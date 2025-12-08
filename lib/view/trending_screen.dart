import 'package:ai_dress_up/view/premium_screen.dart';
import 'package:ai_dress_up/view/setting_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:ai_dress_up/view/pick_image_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/global_variables.dart';
import '../view_model/video_generator_provider.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:video_player/video_player.dart';
import '../view_model/free_usage_provider.dart';
import '../view_model/video_data_provider.dart';
import '../view_model/video_like_provider.dart';
import '../utils/shared_preference_utils.dart';
import '../view_model/credit_provider.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../model/video_model.dart';
import '../ads/ads_load_util.dart';
import '../utils/consts.dart';
import '../utils/utils.dart';
import 'dart:io';

import 'credit_premium_screen.dart';

class TrendingVideoScreen extends ConsumerStatefulWidget {
  const TrendingVideoScreen({super.key});

  @override
  ConsumerState<TrendingVideoScreen> createState() =>
      _TrendingVideoScreenState();
}

class _TrendingVideoScreenState extends ConsumerState<TrendingVideoScreen>
    with WidgetsBindingObserver {
  bool _showHeart = false;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;

  late PageController _pageController;
  int _currentIndex = 0;

  List<VideoModel> _allVideos = [];
  File? _pickedImage;
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: 0);

    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showLog('Deep Baldha');
      _loadTrendingVideos();
      _checkScrollHint();
    });
  }

  void _loadTrendingVideos() {
    final state = ref.read(videoDataProvider(VideoDataType.trending));

    state.whenData((videos) {
      if (_allVideos.isEmpty && videos.isNotEmpty) {
        setState(() {
          _allVideos = videos;
        });

        _initializeCachedVideo(_allVideos[_currentIndex]);

        FirebaseAnalyticsService.logEvent(
          eventName:
              'TRENDING_SCREEN_USER_${_allVideos[_currentIndex].userName}',
        );
      }
    });
  }

  Future<void> _checkScrollHint() async {
    final hasSeen = await SharedPreferenceUtils.getBoolean(
      'has_seen_scroll_hint',
    );

    if (!hasSeen) {
      while (!_isInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      if (!mounted) return;

      setState(() => _showScrollHint = true);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showScrollHint = false);
      });

      SharedPreferenceUtils.saveBoolean('has_seen_scroll_hint', true);
    }
  }

  Future<void> _initializeCachedVideo(VideoModel video) async {
    setState(() {
      _isLoading = true;
      _isInitialized = false;
    });

    await _controller?.pause();
    await _controller?.dispose();
    _controller = null;

    try {
      final videoUrl =
          '${GlobalVariables.videoListTrendingBaseURL}${video.video}';

      final file = await DefaultCacheManager().getSingleFile(videoUrl);
      _controller = VideoPlayerController.file(file);

      await _controller!.initialize();

      _controller!.addListener(() {
        if (_controller == null) return;

        if (_controller!.value.isInitialized &&
            _controller!.value.position >= _controller!.value.duration &&
            !_controller!.value.isPlaying) {
          _controller!.seekTo(Duration.zero);
          _controller!.play();
        }
      });

      _controller!
        ..play()
        ..setVolume(0.0);

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isInitialized = true;
        });
      }
    } catch (e) {
      showLog('❌ Error loading video: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_controller != null &&
          _isInitialized &&
          !_controller!.value.isPlaying) {
        _controller!.play();
      }
    } else if (state == AppLifecycleState.paused) {
      _controller?.pause();
    }
  }

  Future<void> _pickImageCheck() async {
    final video = _allVideos[_currentIndex];
    final freeVideoNotifier = ref.read(freeVideoUsageProvider.notifier);
    final canUseFree = freeVideoNotifier.canUseFree(video);

    if (canUseFree) {
      _pickImage();
      return;
    }

    if (!ref.read(creditProvider.notifier).canAfford(video.creditCharge)) {
      return;
    }

    await _pickImage();
  }

  Future<void> _pickImage() async {
    final wasPlaying = _controller?.value.isPlaying ?? false;
    await _controller?.pause();

    final imagePickerHelper = ImagePickerHelper(context);
    final result = await imagePickerHelper.showImagePickerDialog();

    if (result != null) {
      setState(() {
        _pickedImage = result;
      });
    }

    if (mounted && wasPlaying && _controller != null && _isInitialized) {
      await _controller!.play();
    }
  }

  Future<void> _generateVideo() async {
    if (_pickedImage == null) {
      showToast(getTranslated(context)!.pleasePickImageToGenerateVideo);
      return;
    }

    await _executeVideoGeneration();
  }

  Future<void> _executeVideoGeneration() async {
    final video = _allVideos[_currentIndex];
    final generator = ref.read(videoGenerateProvider.notifier);

    final imagePath = _pickedImage!.path;

    await generator.generate(context, video, imagePath);

    final genState = ref.read(videoGenerateProvider);

    if (genState.errorMessage != null && mounted) {
      showToast(getTranslated(context)!.someThingWentWrong);
    } else if (mounted) {
      setState(() {
        _pickedImage = null;
      });
    }
  }

  void _onPageChanged(int index) {
    final actualIndex = index % _allVideos.length;

    setState(() {
      _currentIndex = actualIndex;
    });

    FirebaseAnalyticsService.logEvent(eventName: 'TRENDING_VIDEO_SCROLL');

    _initializeCachedVideo(_allVideos[actualIndex]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.pause();
    _controller?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendingState = ref.watch(videoDataProvider(VideoDataType.trending));

    trendingState.whenData((videos) {
      if (_allVideos.isEmpty && videos.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _allVideos = videos;
          });

          _initializeCachedVideo(_allVideos[_currentIndex]);
        });
      }
    });

    if (_allVideos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              _buildFullScreenVideo(),
              _buildTopOverlay(),
              _buildTopBar(),
              _buildBottomUI(),
              if (_showScrollHint) _buildScrollHint(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullScreenVideo() {
    return PageView.builder(
      scrollDirection: Axis.vertical,
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: null,
      itemBuilder: (context, index) {
        final actualIndex = index % _allVideos.length;
        final isCurrentPage =
            actualIndex == (_currentIndex % _allVideos.length);

        if (!isCurrentPage) {
          // Show the thumbnail for non-current pages
          return CachedNetworkImage(
            imageUrl: _allVideos[actualIndex].inputImage.startsWith('http')
                ? _allVideos[actualIndex].inputImage
                : '${GlobalVariables.videoListTrendingBaseURL}${_allVideos[actualIndex].inputImage}',
            fit: BoxFit.cover,
          );
        }

        if (_isLoading) {
          return _loadingView(actualIndex);
        }

        if (!_isInitialized || _controller == null) {
          return const Center(
            child: Text(
              'Failed to load video',
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return Align(
          alignment: Alignment.topCenter,
          child: AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: GestureDetector(
              onDoubleTap: () async {
                await ref
                    .read(videoLikeProvider.notifier)
                    .toggleLike(_allVideos[_currentIndex].userName);

                setState(() => _showHeart = true);
                Future.delayed(const Duration(milliseconds: 600), () {
                  if (mounted) setState(() => _showHeart = false);
                });
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller!),

                  Positioned(
                    bottom: -20.h,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 300.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.white,
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),

                  AnimatedOpacity(
                    opacity: _showHeart ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: AnimatedScale(
                      scale: _showHeart ? 1.5 : 0.5,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 120,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _loadingView(int index) {
    return CachedNetworkImage(
      imageUrl: _allVideos[index].inputImage.startsWith('http')
          ? _allVideos[index].inputImage
          : '${GlobalVariables.videoListTrendingBaseURL}${_allVideos[index].inputImage}',
      fit: BoxFit.cover,
      placeholder: (context, url) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey[300],
        ),
      ),
      imageBuilder: (context, imageProvider) => Stack(
        fit: StackFit.expand,
        children: [
          Image(image: imageProvider, fit: BoxFit.cover),
          // Shimmer overlay on the image while video loads
          Shimmer.fromColors(
            baseColor: Colors.black.withValues(alpha: 0.3),
            highlightColor: Colors.black.withValues(alpha: 0.1),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: Center(
          child: Icon(Icons.error, color: Colors.grey[600], size: 50),
        ),
      ),
    );
  }

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      right: 0,
      left: 0,
      child: Container(
        height: 500.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0), Colors.black],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 30.h,
      left: 0.w,
      right: 0.w,
      child: SafeArea(
        child: Container(
          color: Colors.transparent,
          padding: EdgeInsets.only(left: 50.w, top: 20.h, bottom: 20.h),
          child: Row(
            children: [
              Image(
                image: AssetImage('${defaultImagePath}video_heading_white.png'),
                width: 400.w,
              ),
              Expanded(child: Container()),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 30.w,
                      vertical: 15.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        NewDeepPressUnpress(
                          onTap: () {
                            navigateTo(
                              context,
                              CreditPremiumScreen(from: 'home', onDone: () {}),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 30.w,
                              vertical: 15.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: Color(0xffDDDDDD),
                                width: 5.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                Image.asset(
                                  '${defaultImagePath}coin.png',
                                  width: 60.w,
                                ),
                                20.horizontalSpace,
                                Consumer(
                                  builder: (context, ref, _) {
                                    return Text(
                                      ref.watch(creditProvider).toString(),
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 55.sp,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        30.horizontalSpace,
                        NewDeepPressUnpress(
                          onTap: () {
                            navigateTo(
                              context,
                              PremiumScreen(from: 'home', onDone: () {}),
                            );
                          },
                          child: Container(
                            height: 115.h,
                            width: 115.h,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  '${defaultImagePath}home_pro_button.png',
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                        30.horizontalSpace,
                        NewDeepPressUnpress(
                          onTap: () {
                            navigateTo(context, SettingScreen());
                          },
                          child: Container(
                            height: 115.h,
                            width: 115.h,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(
                                  '${defaultImagePath}setting_button.png',
                                ),
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    final videoLikeState = ref.watch(videoLikeProvider);
    final isLiked = videoLikeState.likedVideos.contains(
      _allVideos[_currentIndex].userName,
    );

    final displayCount = ref
        .read(videoLikeProvider.notifier)
        .getDisplayLikeCount(
          _allVideos[_currentIndex].userName,
          _allVideos[_currentIndex].likes,
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(videoLikeProvider.notifier)
          .ensureRandomCount(_allVideos[_currentIndex].userName);
    });

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(50.w, 0, 50.w, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildPickedImageCard(),

                30.horizontalSpace,

                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildVideoDetails(),
                      _buildLikeButton(isLiked, displayCount),
                    ],
                  ),
                ),
              ],
            ),

            30.verticalSpace,

            _buildGenerateButton(),

            20.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _buildPickedImageCard() {
    return Container(
      height: 380.h,
      width: 270.w,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40.r),
        border: Border.all(color: Colors.white, width: 5.w),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.r),
        child: NewDeepPressUnpress(
          onTap: _pickImageCheck,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _pickedImage != null
                  ? Image.file(_pickedImage!, fit: BoxFit.cover)
                  : CachedNetworkImage(
                      imageUrl:
                          _allVideos[_currentIndex].inputImage.startsWith(
                            'http',
                          )
                          ? _allVideos[_currentIndex].inputImage
                          : '${GlobalVariables.videoListTrendingBaseURL}${_allVideos[_currentIndex].inputImage}',
                      fit: BoxFit.cover,
                    ),

              if (_pickedImage == null)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.camera_alt,
                        color: Colors.white.withValues(alpha: 0.7),
                        size: 50.sp,
                      ),
                    ),
                  ),
                ),

              if (_pickedImage != null)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Image.asset(
                    width: 60.w,
                    '${defaultImagePath}close.png',
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoDetails() {
    final video = _allVideos[_currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          video.title,
          style: TextStyle(
            fontSize: 60.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        10.verticalSpace,
        Text(
          video.userName,
          style: TextStyle(
            color: Colors.black.withValues(alpha: 0.7),
            fontSize: 55.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
        10.verticalSpace,

        if (ref
            .watch(freeVideoUsageProvider.notifier)
            .getUpdatedVideo(video)
            .isOneTimeFree)
          _freeBadge()
        else
          _creditBadge(video.creditCharge),
      ],
    );
  }

  Widget _freeBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('${defaultImagePath}coin.png', width: 50.w),
          10.horizontalSpace,
          Text(
            getTranslated(context)!.free.toUpperCase(),
            style: TextStyle(
              fontSize: 42.sp,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _creditBadge(int credit) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(150),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: 2,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Row(
        children: [
          Image.asset('${defaultImagePath}coin.png', width: 60.w),
          10.horizontalSpace,
          Text(
            '$credit',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildLikeButton(bool isLiked, int displayCount) {
    return NewDeepPressUnpress(
      onTap: () async {
        await ref
            .read(videoLikeProvider.notifier)
            .toggleLike(_allVideos[_currentIndex].userName);
      },
      child: Column(
        children: [
          Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            color: isLiked ? Colors.red : Colors.black,
            size: 80.sp,
          ),
          5.verticalSpace,
          Text(
            _formatLikeCount(displayCount),
            style: TextStyle(
              color: Colors.black,
              fontSize: 35.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return NewDeepPressUnpress(
      onTap: () {
        if (_pickedImage == null) {
          _pickImageCheck();
        } else {
          _generateVideo();
        }
      },
      child: SafeArea(
        top: false,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 40.w),
          height: 180.h,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(500),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                _pickedImage == null
                    ? '${defaultImagePath}upload_image.png'
                    : '${defaultImagePath}generate_pre_icon.png',
                height: 60.h,
              ),
              30.horizontalSpace,
              Flexible(
                child: Text(
                  _pickedImage == null
                      ? getTranslated(context)!.chooseYourPhoto
                      : getTranslated(context)!.generateVideo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white, fontSize: 60.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollHint() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: Image.asset(
            '${defaultImagePath}scroll_up_down.gif',
            width: 300.w,
            height: 300.h,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  String _formatLikeCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}
