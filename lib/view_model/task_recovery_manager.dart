import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/global_variables.dart';
import '../view_model/video_result_provider.dart';
import 'persistent_task_storage_service.dart';
import '../utils/utils.dart';

/// Manager to recover and process pending tasks after app restart
class TaskRecoveryManager {
  final Ref ref;

  TaskRecoveryManager(this.ref);

  /// Check and recover pending task silently in background
  Future<void> checkAndRecoverPendingTaskSilently() async {
    try {
      final storage = ref.read(persistentTaskStorageProvider);

      final hasPending = await storage.hasPendingTask();

      if (!hasPending) {
        showLog('✅ No pending tasks found');
        return;
      }

      // Get pending task details
      final taskData = await storage.getPendingTask();

      if (taskData == null) {
        showLog('⚠️ Pending task data is null');
        return;
      }

      final taskId = taskData['taskId']!;
      final apiType = taskData['apiType']!;

      showLog('🔄 Found pending task: $taskId ($apiType)');

      // Check task age (optional: skip if too old)
      final ageInMinutes = await storage.getTaskAgeInMinutes();
      if (ageInMinutes != null && ageInMinutes > 60) {
        showLog('⚠️ Task is too old ($ageInMinutes minutes), clearing...');
        await storage.clearPendingTask();
        return;
      }

      // Silently recover the task
      await _recoverTaskSilently(taskId, apiType, storage);
    } catch (e) {
      showLog('❌ Error checking pending task: $e');
    }
  }

  /// Recover and process the pending task silently
  Future<void> _recoverTaskSilently(
      String taskId,
      String apiType,
      PersistentTaskStorageService storage,
      ) async {
    try {
      showLog('🔄 Silently recovering task: $taskId');

      final isSeaArt = apiType == 'seaart_scrap_prompt' ||
          apiType == 'seaart_scrap_tempid' ||
          apiType == 'seaart_scrap_apply';

      showLog('here1');
      if (!isSeaArt) {
        showLog('⚠️ Non-SeaArt API, cannot recover: $apiType');
        await storage.clearPendingTask();
        return;
      }

      showLog('here2');

      // Try to get the result directly
      final result = await _getTaskResult(taskId);
      showLog('here10');

      if (result == null) {
        showLog('⚠️ Could not get task result, will retry next time');
        return;
      }

      final status = result['status'] as String;
      final videoUrl = result['videoUrl'] as String?;

      showLog('📊 Recovered task status: $status');

      if (status == 'completed' && videoUrl != null) {
        showLog('✅ Task completed, downloading silently...');
        await _downloadAndSaveVideoSilently(videoUrl, storage);
      } else if (status == 'failed') {
        showLog('❌ Task failed, clearing storage');
        await storage.clearPendingTask();
      } else {
        showLog('⏳ Task still processing, will check again next time');
      }
    } catch (e) {
      showLog('❌ Error recovering task: $e');
    }
  }

  /// Get task result from API
  /// Get task result from API
  Future<Map<String, dynamic>?> _getTaskResult(String taskId) async {
    try {
      final url = 'https://www.seaart.ai/api/v1/task/batch-progress';

      final headers = {
        'cookie': GlobalVariables.seaArtCookie,
        'Content-Type': 'application/json',
      };

      showLog('here3');
      final response = await Dio().post(
        url,
        options: Options(headers: headers),
        data: {
          "task_ids": [taskId],
          "ss": 52,
        },
      );

      showLog('here4 with response : ${response.data} and code is ${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final json = response.data;

        showLog('here5 with data : $json');

        final items = json['data']?['items'];

        if (items != null && items.isNotEmpty) {
          final item = items[0];
          final statusDesc = item['status_desc']; // ✅ Use status_desc
          final int progress = item['process'] ?? 0; // ✅ Use process for progress

          String statusString;
          String? videoUrl;

          if (statusDesc == 'finish') {
            statusString = 'completed';
            // ✅ Get video URL from img_uris
            final uris = item['img_uris'];
            videoUrl = uris != null && uris.isNotEmpty ? uris[0]['url'] : null;
          } else if (statusDesc == 'waiting' || statusDesc == 'processing') {
            statusString = 'processing';
          } else {
            statusString = 'failed';
          }

          return {
            'status': statusString,
            'videoUrl': videoUrl,
            'progress': progress,
          };
        }
      }

      return null;
    } catch (e) {
      showLog('❌ Error getting task result: $e');
      return null;
    }
  }

  /// Download video and save to history silently
  Future<void> _downloadAndSaveVideoSilently(
      String videoUrl,
      PersistentTaskStorageService storage,
      ) async {
    try {
      showLog('⬇️ Downloading recovered video silently...');

      final dio = Dio();
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'recovered_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final filePath = '${dir.path}/$fileName';

      final response = await dio.download(videoUrl, filePath);

      if (response.statusCode == 200) {
        showLog('✅ Video downloaded: $filePath');

        // ✅ CRITICAL: Get the notifier instance and ensure videos are loaded
        final videoNotifier = ref.read(videoResultProvider);

        // ✅ Ensure videos are loaded before adding new one
        if (!videoNotifier.isInitialized) {
          await videoNotifier.loadVideos();
        }

        // ✅ Add video to history
        await videoNotifier.addVideo(
          filePath,
          title: 'Recovered Video',
          thumbnailUrl: null,
        );

        // ✅ Wait for storage operations to complete
        await Future.delayed(const Duration(milliseconds: 300));

        // ✅ Mark as completed first
        await storage.markTaskCompleted();

        showLog('✅ Marked task as completed');

        // ✅ Clear pending task AFTER everything is saved and propagated
        await storage.clearPendingTask();

        showLog('✅ Video recovered and saved successfully (SILENT)');
      } else {
        throw Exception('Download failed: ${response.statusCode}');
      }
    } catch (e) {
      showLog('❌ Error downloading video silently: $e');
      // Don't clear storage - retry next time
    }
  }
}

/// Provider
final taskRecoveryManagerProvider = Provider<TaskRecoveryManager>((ref) {
  return TaskRecoveryManager(ref);
});