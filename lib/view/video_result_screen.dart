import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';

import '../ads/ads_load_util.dart';
import '../utils/consts.dart';
import '../utils/custom_widgets/deep_press_unpress.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/utils.dart';
import '../view_model/video_result_provider.dart';

class VideoResultScreen extends ConsumerStatefulWidget {
  const VideoResultScreen({
    super.key,
    required this.video,
    this.title,
    required this.from,
    this.autoSave = true,
  });

  final String video;
  final String? title;
  final bool autoSave;
  final String from;

  @override
  ConsumerState<VideoResultScreen> createState() => _VideoResultScreenState();
}

class _VideoResultScreenState extends ConsumerState<VideoResultScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isSaving = false;
  bool _hasSaved = false;
  bool _isDeleting = false;
  bool _isSavingToGallery = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    WidgetsBinding.instance.addPostFrameCallback((callback) {
      FirebaseAnalyticsService.logEvent(eventName: 'VIDEO_RESULT_SCREEN');
    });
  }

  Future<void> _initializeVideo() async {
    try {
      showLog('🎬 Initializing video: ${widget.video}');

      final isLocalFile =
          widget.video.startsWith('/') || widget.video.startsWith('file://');
      _controller = isLocalFile
          ? VideoPlayerController.file(File(widget.video))
          : VideoPlayerController.networkUrl(Uri.parse(widget.video));

      await _controller.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        _controller.play();
        _controller.setLooping(true);

        showLog('✅ Video initialized successfully');

        if (widget.autoSave && !_hasSaved) {
          await _saveToHistory();
        }
      }
    } catch (e) {
      showLog('❌ Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _saveToHistory() async {
    if (_isSaving || _hasSaved) {
      showLog('⚠️ Already saving or saved, skipping');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      showLog('💾 Saving video to history...');

      final videoResultNotifier = ref.read(videoResultProvider);

      await videoResultNotifier.addVideo(
        widget.video,
        title: widget.title ?? 'Video ${DateTime.now().millisecondsSinceEpoch}',
        thumbnailUrl: null,
      );

      if (mounted) {
        setState(() {
          _hasSaved = true;
          _isSaving = false;
        });
        showLog('✅ Video saved successfully');
        showToast(getTranslated(context)!.videoSavedToHistory);
      }
    } catch (e) {
      showLog('❌ Error saving video: $e');

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save: $e')),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSavingToGallery) {
      showLog('⚠️ Already saving to gallery, skipping');
      return;
    }

    setState(() {
      _isSavingToGallery = true;
    });

    try {
      showLog('📥 Saving video to gallery: ${widget.video}');

      final success = await GallerySaver.saveVideo(widget.video);

      if (success ?? false) {
        showToast('Video Successfully Saved To Gallery');
      } else {
        showToast('Error in saving video to gallery');
      }

      setState(() {
        _isSavingToGallery = false;
      });
    } catch (e) {
      showLog('❌ Error saving to gallery: $e');

      if (mounted) {
        setState(() {
          _isSavingToGallery = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to save to gallery: $e')),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 800.w,
              padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 60.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(80.r),
                image: DecorationImage(
                  image: AssetImage('${defaultImagePath}delete_dialog_bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Spacer(),
                      NewDeepPressUnpress(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: Image.asset(
                          '${defaultImagePath}close.png',
                          width: 100.w,
                        ),
                      ),
                    ],
                  ),
                  Image.asset(
                    '${defaultImagePath}delete_icon_dialog.png',
                    height: 300.h,
                  ),
                  50.verticalSpace,
                  Text(
                    getTranslated(context)!.areYouSureYouWantToDeleteThisVideo,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 50.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  60.verticalSpace,

                  NewDeepPressUnpress(
                    onTap: () async {
                      Navigator.pop(context);
                      _deleteVideo();
                    },
                    child: Container(
                      width: 600.w,
                      padding: EdgeInsets.symmetric(vertical: 35.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(150),
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFFFF7271), Color(0xFFEF4B4A)],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          getTranslated(context)!.delete,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 50.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  30.verticalSpace,
                  NewDeepPressUnpress(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      getTranslated(context)!.cancel,
                      style: TextStyle(color: Color(0xff626262)),
                    ),
                  ),
                  40.verticalSpace,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteVideo() async {
    if (_isDeleting) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      showLog('🗑️ Deleting video: ${widget.video}');

      final videoResultNotifier = ref.read(videoResultProvider);

      // Find the index of the video to delete
      final videoIndex = videoResultNotifier.videos.indexWhere(
        (v) => v.videoUrl == widget.video,
      );

      if (videoIndex != -1) {
        await videoResultNotifier.deleteVideo(videoIndex);
        showLog('✅ Video deleted successfully');

        if (mounted) {
          showToast('Video deleted successfully');

          if (widget.from == 'generate') {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pop();
          }
        }
      } else {
        showLog('⚠️ Video not found in history');

        if (mounted) {
          setState(() {
            _isDeleting = false;
          });
          showToast('Video not found in history');
        }
      }
    } catch (e) {
      showLog('❌ Error deleting video: $e');

      if (mounted) {
        setState(() {
          _isDeleting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Failed to delete video')),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    showLog('🗑️ Disposing video controller');
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Color(0xfff3f3f3),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  30.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 50.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        NewDeepPressUnpress(
                          onTap: () {
                            AdsLoadUtil.onShowAds(context, () {
                              if (widget.from == 'generate') {
                                // Navigator.pop(context);
                                Navigator.pop(context);
                              } else {
                                Navigator.pop(context);
                              }
                            });
                          },
                          child: Image.asset(
                            '${defaultImagePath}back.png',
                            height: 100.h,
                          ),
                        ),
                        30.horizontalSpace,
                        Expanded(
                          child: Text(
                            getTranslated(context)!.preview,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 75.sp, letterSpacing: 0.4),
                          ),
                        ),
                        NewDeepPressUnpress(
                          onTap: () => showDeleteDialog(context),
                          child: Image.asset(
                            '${defaultImagePath}delete.png',
                            height: 90.w,
                          ),
                        ),
                      ],
                    ),
                  ),

                  50.verticalSpace,
                  Expanded(child: Center(child: _buildBody())),

                  NewDeepPressUnpress(
                    onTap: () {
                      if (_isSavingToGallery) {
                        return;
                      } else {
                        _saveToGallery();
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 70.h),
                      height: 180.h,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(150),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            '${defaultImagePath}download.png',
                            color: Colors.white,
                            width: 70.w,
                          ),
                          30.horizontalSpace,
                          Text(
                            getTranslated(context)!.downloadVideo,
                            style: TextStyle(
                              fontSize: 60.sp,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  50.verticalSpace,
                ],
              ),
            ),
            if (_isSavingToGallery)
              Container(
                color: Colors.black.withValues(alpha: 0.7),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Lottie.asset(
                        '${defaultImagePath}loader.json',
                        height: 300.h,
                      ),
                      40.verticalSpace,
                      Text(
                        'Saving to gallery...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 50.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_hasError) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Failed to load video',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = '';
                });
                _initializeVideo();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset('${defaultImagePath}loader.json', height: 500.h),
          50.verticalSpace,
          Text(
            'Loading video...',
            style: TextStyle(color: Colors.white, fontSize: 60.sp),
          ),
        ],
      );
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 50.w),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(120.r),
        color: const Color(0xfff3f3f3),
      ),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          children: [
            // --- VIDEO ---
            ClipRRect(
              borderRadius: BorderRadius.circular(120.r),
              child: VideoPlayer(_controller),
            ),

            // --- TAP TO PAUSE ---
            Positioned.fill(
              child: NewDeepPressUnpress(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Container(color: Colors.transparent),
              ),
            ),

            // --- PLAY OVERLAY ---
            if (!_controller.value.isPlaying && !_hasError)
              Center(
                child: Image.asset(
                  '${defaultImagePath}video_pause.png',
                  width: 200.w,
                ),
              ),

            // --- BOTTOM CONTROLS (fixed to video bottom) ---
            if (!_controller.value.isPlaying && !_hasError)
              Positioned(
                left: 25.w,
                right: 25.w,
                bottom: 25.h,  // 👈 Adjust here
                child: Row(
                  children: [
                    NewDeepPressUnpress(
                      onTap: () {
                        setState(() {
                          _controller.value.isPlaying
                              ? _controller.pause()
                              : _controller.play();
                        });
                      },
                      child: Image.asset(
                        _controller.value.isPlaying
                            ? '${defaultImagePath}video_pause.png'
                            : '${defaultImagePath}video_play.png',
                        width: 150.w,
                      ),
                    ),
                    SizedBox(width: 12.w),

                    Text(
                      _formatDuration(_controller.value.position),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Expanded(
                      child: VideoProgressIndicator(
                        _controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Colors.white,
                          bufferedColor: Colors.white30,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),

                    SizedBox(width: 8.w),

                    Text(
                      _formatDuration(_controller.value.duration),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 40.sp,
                        fontWeight: FontWeight.w500,
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

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
