import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ai_dress_up/view/video_scroll_screen.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:image_picker/image_picker.dart';
import '../view_model/free_usage_provider.dart';
import '../view_model/video_like_provider.dart';
import '../view_model/video_data_provider.dart';
import '../utils/global_variables.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../model/video_model.dart';
import '../ads/ads_load_util.dart';
import '../ads/ads_variable.dart';
import '../utils/consts.dart';
import '../utils/utils.dart';
import 'dart:math';

class VideoHomeScreen extends ConsumerStatefulWidget {
  const VideoHomeScreen({super.key});

  @override
  ConsumerState<VideoHomeScreen> createState() => _VideoHomeScreenState();
}

class _VideoHomeScreenState extends ConsumerState<VideoHomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {});
    super.initState();
  }

  VideoDataType getHomeVideoType() {
    showLog('Ads variable value is : ${AdsVariable.userFrom}');
    switch (AdsVariable.userFrom.toLowerCase()) {
      case 'facebook':
        FirebaseAnalyticsService.logEvent(eventName: 'FACEBOOK_HOME_SCREEN');
        return VideoDataType.homeFacebook;
      case 'google':
        FirebaseAnalyticsService.logEvent(eventName: 'GOOGLE_HOME_SCREEN');
        return VideoDataType.homeGoogle;
      case 'unity':
        FirebaseAnalyticsService.logEvent(eventName: 'UNITY_HOME_SCREEN');
        return VideoDataType.homeNormal;
      default:
        FirebaseAnalyticsService.logEvent(eventName: 'PLAY_STORE_HOME_SCREEN');
        return VideoDataType.homeNormal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeVideoType = getHomeVideoType();
    final videoState = ref.watch(videoDataProvider(homeVideoType));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.only(
          left: 50.w,
          right: 50.w,
          top: 30.h,
          // bottom: 80.h,
        ),
        child: SafeArea(
          child: videoState.when(
            data: (videos) {
              if (videos.isEmpty) {
                return const Center(
                  child: Text(
                    'No videos available.',
                    style: TextStyle(color: Colors.white),
                  ),
                );
              }

              return CustomScrollView(
                slivers: [
                  SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.6,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final video = videos[index];
                      return _buildVideoGridCard(context, video, index, videos);
                    }, childCount: videos.length),
                  ),
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [50.verticalSpace],
                    ),
                  ),
                ],
              );
            },

            loading: () => Center(
              child: Lottie.asset(
                '${defaultImagePath}loader.json',
                height: 600.h,
              ),
            ),

            error: (error, _) => Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 50.w),
                child: Text(
                  getTranslated(
                    context,
                  )!.somethingWentWrongMakeSureYouHaveActiveInternetConnection,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Rosefana',
                    fontSize: 100.sp,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String getHomeBaseUrl() {
    switch (AdsVariable.userFrom.toLowerCase()) {
      case 'facebook':
        return GlobalVariables.videoFacebookBaseURL;
      case 'google':
        return GlobalVariables.videoGoogleAdsBaseURL;
      case 'unity':
        return GlobalVariables.videoHomeBaseURL;
      default:
        return GlobalVariables.videoHomeBaseURL;
    }
  }

  Widget _buildVideoGridCard(
    BuildContext context,
    VideoModel video,
    int index,
    List<VideoModel> allVideos,
  ) {
    final baseURL = getHomeBaseUrl();
    final String imageUrl = '$baseURL${video.thumbnail}';

    final videoLikeState = ref.watch(videoLikeProvider);
    final isLiked = videoLikeState.likedVideos.contains(video.userName);

    final displayCount = ref
        .read(videoLikeProvider.notifier)
        .getDisplayLikeCount(video.userName, video.likes);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoLikeProvider.notifier).ensureRandomCount(video.userName);
    });

    return NewDeepPressUnpress(
      onTap: () {
        AdsLoadUtil.onShowAds(context, () {
          navigateTo(
            context,
            VideoScrollScreen(
              videoModel: video,
              initialIndex: index,
              videosList: allVideos,
              baseURL: AdsVariable.userFrom.toLowerCase() == 'facebook'
                  ? GlobalVariables.videoFacebookBaseURL
                  : AdsVariable.userFrom.toLowerCase() == 'google'
                  ? GlobalVariables.videoGoogleAdsBaseURL
                  : GlobalVariables.videoHomeBaseURL,
            ),
          );
        });
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40.r),
        child: Stack(
          children: [
            Positioned.fill(
              child: RetryingNetworkImage(
                imageUrl: imageUrl,
                videoUserName: video.userName,
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 180.h,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 3,
                    sigmaY: 3,
                    tileMode: TileMode.clamp,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.2),
                          Colors.black.withValues(alpha: 0.15),
                          Colors.black.withValues(alpha: 0.12),
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.07),
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.03),
                          Colors.black.withValues(alpha: 0.02),
                          Colors.black.withValues(alpha: 0.01),
                          Colors.transparent,
                          Colors.transparent,
                        ],
                        stops: const [
                          0.0,
                          0.15,
                          0.25,
                          0.35,
                          0.45,
                          0.55,
                          0.65,
                          0.75,
                          0.85,
                          0.9,
                          0.95,
                          1.0,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              left: 40.w,
              right: 30.w,
              bottom: 8,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /*Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 30.w,
                            vertical: 15.h,
                          ),
                          decoration: BoxDecoration(
                            color: isLiked
                                ? Colors.white
                                : Color(0xff000000).withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(150),
                          ),
                          child: NewDeepPressUnpress(
                            onTap: () async {
                              await ref
                                  .read(videoLikeProvider.notifier)
                                  .toggleLike(video.userName);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isLiked ? Icons.favorite : Icons.favorite,
                                  color: isLiked ? Colors.red : Colors.white,
                                  size: 60.sp,
                                ),
                                10.horizontalSpace,
                                Text(
                                  _formatLikeCount(displayCount),
                                  style: TextStyle(
                                    color: isLiked
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 35.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),*/
                        20.verticalSpace,
                        Text(
                          video.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontStyle: FontStyle.italic,
                            fontSize: 50.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          video.userName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 40.sp,
                            shadows: [
                              Shadow(
                                blurRadius: 4,
                                color: Colors.black,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              top: 30.h,
              right:
                  ref
                      .watch(freeVideoUsageProvider.notifier)
                      .getUpdatedVideo(video)
                      .isOneTimeFree
                  ? 0.w
                  : 40.w,
              child: Column(
                children: [
                  if (ref
                      .watch(freeVideoUsageProvider.notifier)
                      .getUpdatedVideo(video)
                      .isOneTimeFree)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        color: Color(0xffF9595F),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(100),
                          bottomLeft: Radius.circular(100),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          10.horizontalSpace,
                          Text(
                            getTranslated(context)!.free.toUpperCase(),
                            style: TextStyle(
                              fontSize: 42.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 15.w,
                        vertical: 10.h,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(120),
                        color: Colors.white,
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            '${defaultImagePath}coin_show.png',
                            width: 50.w,
                          ),
                          10.horizontalSpace,
                          Text(
                            video.creditCharge.toString(),
                            style: TextStyle(
                              fontSize: 42.sp,
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
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

class RetryingNetworkImage extends StatefulWidget {
  final String imageUrl;
  final String videoUserName;

  const RetryingNetworkImage({
    required this.imageUrl,
    required this.videoUserName,
  });

  @override
  State<RetryingNetworkImage> createState() => _RetryingNetworkImageState();
}

class _RetryingNetworkImageState extends State<RetryingNetworkImage> {
  int _retryCount = 0;
  Key _imageKey = UniqueKey();

  void _retryLoad() {
    setState(() {
      _retryCount++;
      _imageKey = UniqueKey();
      showLog(
        '🔄 Retrying image load for ${widget.videoUserName} (attempt $_retryCount)',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      key: _imageKey,
      imageUrl: widget.imageUrl,
      fit: BoxFit.cover,
      maxHeightDiskCache: 400,
      maxWidthDiskCache: 300,
      memCacheHeight: 400,
      memCacheWidth: 300,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                '${defaultImagePath}loader.json',
                width: 150.w,
                height: 150.w,
              ),
              if (_retryCount > 0) ...[
                10.verticalSpace,
                Text(
                  'Loading... ',
                  style: TextStyle(color: Colors.grey[600], fontSize: 30.sp),
                ),
              ],
            ],
          ),
        ),
      ),
      errorWidget: (context, url, error) {
        showLog('❌ Image error for ${widget.videoUserName}: $error');
        Future.delayed(Duration(seconds: 2), () {
          if (mounted) {
            _retryLoad();
          }
        });

        return Container(
          color: Colors.grey[900],
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  '${defaultImagePath}loader.json',
                  width: 150.w,
                  height: 150.w,
                ),
                10.verticalSpace,
              ],
            ),
          ),
        );
      },
    );
  }
}
