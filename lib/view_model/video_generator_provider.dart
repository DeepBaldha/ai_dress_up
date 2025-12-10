import 'package:ai_dress_up/view_model/persistent_task_storage_service.dart';
import 'package:ai_dress_up/view_model/video_result_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import '../ads/ads_variable.dart';
import '../api_services/dezgo_image_prompt.dart';
import '../api_services/pollo_ai_scrap_service.dart';
import '../api_services/pollo_api_services.dart';
import '../api_services/sea_art_scrap_services.dart';
import '../api_services/upload_image_to_seaart_service.dart';
import '../model/video_model.dart';
import '../utils/custom_widgets/loading_with_percentage.dart';
import '../utils/firebase_analytics_service.dart';
import '../utils/loading_dialog.dart';
import '../utils/utils.dart';
import '../view/image_result_full_screen.dart';
import '../view/video_result_screen.dart';
import 'background_video_provider.dart';
import 'credit_provider.dart';
import 'free_usage_provider.dart';

/// State model
class VideoGenerateState {
  final bool isLoading;
  final bool isDownloading;
  final String? videoUrl;
  final String? localImagePath;
  final String? errorMessage;
  final double downloadProgress;
  final int generationProgress;
  final String? currentTaskId; // 🔥 Track task ID
  final String? currentApiType; // 🔥 Track API type
  final VideoModel? currentVideoModel; // 🔥 Track video model

  const VideoGenerateState({
    this.isLoading = false,
    this.isDownloading = false,
    this.videoUrl,
    this.localImagePath,
    this.errorMessage,
    this.downloadProgress = 0.0,
    this.generationProgress = 0,
    this.currentTaskId,
    this.currentApiType,
    this.currentVideoModel,
  });

  VideoGenerateState copyWith({
    bool? isLoading,
    bool? isDownloading,
    String? videoUrl,
    String? localImagePath,
    String? errorMessage,
    double? downloadProgress,
    int? generationProgress,
    String? currentTaskId,
    String? currentApiType,
    VideoModel? currentVideoModel,
  }) {
    return VideoGenerateState(
      isLoading: isLoading ?? this.isLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      videoUrl: videoUrl,
      localImagePath: localImagePath,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      generationProgress: generationProgress ?? this.generationProgress,
      currentTaskId: currentTaskId ?? this.currentTaskId,
      currentApiType: currentApiType ?? this.currentApiType,
      currentVideoModel: currentVideoModel ?? this.currentVideoModel,
    );
  }

  bool get isSeaArtApi =>
      currentApiType == 'seaart_scrap_prompt' ||
          currentApiType == 'seaart_scrap_tempid' ||
          currentApiType == 'seaart_scrap_apply';

  bool get canMoveToBackground => isSeaArtApi && currentTaskId != null;
}

/// Provider (Notifier)
class VideoGenerateNotifier extends StateNotifier<VideoGenerateState> {
  final Ref ref;
  VideoGenerateNotifier(this.ref) : super(const VideoGenerateState());

  /// Main method: determine API type and call appropriate generator
  Future<void> generate(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    if (state.isLoading) return;

    // 🔥 Check if background task is already running
    final bgTask = ref.read(backgroundTaskProvider);
    if (bgTask.hasActiveTask) {
      showToast('A video is already being generated in background');
      return;
    }

    state = state.copyWith(
      isLoading: true,
      isDownloading: false,
      errorMessage: null,
      videoUrl: null,
      localImagePath: null,
      downloadProgress: 0.0,
      generationProgress: 0,
      currentTaskId: null,
      currentApiType: model.apiType,
      currentVideoModel: model,
    );

    bool useProgressDialog = model.apiType != 'dezgo_image';

    if (useProgressDialog) {
      LoadingProgressDialog.onHideCallback = () {
        _moveToBackground(context);
      };

      LoadingProgressDialog.show(
        context,
        percentage: 0,
        message1: '${getTranslated(context)!.processing}...',
        message2: getTranslated(
          context,
        )!.yourResultIsOnTheWayJustAFewMinutesToGo,
      );
    } else {
      LoadingDialog.show(
        context,
        message: getTranslated(context)!.processing,
        secondMessage: getTranslated(context)!.yourResultIsOnTheWayJustAFewMinutesToGo,
      );
    }

    showLog('🚀 Starting generation for ${model.title} (${model.apiType})');

    final freeVideoNotifier = ref.read(freeVideoUsageProvider.notifier);
    final canUseFree = freeVideoNotifier.canUseFree(model);

    if (canUseFree) {
      await freeVideoNotifier.markAsUsed(model);
      showLog('🎁 Using FREE video (one-time): ${model.userName}');
    } else {
      final creditNotifier = ref.read(creditProvider.notifier);
      await creditNotifier.deductCredit(model.creditCharge);
      showLog('💰 Deducted ${model.creditCharge} credits');
    }

    bool shouldRefund = false;

    final cleanName = model.userName.replaceFirst('@', '');

    FirebaseAnalyticsService.logEvent(eventName: "GENERATING_VIDEO_$cleanName");

    try {
      switch (model.apiType) {
        case 'pollo_api':
          await _generatePolloApi(context, model, imagePath);
          break;
        case 'pollo_scrap':
          await _generatePolloScrap(context, model, imagePath);
          break;
        case 'seaart_scrap_prompt':
          await _generateSeaArtPrompt(context, model, imagePath);
          break;
        case 'seaart_scrap_tempid':
          await _generateSeaArtTemplate(context, model, imagePath);
          break;
        case 'seaart_scrap_apply':
          await _generateSeaArtApply(context, model, imagePath);
          break;
        case 'dezgo_image':
          await _generateDezgoImage(context, model, imagePath);
          break;
        default:
          shouldRefund = true;
          throw Exception('❌ Unknown API type: ${model.apiType}');
      }

      if (state.errorMessage != null) {
        shouldRefund = true;
      }
    } catch (e) {
      shouldRefund = true;
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      showLog('❌ Error generating video: $e');

      // ✅ Hide loader on error
      if (context.mounted) {
        if (useProgressDialog) {
          LoadingProgressDialog.hide(context);
        } else {
          LoadingDialog.hide(context);
        }
      }
    } finally {
      // 💸 Refund if any error occurred
      if (shouldRefund) {
        if (AdsVariable.showIMTester) {
          return;
        }

        final freeVideoNotifier = ref.read(freeVideoUsageProvider.notifier);
        final wasFree =
            freeVideoNotifier.getUpdatedVideo(model).isOneTimeFree == false &&
                model.isOneTimeFree == true;

        if (wasFree) {
          await ref
              .read(freeVideoStorageServiceProvider)
              .removeUsedVideo(model.userName);
          await freeVideoNotifier.refresh();
          showLog('🔄 Restored FREE status for: ${model.userName}');
        } else {
          final creditNotifier = ref.read(creditProvider.notifier);
          await creditNotifier.addCredit(model.creditCharge);
          showLog('💸 Refunded ${model.creditCharge} credits due to error');
        }
      }

      // 🔥 Clear callback
      LoadingProgressDialog.onHideCallback = null;
    }
  }

  /// POLLO API (prompt-based)
  Future<void> _generatePolloApi(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    showLog('here1');
    final notifier = ref.read(polloApiProvider.notifier);
    await notifier.makePolloAiApiCall(fileUrl: imagePath, prompt: model.prompt);

    final data = ref.read(polloApiProvider);
    await _handleResult(context, data.videoUrl, data.error);
  }

  /// POLLO SCRAP (template-based)
  Future<void> _generatePolloScrap(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    final notifier = ref.read(polloAiScrapProvider.notifier);
    await notifier.uploadAndGetResultUsingPollScrap(
      filePath: imagePath,
      templateId: model.poloTemplateId,
    );

    final data = ref.read(polloAiScrapProvider);
    await _handleResult(context, data.videoUrl, data.error);
  }

  /// SEAART SCRAP (prompt-based)
  Future<void> _generateSeaArtPrompt(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    final notifier = ref.read(seaArtScarpProvider.notifier);

    final taskId = await notifier.createVideoTask(
      imageUrl: await _uploadImageForSeaArt(imagePath),
      prompt: model.prompt,
      modelNo: model.seaArtModelNo,
      versionNo: model.seaArtVersionNo,
    );

    if (taskId != null) {
      state = state.copyWith(currentTaskId: taskId);
      showLog('✅ Got task ID: $taskId');

      await ref.read(persistentTaskStorageProvider).savePendingTask(
        taskId: taskId,
        apiType: model.apiType,
      );

      // 🔥 Show hide button now that we have task ID
      if (context.mounted) {
        LoadingProgressDialog.update(
          context,
          0,
          message1: '${getTranslated(context)!.processing}... (0%)',
          message2: getTranslated(context)!.yourResultIsOnTheWayJustAFewMinutesToGo,
          showHideButton: true
        );
      }

      // Now poll the task
      final videoUrl = await notifier.getVideoUrlByTaskId(
        taskId,
        onProgressUpdate: (progress) {
          state = state.copyWith(generationProgress: progress);
          if (context.mounted && state.isLoading) {
            LoadingProgressDialog.update(
              context,
              progress,
              message1: '${getTranslated(context)!.processing}... ($progress%)',
              message2: getTranslated(context)!.yourResultIsOnTheWayJustAFewMinutesToGo,
            );
          }
        },
      );

      await _handleResult(context, videoUrl, null);
    } else {
      await _handleResult(context, null, 'Failed to create task');
    }
  }

  /// SEAART SCRAP (templateId-based)
  Future<void> _generateSeaArtTemplate(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    final notifier = ref.read(seaArtScarpProvider.notifier);

    final imageUrl = await _uploadImageForSeaArt(imagePath);

    final taskId = await notifier.createVideoTaskForTemplateId(
      imageUrl: imageUrl,
      templateId: model.seaArtTemplateId,
    );

    if (taskId != null) {
      state = state.copyWith(currentTaskId: taskId);
      showLog('✅ Got task ID: $taskId');


      await ref.read(persistentTaskStorageProvider).savePendingTask(
        taskId: taskId,
        apiType: model.apiType,
      );

      final videoUrl = await notifier.getVideoUrlByTaskId(
        taskId,
        onProgressUpdate: (progress) {
          state = state.copyWith(generationProgress: progress);
          if (context.mounted && state.isLoading) {
            LoadingProgressDialog.update(
              context,
              progress,
              message1: '${getTranslated(context)!.processing}... ($progress%)',
              message2: getTranslated(context)!.yourResultIsOnTheWayJustAFewMinutesToGo,
              showHideButton: true
            );
          }
        },
      );

      await _handleResult(context, videoUrl, null);
    } else {
      await _handleResult(context, null, 'Failed to create task');
    }
  }

  /// SEAART SCRAP (applyId-based)
  Future<void> _generateSeaArtApply(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    final notifier = ref.read(seaArtScarpProvider.notifier);

    // Create task
    final taskId = await notifier.createVideoTaskForApplyId(
      imagePath: imagePath,
      videoModel: model,
    );



    if (taskId != null) {
      state = state.copyWith(currentTaskId: taskId);
      showLog('✅ Got task ID: $taskId');

      await ref.read(persistentTaskStorageProvider).savePendingTask(
        taskId: taskId,
        apiType: model.apiType,
      );

      final videoUrl = await notifier.getVideoUrlByTaskId(
        taskId,
        onProgressUpdate: (progress) {
          state = state.copyWith(generationProgress: progress);
          if (context.mounted && state.isLoading) {
            LoadingProgressDialog.update(
              context,
              progress,
              message1: '${getTranslated(context)!.processing}... ($progress%)',
              message2: getTranslated(context)!.yourResultIsOnTheWayJustAFewMinutesToGo,
              showHideButton: true
            );
          }
        },
      );

      await _handleResult(context, videoUrl, null);
    } else {
      await _handleResult(context, null, 'Failed to create task');
    }
  }

  /// Helper: Upload image for SeaArt
  Future<String> _uploadImageForSeaArt(String imagePath) async {
    final uploadNotifier = ref.read(uploadImageToSeaArtProvider.notifier);
    final imageUrl = await uploadNotifier.handleUpload(filePath: imagePath);

    if (imageUrl == null) {
      throw Exception("Failed to upload image");
    }

    return imageUrl;
  }

  /// DEZGO IMAGE (image-to-image)
  Future<void> _generateDezgoImage(
      BuildContext context,
      VideoModel model,
      String imagePath,
      ) async {
    showLog('🎨 Starting Dezgo image generation');

    final notifier = ref.read(dezgoProcessProvider.notifier);
    showLog('call1');
    final localPath = await notifier.processImage(
      imagePath: imagePath,
      prompt: model.dezgoPrompt,
      strength: 0.8,
    );

    showLog('call2');

    final data = ref.read(dezgoProcessProvider);
    await _handleImageResult(context, localPath, data.error);
  }

  /// Handle image result (for Dezgo)
  Future<void> _handleImageResult(
      BuildContext context,
      String? localPath,
      String? error,
      ) async {
    if (localPath != null) {
      showLog('✅ Image generated successfully: $localPath');
      state = state.copyWith(isLoading: false, localImagePath: localPath);

      if (context.mounted) {
        LoadingDialog.hide(context);
      }

      await Future.delayed(const Duration(milliseconds: 150));

      if (context.mounted) {
        await _navigateToImageResult(context, localPath);
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        errorMessage: error ?? 'Unknown error',
      );

      if (context.mounted) {
        LoadingDialog.hide(context);
        showToast(getTranslated(context)!.someThingWentWrong);
        showLog('⚠️ Image generation failed: $error');
      }
    }
  }

  /// Navigate to image result screen
  Future<void> _navigateToImageResult(
      BuildContext context,
      String localPath,
      ) async {
    showLog('🚀 Navigating to ImageResultFullScreen...');

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ImageResultFullScreen(
          imagePath: localPath,
          autoSave: true,
          from: 'denzo_image',
        ),
      ),
    );

    showLog('✅ Navigation complete');
  }

  // Key changes in video_generate_provider.dart:

// 1. Fix _handleResult to not interfere with background tasks
  Future<void> _handleResult(
      BuildContext context,
      String? videoUrl,
      String? error,
      ) async {
    // 🔥 Check if task moved to background
    final bgTask = ref.read(backgroundTaskProvider);
    if (bgTask.hasActiveTask && bgTask.taskId == state.currentTaskId) {
      showLog("⛔ Task moved to background, skipping foreground handling");
      return;
    }

    // If we're no longer loading but background isn't handling it, something went wrong
    if (!state.isLoading) {
      showLog("⚠️ Foreground cancelled without background takeover");
      return;
    }

    if (videoUrl != null) {
      await ref.read(persistentTaskStorageProvider).markTaskCompleted();


      showLog('✅ Video generated successfully: $videoUrl');
      state = state.copyWith(
        isLoading: false,
        videoUrl: videoUrl,
        generationProgress: 100,
      );

      try {
        state = state.copyWith(isDownloading: true, downloadProgress: 0.0);

        if (context.mounted) {
          LoadingProgressDialog.update(
            context,
            100,
            message1: getTranslated(context)!.downloadingVideo,
            message2: getTranslated(context)!.pleaseWait,
          );
        }

        showLog('⬇️ Starting video download...');

        final localPath = await _downloadVideoToLocal(videoUrl, context);

        try {
          showLog("💾 Auto-saving video to history...");
          await ref.read(videoResultProvider).addVideo(
            localPath,
            title: 'Video ${DateTime.now().millisecondsSinceEpoch}',
            thumbnailUrl: null,
          );
          showLog("✅ Auto-saved to history successfully");
        } catch (e) {
          showLog("❌ Auto-save failed: $e");
        }

        state = state.copyWith(isDownloading: false, downloadProgress: 1.0);
        showLog('✅ Download complete. Local path: $localPath');

        if (!context.mounted) {
          showLog('⚠️ Context not mounted! Cannot navigate.');
          return;
        }

        LoadingProgressDialog.hide(context);
        showLog('✅ Loader hidden');

        await Future.delayed(const Duration(milliseconds: 150));

        if (!context.mounted) {
          showLog('⚠️ Context not mounted after delay! Cannot navigate.');
          return;
        }

        showLog('🚀 Navigating to ResultScreen...');
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoResultScreen(
              video: localPath,
              title: 'Generated Video',
              autoSave: true,
              from: 'generate',
            ),
          ),
        );
        showLog('✅ Navigation complete');
      } catch (e) {
        showLog('❌ Error downloading video: $e');
        state = state.copyWith(
          isDownloading: false,
          isLoading: false,
          errorMessage: 'Download failed: $e',
        );

        if (context.mounted) {
          LoadingProgressDialog.hide(context);
          showToast(getTranslated(context)!.someThingWentWrong);
          showLog(e.toString());
        }
      }
    } else {
      state = state.copyWith(
        isLoading: false,
        isDownloading: false,
        errorMessage: error ?? 'Unknown error',
      );

      if (context.mounted) {
        LoadingProgressDialog.hide(context);
        showLog('⚠️ Generation failed: $error');
      }
    }
  }

  void _moveToBackground(BuildContext context) {
    if (!state.canMoveToBackground) {
      showLog('⚠️ Cannot move to background - no task ID or not SeaArt API');
      return;
    }

    showLog('🔄 Moving to background: ${state.currentTaskId}');

    // Start background task
    ref.read(backgroundTaskProvider.notifier).startBackgroundTask(
      taskId: state.currentTaskId!,
      apiType: state.currentApiType!,
      videoModel: state.currentVideoModel!,
    );

    // 🔥 Clear foreground state properly
    state = const VideoGenerateState();

    showLog('✅ Moved to background successfully');
  }

  Future<String> _downloadVideoToLocal(
      String videoUrl,
      BuildContext context,
      ) async {
    final dio = Dio();
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    final filePath = '${dir.path}/$fileName';

    showLog('⬇️ Downloading video to: $filePath');

    final response = await dio.download(
      videoUrl,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = received / total;
          state = state.copyWith(downloadProgress: progress);

          if (context.mounted) {
            LoadingProgressDialog.update(
              context,
              100,
              message1:
              '${getTranslated(context)!.downloadingVideo}... (${(progress * 100).toStringAsFixed(0)}%)',
              message2: getTranslated(context)!.pleaseWait,
            );
          }

          showLog('📥 Download progress: ${(progress * 100).toStringAsFixed(0)}%');
        }
      },
    );

    if (response.statusCode == 200) {
      showLog('✅ Video downloaded successfully: $filePath');
      return filePath;
    } else {
      throw Exception('Failed to download video (status: ${response.statusCode})');
    }
  }
}

/// Riverpod provider
final videoGenerateProvider =
StateNotifierProvider<VideoGenerateNotifier, VideoGenerateState>((ref) {
  return VideoGenerateNotifier(ref);
});