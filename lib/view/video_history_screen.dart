import 'dart:io';
import 'package:ai_dress_up/view/video_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lottie/lottie.dart';

import '../ads/ads_load_util.dart';
import '../model/video_result_model.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/utils.dart';
import '../view_model/video_result_provider.dart';

class VideoHistoryScreen extends ConsumerStatefulWidget {
  const VideoHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<VideoHistoryScreen> createState() => _VideoHistoryScreenState();
}

class _VideoHistoryScreenState extends ConsumerState<VideoHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(videoResultProvider).loadVideos();
      FirebaseAnalyticsService.logEvent(
        eventName: 'VIDEO_CREATION_LIST_SCREEN',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        final provider = ref.watch(videoResultProvider);
        if (provider.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: () async {
            await provider.loadVideos();
          },
          child: _buildGridView(provider),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('${defaultImagePath}creation_empty.png', height: 750.h),
        50.verticalSpace,
        Text(
          getTranslated(context)!.thereIsNoItemHere,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 70.sp),
        ),
        20.verticalSpace,
        Text(
          getTranslated(context)!.beginYourImageAndVideoMagicToday,
          style: TextStyle(color: Color(0xff949494)),
        ),
        200.verticalSpace,
      ],
    );
  }

  Widget _buildGridView(VideoResultNotifier provider) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: provider.videoCount,
      itemBuilder: (context, index) {
        final video = provider.videos[index];
        return _buildGridCard(context, video, index, provider);
      },
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    VideoResultModel video,
    int index,
    VideoResultNotifier provider,
  ) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(50.r)),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(50.r),
            child: NewDeepPressUnpress(
              onTap: () {
                AdsLoadUtil.onShowAds(context, () {
                  _openVideo(context, video);
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: Colors.black87,
                      child: _buildThumbnail(video),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Image.asset(
            '${defaultImagePath}video_play.png',
            height: 200.h,
          ),
        ),
      ],
    );
  }

  /// Build thumbnail widget with proper error handling
  Widget _buildThumbnail(VideoResultModel video) {
    if (video.thumbnailUrl != null && video.thumbnailUrl!.isNotEmpty) {
      if (video.thumbnailUrl!.startsWith('http://') ||
          video.thumbnailUrl!.startsWith('https://')) {
        return Image.network(
          video.thumbnailUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Lottie.asset('${defaultImagePath}loader.json'),
            );
          },
          errorBuilder: (_, __, ___) => _buildVideoIcon(),
        );
      } else {
        final file = File(video.thumbnailUrl!);
        return FutureBuilder<bool>(
          future: file.exists(),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data == true) {
              return Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildVideoIcon(),
              );
            }
            return _buildVideoIcon();
          },
        );
      }
    }

    return _buildVideoIcon();
  }

  Widget _buildVideoIcon() {
    return const Center(
      child: Icon(Icons.play_circle_outline, size: 48, color: Colors.white),
    );
  }

  void _openVideo(BuildContext context, VideoResultModel video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoResultScreen(
          video: video.videoUrl,
          title: video.title,
          autoSave: false,
          from: 'history',
        ),
      ),
    );
  }
}
