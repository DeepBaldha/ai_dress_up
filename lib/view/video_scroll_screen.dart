import 'package:ai_dress_up/ads/ads_variable.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:ai_dress_up/view/pick_image_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_model/background_video_provider.dart';
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
import 'dart:math';
import 'dart:io';

import 'credit_premium_screen.dart';

class VideoScrollScreen extends ConsumerStatefulWidget {
  const VideoScrollScreen({
    super.key,
    required this.videoModel,
    required this.initialIndex,
    required this.baseURL,
    this.videosList,
  });

  final VideoModel videoModel;
  final int initialIndex;
  final String baseURL;
  final List<VideoModel>? videosList;

  @override
  ConsumerState<VideoScrollScreen> createState() => _VideoScrollScreenState();
}

class _VideoScrollScreenState extends ConsumerState<VideoScrollScreen>
    with WidgetsBindingObserver {
  bool _showHeart = false;
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isLoading = true;
  late PageController _pageController;
  late int _currentIndex;
  List<VideoModel> _allVideos = [];
  File? _pickedImage;
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _checkScrollHint();
    _pageController = PageController(initialPage: _currentIndex);

    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(
        eventName:
            'VIDEO_GENERATE_PREVIEW_SCREEN_USER_${_allVideos[_currentIndex].userName}',
      );
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

      // Hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showScrollHint = false);
      });

      // Save flag
      SharedPreferenceUtils.saveBoolean('has_seen_scroll_hint', true);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (widget.videosList != null) {
      if (_allVideos.isEmpty) {
        setState(() {
          _allVideos = widget.videosList!;
        });
        _initializeCachedVideo(_allVideos[_currentIndex]);
      }
    } else {
      final videoState = ref.watch(videoDataProvider(VideoDataType.homeNormal));
      videoState.whenData((videos) {
        if (_allVideos.isEmpty) {
          setState(() {
            _allVideos = videos;
          });
          _initializeCachedVideo(_allVideos[_currentIndex]);
        }
      });
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
      final videoUrl = '${widget.baseURL}${video.video}';

      final file = await DefaultCacheManager().getSingleFile(videoUrl);
      _controller = VideoPlayerController.file(file);

      await _controller!.initialize();

      _controller!.addListener(() {
        final controller = _controller;
        if (controller == null) return;

        if (controller.value.isInitialized &&
            controller.value.position >= controller.value.duration &&
            !controller.value.isPlaying) {
          controller.seekTo(Duration.zero);
          controller.play();
        }
      });

      _controller!
        ..play()
        ..setVolume(0.0);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      showLog('❌ Error loading video: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      showLog('here it is with start');
      if (_controller != null &&
          _isInitialized &&
          !_controller!.value.isPlaying) {
        _controller!.play();
      }
    } else if (state == AppLifecycleState.paused) {
      showLog('here it is');
      _controller?.pause();
    }
  }

  Future<void> _pickImageCheck() async {
    final bgTask = ref.read(backgroundTaskProvider);
    if (bgTask.hasActiveTask) {
      showToast('A video is already being generated in background. Please wait until it completes.');
      showLog('⛔ Cannot start new generation - background task is active');
      return;
    }

    final video = _allVideos[_currentIndex];

    final freeVideoNotifier = ref.read(freeVideoUsageProvider.notifier);
    final canUseFree = freeVideoNotifier.canUseFree(video);

    showLog('Can use free $canUseFree');

    if (canUseFree) {
      _pickImage();
      return;
    }

    if (!ref.read(creditProvider.notifier).canAfford(video.creditCharge)) {
      showLog(
        'video credit : ${video.creditCharge} and your credit ${ref.read(creditProvider).toString()}',
      );

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreditPremiumScreen(
            onDone: () async {
              await _pickImage();
            },
            from: 'generate_video',
          ),
        ),
      );
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

    final video = _allVideos[_currentIndex];

    // // Check if user has sufficient credits
    if(!AdsVariable.showIMTester) {
      if (!ref.read(creditProvider.notifier).canAfford(video.creditCharge)) {
        showLog(
          'video credit : ${video.creditCharge} and your credit ${ref.read(
              creditProvider).toString()}',
        );

        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreditPremiumScreen(
                  onDone: () async {
                    await _executeVideoGeneration();
                  },
                  from: 'generate_video',
                ),
          ),
        );
        return;
      }
    }

    await _executeVideoGeneration();
  }

  Future<void> _executeVideoGeneration() async {
    final video = _allVideos[_currentIndex];
    final generator = ref.read(videoGenerateProvider.notifier);
    final imagePath = _pickedImage!.path;

    await generator.generate(context, video, imagePath);

    // 🔥 CRITICAL: Check mounted BEFORE reading provider state
    if (!mounted) {
      showLog('⛔ Widget unmounted during generation, skipping cleanup');
      return;
    }

    // Now safe to read provider
    final genState = ref.read(videoGenerateProvider);

    // Check if task moved to background
    final bgTask = ref.read(backgroundTaskProvider);
    if (bgTask.hasActiveTask) {
      showLog('✅ Task moved to background, skipping error handling');
      setState(() {
        _pickedImage = null;
      });
      return;
    }

    // Handle foreground errors
    if (genState.errorMessage != null) {
      showToast(getTranslated(context)!.someThingWentWrong);
      showLog(genState.errorMessage.toString());
    } else {
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

    showLog('page is changed');
    FirebaseAnalyticsService.logEvent(eventName: 'VIDEO_SCROLL_SCREEN');
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
    if (_allVideos.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[900]!,
            highlightColor: Colors.grey[700]!,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
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
              Positioned(
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
              ),

              Positioned(
                top: 30.h,
                left: 60.w,
                right: 60.w,
                child: SafeArea(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      NewDeepPressUnpress(
                        onTap: () {
                          AdsLoadUtil.onShowAds(context, () {
                            Navigator.pop(context);
                          });
                        },
                        child: Image.asset(
                          '${defaultImagePath}back_white.png',
                          width: 100.w,
                        ),
                      ),
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
                    ],
                  ),
                ),
              ),

              _buildBottomUI(),
              if (_showScrollHint)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            '${defaultImagePath}scroll_up_down.gif',
                            width: 300.w,
                            height: 300.h,
                            fit: BoxFit.contain,
                          ),
                          20.verticalSpace,
                          /*Text(
                            'Swipe up/down to explore',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 45.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),*/
                        ],
                      ),
                    ),
                  ),
                ),
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

        if (!isCurrentPage) return Container(color: Colors.black);

        if (_isLoading) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: _allVideos[actualIndex].inputImage.startsWith('http')
                    ? _allVideos[actualIndex].inputImage
                    : '${widget.baseURL}${_allVideos[actualIndex].inputImage}',
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.darken,
                placeholder: (context, url) => Shimmer(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff000000),
                      Color(0xffBD43fD).withValues(alpha: 0.13),
                      Color(0xffBD43fD).withValues(alpha: 0.26),
                      Color(0xffBD43fD).withValues(alpha: 0.13),
                      Color(0xff000000),
                    ],
                    stops: [0.0, 0.4, 0.5, 0.6, 1.0],
                  ),
                  period: Duration(milliseconds: 1500),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                ),
                errorWidget: (context, url, error) => Shimmer(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff000000),
                      Color(0xffBD43fD).withValues(alpha: 0.13),
                      Color(0xffBD43fD).withValues(alpha: 0.26),
                      Color(0xffBD43fD).withValues(alpha: 0.13),
                      Color(0xff000000),
                    ],
                    stops: [0.0, 0.4, 0.5, 0.6, 1.0],
                  ),
                  period: Duration(milliseconds: 1500),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.black,
                  ),
                ),
              ),
              // Shimmer effect overlay
              Center(
                child: Shimmer(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff000000),
                      Color(0xffBD43fD).withValues(alpha: 0.13),
                      Color(0xffBD43fD).withValues(alpha: 0.26),
                      Color(0xffBD43fD).withValues(alpha: 0.13),
                      Color(0xff000000),
                    ],
                    stops: [0.0, 0.4, 0.5, 0.6, 1.0],
                  ),
                  period: Duration(milliseconds: 1500),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          );
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
                // Like video
                await ref
                    .read(videoLikeProvider.notifier)
                    .toggleLike(_allVideos[_currentIndex].userName);

                // Show animation
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
                    bottom: -5.h,
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

    showLog(
      'image Url is ${_allVideos[_currentIndex].inputImage.startsWith('http') ? _allVideos[_currentIndex].inputImage : '${widget.baseURL}${_allVideos[_currentIndex].inputImage}'}',
    );
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
                Container(
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
                                      _allVideos[_currentIndex].inputImage
                                          .startsWith('http')
                                      ? _allVideos[_currentIndex].inputImage
                                      : '${widget.baseURL}${_allVideos[_currentIndex].inputImage}',
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) =>
                                      Shimmer.fromColors(
                                        baseColor: Colors.grey[800]!,
                                        highlightColor: Colors.grey[600]!,
                                        child: Container(
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                        color: Colors.grey[800],
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 40,
                                          color: Colors.white54,
                                        ),
                                      ),
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
                ),
                30.horizontalSpace,
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _allVideos[_currentIndex].title,
                            style: TextStyle(
                              fontSize: 65.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          10.verticalSpace,
                          Text(
                            _allVideos[_currentIndex].userName,
                            style: TextStyle(
                              color: Colors.black.withValues(alpha: 0.7),
                              fontSize: 55.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          10.verticalSpace,
                          if (ref
                              .watch(freeVideoUsageProvider.notifier)
                              .getUpdatedVideo(_allVideos[_currentIndex])
                              .isOneTimeFree) ...[
                            Container(
                              padding: EdgeInsets.only(
                                left: 15.w,
                                right: 25.w,
                                top: 10.h,
                                bottom: 10.h,
                              ),
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
                                  Image.asset(
                                    '${defaultImagePath}coin.png',
                                    width: 50.w,
                                  ),
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
                            ),
                          ] else ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 30.w,
                                vertical: 10.h,
                              ),
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
                                  Image.asset(
                                    '${defaultImagePath}coin.png',
                                    width: 60.w,
                                  ),
                                  10.horizontalSpace,
                                  Text(
                                    '${_allVideos[_currentIndex].creditCharge}',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      NewDeepPressUnpress(
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
            30.verticalSpace,
            NewDeepPressUnpress(
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
                  margin: EdgeInsets.symmetric(horizontal: 10.w),
                  height: 190.h,
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
                        height: 65.h,
                      ),
                      30.horizontalSpace,
                      Flexible(
                        child: Text(
                          _pickedImage == null
                              ? getTranslated(context)!.chooseYourPhoto
                              : getTranslated(context)!.generateVideo,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 65.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            20.verticalSpace,
          ],
        ),
      ),
    );
  }

  int getDisplayLikeCount(int? videoLikes, String userName) {
    if (videoLikes != null && videoLikes > 0) {
      return videoLikes;
    } else {
      final seed = userName.hashCode;
      return Random(seed).nextInt(9000) + 1000;
    }
  }

  String _formatLikeCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
