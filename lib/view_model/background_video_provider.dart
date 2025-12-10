import 'dart:async';
import 'package:ai_dress_up/view_model/persistent_task_storage_service.dart';
import 'package:ai_dress_up/view_model/video_result_provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';
import '../api_services/sea_art_scrap_services.dart';
import '../model/video_model.dart';
import '../utils/consts.dart';
import '../utils/utils.dart';

/// Background Task State
class BackgroundTaskState {
  final String? taskId;
  final String? apiType;
  final VideoModel? videoModel;
  final int progress; // 0-100
  final String status; // 'none', 'polling', 'downloading', 'completed', 'failed'
  final String? videoUrl;
  final String? localVideoPath;
  final String? errorMessage;

  const BackgroundTaskState({
    this.taskId,
    this.apiType,
    this.videoModel,
    this.progress = 0,
    this.status = 'none',
    this.videoUrl,
    this.localVideoPath,
    this.errorMessage,
  });

  bool get hasActiveTask => status != 'none' && status != 'completed' && status != 'failed';
  bool get isCompleted => status == 'completed';
  bool get hasFailed => status == 'failed';

  BackgroundTaskState copyWith({
    String? taskId,
    String? apiType,
    VideoModel? videoModel,
    int? progress,
    String? status,
    String? videoUrl,
    String? localVideoPath,
    String? errorMessage,
  }) {
    return BackgroundTaskState(
      taskId: taskId ?? this.taskId,
      apiType: apiType ?? this.apiType,
      videoModel: videoModel ?? this.videoModel,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      videoUrl: videoUrl ?? this.videoUrl,
      localVideoPath: localVideoPath ?? this.localVideoPath,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Background Task Notifier
class BackgroundTaskNotifier extends StateNotifier<BackgroundTaskState> {
  final Ref ref;
  Timer? _pollTimer;

  BackgroundTaskNotifier(this.ref) : super(const BackgroundTaskState());

  /// Start background task with taskId
  void startBackgroundTask({
    required String taskId,
    required String apiType,
    required VideoModel videoModel,
  }) {
    if (state.hasActiveTask) {
      showLog('⚠️ Background task already running, cannot start new one');
      return;
    }

    showLog('🚀 Starting background task: $taskId');

    state = BackgroundTaskState(
      taskId: taskId,
      apiType: apiType,
      videoModel: videoModel,
      progress: 0,
      status: 'polling',
    );

    _startPolling();
  }

  /// Start polling SeaArt task
  void _startPolling() {
    _pollTimer?.cancel();

    _pollTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (!state.hasActiveTask || state.taskId == null) {
        timer.cancel();
        return;
      }

      await _pollOnce();
    });
  }

  /// Poll task once
  Future<void> _pollOnce() async {
    if (state.taskId == null) return;

    try {
      final seaArtNotifier = ref.read(seaArtScarpProvider.notifier);
      final result = await seaArtNotifier.pollTaskOnce(state.taskId!);

      if (result == null) {
        showLog('⚠️ Poll returned null, retrying...');
        return;
      }

      final progress = result['progress'] as int;
      final status = result['status'] as String;
      final videoUrl = result['videoUrl'] as String?;

      showLog('📊 Background poll: $progress% - $status');

      state = state.copyWith(progress: progress);

      if (status == 'completed' && videoUrl != null) {
        _pollTimer?.cancel();
        showLog('✅ Video generation completed: $videoUrl');
        state = state.copyWith(
          videoUrl: videoUrl,
          status: 'downloading',
        );

        await _downloadVideo(videoUrl);
      } else if (status == 'failed') {
        _pollTimer?.cancel();
        showLog('❌ Video generation failed');
        state = state.copyWith(
          status: 'failed',
          errorMessage: 'Video generation failed',
        );
      }
    } catch (e) {
      showLog('❌ Background polling error: $e');
      // Don't fail immediately, retry on next poll
    }
  }

  /// Download video to local storage
  Future<void> _downloadVideo(String videoUrl) async {
    try {
      showLog('⬇️ Starting background download...');

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${dir.path}/$fileName';

      final response = await dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            final downloadProgress = (received / total * 100).toInt();
            state = state.copyWith(progress: downloadProgress);
            showLog('📥 Download progress: $downloadProgress%');
          }
        },
      );

      if (response.statusCode == 200) {
        showLog('✅ Download complete: $filePath');

        // 🔥 AUTO-SAVE TO HISTORY
        try {
          showLog("💾 Auto-saving video to history...");
          await ref.read(videoResultProvider).addVideo(
            filePath,
            title: 'Video ${DateTime.now().millisecondsSinceEpoch}',
            thumbnailUrl: null,
          );
          final context = navigatorKey.currentContext;
          if (context != null && context.mounted) {
            showToast(getTranslated(context)!.videoGeneratedSuccessfullyAndMovedToCreation);
          }
          await ref.read(persistentTaskStorageProvider).clearPendingTask();
          showLog("✅ Auto-saved to history successfully");
        } catch (e) {
          showLog("❌ Auto-save failed: $e");
        }

        state = state.copyWith(
          status: 'completed',
          localVideoPath: filePath,
          progress: 100,
        );
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      showLog('❌ Download error: $e');
      state = state.copyWith(
        status: 'failed',
        errorMessage: 'Download failed: $e',
      );
    }
  }

  /// Clear completed/failed task
  void clearTask() {

    if (state.hasActiveTask && !state.isCompleted && !state.hasFailed) {
      showLog('⚠️ Cannot clear task - still running');
      return;
    }

    showLog('🗑️ Clearing background task');
    _pollTimer?.cancel();
    state = const BackgroundTaskState();
  }

  /// Cancel active task
  void cancelTask() {
    showLog('🛑 Cancelling background task');
    _pollTimer?.cancel();

    ref.read(persistentTaskStorageProvider).clearPendingTask();

    state = state.copyWith(
      status: 'failed',
      errorMessage: 'Cancelled by user',
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

/// Provider
final backgroundTaskProvider =
StateNotifierProvider<BackgroundTaskNotifier, BackgroundTaskState>((ref) {
  return BackgroundTaskNotifier(ref);
});