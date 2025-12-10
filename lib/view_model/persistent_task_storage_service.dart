import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/utils.dart';

/// Service to persist pending task data across app restarts
class PersistentTaskStorageService {
  static const String _keyTaskId = 'pending_task_id';
  static const String _keyApiType = 'pending_task_api_type';
  static const String _keyIsPending = 'is_task_pending';
  static const String _keyTimestamp = 'task_start_timestamp';

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Save pending task when it starts
  Future<void> savePendingTask({
    required String taskId,
    required String apiType,
  }) async {
    try {
      await _storage.write(key: _keyTaskId, value: taskId);
      await _storage.write(key: _keyApiType, value: apiType);
      await _storage.write(key: _keyIsPending, value: 'true');
      await _storage.write(
        key: _keyTimestamp,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      showLog('💾 Saved pending task: $taskId ($apiType)');
    } catch (e) {
      showLog('❌ Error saving pending task: $e');
    }
  }

  /// Check if there's a pending task
  Future<bool> hasPendingTask() async {
    try {
      final isPending = await _storage.read(key: _keyIsPending);
      return isPending == 'true';
    } catch (e) {
      showLog('❌ Error checking pending task: $e');
      return false;
    }
  }

  /// Get pending task details
  Future<Map<String, String>?> getPendingTask() async {
    try {
      final isPending = await _storage.read(key: _keyIsPending);

      if (isPending != 'true') {
        return null;
      }

      final taskId = await _storage.read(key: _keyTaskId);
      final apiType = await _storage.read(key: _keyApiType);
      final timestamp = await _storage.read(key: _keyTimestamp);

      if (taskId == null || apiType == null) {
        showLog('⚠️ Incomplete pending task data, clearing...');
        await clearPendingTask();
        return null;
      }

      return {
        'taskId': taskId,
        'apiType': apiType,
        'timestamp': timestamp ?? '',
      };
    } catch (e) {
      showLog('❌ Error getting pending task: $e');
      return null;
    }
  }

  /// Mark task as completed (clears pending flag)
  Future<void> markTaskCompleted() async {
    try {
      await _storage.write(key: _keyIsPending, value: 'false');
      showLog('✅ Marked task as completed');
    } catch (e) {
      showLog('❌ Error marking task completed: $e');
    }
  }

  /// Clear all pending task data
  Future<void> clearPendingTask() async {
    try {
      await _storage.delete(key: _keyTaskId);
      await _storage.delete(key: _keyApiType);
      await _storage.delete(key: _keyIsPending);
      await _storage.delete(key: _keyTimestamp);
      showLog('🗑️ Cleared pending task data');
    } catch (e) {
      showLog('❌ Error clearing pending task: $e');
    }
  }

  /// Get task age in minutes
  Future<int?> getTaskAgeInMinutes() async {
    try {
      final timestamp = await _storage.read(key: _keyTimestamp);
      if (timestamp == null) return null;

      final startTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(timestamp),
      );
      final now = DateTime.now();
      final difference = now.difference(startTime);

      return difference.inMinutes;
    } catch (e) {
      showLog('❌ Error getting task age: $e');
      return null;
    }
  }
}

final persistentTaskStorageProvider = Provider<PersistentTaskStorageService>((
  ref,
) {
  return PersistentTaskStorageService();
});
