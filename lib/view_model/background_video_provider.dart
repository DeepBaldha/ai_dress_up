import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../api_services/sea_art_scrap_services.dart';
import '../api_services/upload_image_to_seaart_service.dart';
import '../model/video_model.dart';
import '../utils/utils.dart';
import 'credit_provider.dart';
import 'free_usage_provider.dart';

/// Background task state
class BackgroundVideoTask {
  final String taskId;
  final VideoModel model;
  final String imagePath;
  final DateTime startTime;
  final int progress; // 0-100
  final String status; // 'processing', 'completed', 'failed'
  final String? videoUrl;
  final String? errorMessage;
  final bool hasUserSeenResult;

  const BackgroundVideoTask({
    required this.taskId,
    required this.model,
    required this.imagePath,
    required this.startTime,
    this.progress = 0,
    this.status = 'processing',
    this.videoUrl,
    this.errorMessage,
    this.hasUserSeenResult = false,
  });

  BackgroundVideoTask copyWith({
    int? progress,
    String? status,
    String? videoUrl,
    String? errorMessage,
    bool? hasUserSeenResult,
  }) {
    return BackgroundVideoTask(
      taskId: taskId,
      model: model,
      imagePath: imagePath,
      startTime: startTime,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      errorMessage: errorMessage ?? this.errorMessage,
      hasUserSeenResult: hasUserSeenResult ?? this.hasUserSeenResult,
    );
  }

  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
}

/// Background video generation state
class BackgroundVideoState {
  final BackgroundVideoTask? currentTask;

  const BackgroundVideoState({this.currentTask});

  BackgroundVideoState copyWith({
    BackgroundVideoTask? currentTask,
  }) {
    return BackgroundVideoState(
      currentTask: currentTask,
    );
  }

  bool get isProcessing => currentTask?.isProcessing ?? false;
  bool get hasTask => currentTask != null;
}

/// Background Video Generation Notifier
class BackgroundVideoNotifier extends StateNotifier<BackgroundVideoState> {
  final Ref ref;
  Timer? _pollingTimer;

  BackgroundVideoNotifier(this.ref) : super(const BackgroundVideoState());

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Start background video generation
  Future<void> startGeneration({
    required BuildContext context,
    required VideoModel model,
    required String imagePath,
  }) async {
    if (state.isProcessing) {
      showToast('A video is already being generated. Please wait.');
      return;
    }

    showLog('🚀 Starting background generation for ${model.title}');

    // Check if video can be used for free
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

    try {
      // Step 1: Create task based on API type
      String? taskId;

      switch (model.apiType) {
        case 'seaart_scrap_prompt':
          taskId = await _createTaskForPrompt(model, imagePath);
          break;
        case 'seaart_scrap_tempid':
          taskId = await _createTaskForTemplate(model, imagePath);
          break;
        case 'seaart_scrap_apply':
          taskId = await _createTaskForApply(model, imagePath);
          break;
        default:
          throw Exception('Background generation not supported for ${model.apiType}');
      }

      if (taskId == null) {
        throw Exception('Failed to create video task');
      }

      showLog('✅ Task created: $taskId');

      // Step 2: Create background task
      final task = BackgroundVideoTask(
        taskId: taskId,
        model: model,
        imagePath: imagePath,
        startTime: DateTime.now(),
      );

      state = state.copyWith(currentTask: task);

      // Step 3: Start polling
      _startPolling();

      showToast('Video generation started! You can navigate away.');
    } catch (e) {
      showLog('❌ Error starting generation: $e');

      // Refund credits on error
      await _refundCredits(model);

      showToast('Failed to start generation: $e');
      state = const BackgroundVideoState();
    }
  }

  /// Create task for prompt-based generation
  Future<String?> _createTaskForPrompt(VideoModel model, String imagePath) async {
    final notifier = ref.read(seaArtScarpProvider.notifier);

    // Upload image first
    final uploadNotifier = ref.read(uploadImageToSeaArtProvider.notifier);
    final imageUrl = await uploadNotifier.handleUpload(filePath: imagePath);

    if (imageUrl == null) return null;

    // Create task
    return await notifier.createVideoTask(
      imageUrl: imageUrl,
      prompt: model.prompt,
      modelNo: model.seaArtModelNo,
      versionNo: model.seaArtVersionNo,
    );
  }

  /// Create task for template-based generation
  Future<String?> _createTaskForTemplate(VideoModel model, String imagePath) async {
    final notifier = ref.read(seaArtScarpProvider.notifier);

    final uploadNotifier = ref.read(uploadImageToSeaArtProvider.notifier);
    final imageUrl = await uploadNotifier.handleUpload(filePath: imagePath);

    if (imageUrl == null) return null;

    return await notifier.createVideoTaskForTemplateId(
      imageUrl: imageUrl,
      templateId: model.seaArtTemplateId,
    );
  }

  /// Create task for apply-based generation
  Future<String?> _createTaskForApply(VideoModel model, String imagePath) async {
    final notifier = ref.read(seaArtScarpProvider.notifier);

    return await notifier.createVideoTaskForApplyId(
      imagePath: imagePath,
      videoModel: model,
    );
  }

  /// Start polling for progress
  void _startPolling() {
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 8), (timer) async {
      final task = state.currentTask;
      if (task == null || !task.isProcessing) {
        timer.cancel();
        return;
      }

      await _pollProgress(task);
    });

    // Initial poll
    Future.delayed(const Duration(seconds: 2), () {
      if (state.currentTask?.isProcessing ?? false) {
        _pollProgress(state.currentTask!);
      }
    });
  }

  /// Poll progress from API
  Future<void> _pollProgress(BackgroundVideoTask task) async {
    try {
      final result = await _checkTaskProgress(task.taskId);

      if (result != null) {
        final progress = result['progress'] as int;
        final status = result['status'] as String;
        final videoUrl = result['videoUrl'] as String?;

        showLog('📊 Task ${task.taskId}: $progress% ($status)');

        if (status == 'completed' && videoUrl != null) {
          // Task completed
          state = state.copyWith(
            currentTask: task.copyWith(
              progress: 100,
              status: 'completed',
              videoUrl: videoUrl,
            ),
          );

          _pollingTimer?.cancel();
          showLog('✅ Video generation completed!');

          // Show notification or update UI
          _notifyCompletion();
        } else if (status == 'failed') {
          // Task failed
          state = state.copyWith(
            currentTask: task.copyWith(
              status: 'failed',
              errorMessage: 'Video generation failed',
            ),
          );

          _pollingTimer?.cancel();
          await _refundCredits(task.model);
          showLog('❌ Video generation failed');
        } else {
          // Still processing
          state = state.copyWith(
            currentTask: task.copyWith(progress: progress),
          );
        }
      }
    } catch (e) {
      showLog('❌ Error polling progress: $e');
    }
  }

  /// Check task progress via API
  Future<Map<String, dynamic>?> _checkTaskProgress(String taskId) async {
    try {
      final notifier = ref.read(seaArtScarpProvider.notifier);

      // Call the polling method once
      final response = await notifier.pollTaskOnce(taskId);

      return response;
    } catch (e) {
      showLog('❌ Error checking task progress: $e');
      return null;
    }
  }

  /// Notify user of completion
  void _notifyCompletion() {
    // You can add local notification here
    showLog('🔔 Video generation completed! Ready to view.');
  }

  /// Mark result as seen by user
  void markResultAsSeen() {
    final task = state.currentTask;
    if (task != null) {
      state = state.copyWith(
        currentTask: task.copyWith(hasUserSeenResult: true),
      );
    }
  }

  /// Clear current task
  void clearTask() {
    _pollingTimer?.cancel();
    state = const BackgroundVideoState();
  }

  /// Refund credits on failure
  Future<void> _refundCredits(VideoModel model) async {
    final freeVideoNotifier = ref.read(freeVideoUsageProvider.notifier);
    final wasFree = freeVideoNotifier.getUpdatedVideo(model).isOneTimeFree == false &&
        model.isOneTimeFree == true;

    if (wasFree) {
      await ref.read(freeVideoStorageServiceProvider).removeUsedVideo(model.userName);
      await freeVideoNotifier.refresh();
      showLog('🔄 Restored FREE status for: ${model.userName}');
    } else {
      final creditNotifier = ref.read(creditProvider.notifier);
      await creditNotifier.addCredit(model.creditCharge);
      showLog('💸 Refunded ${model.creditCharge} credits due to error');
    }
  }
}

/// Provider
final backgroundVideoProvider = StateNotifierProvider<BackgroundVideoNotifier, BackgroundVideoState>((ref) {
  return BackgroundVideoNotifier(ref);
});