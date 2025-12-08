import 'dart:convert';
import 'dart:io';
import 'package:ai_dress_up/view_model/thumbnail_generator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/video_result_model.dart';

final videoResultProvider = ChangeNotifierProvider<VideoResultNotifier>((ref) {
  return VideoResultNotifier();
});

class VideoResultNotifier extends ChangeNotifier {
  static const String _storageKey = 'video_results_history_secure';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  List<VideoResultModel> _videos = [];
  bool _isLoading = false;
  bool _isInitialized = false;

  List<VideoResultModel> get videos => _videos;
  int get videoCount => _videos.length;
  bool get isEmpty => _videos.isEmpty;
  bool get isLoading => _isLoading;

  /// Load videos from Secure Storage
  Future<void> loadVideos() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = await _secureStorage.read(key: _storageKey);

      debugPrint('📦 Loading videos from secure storage...');

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _videos = jsonList.map((json) => VideoResultModel.fromJson(json)).toList();
        debugPrint('✅ Loaded ${_videos.length} videos from secure storage');
      } else {
        debugPrint('📦 No videos found in secure storage');
        _videos = [];
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error loading videos (secure): $e');
      _videos = [];
      _isInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Add new video result with automatic thumbnail generation
  Future<void> addVideo(String videoPath, {String? title, String? thumbnailUrl}) async {
    try {
      if (!_isInitialized) await loadVideos();

      final existingIndex = _videos.indexWhere((v) => v.videoUrl == videoPath);
      if (existingIndex != -1) {
        debugPrint('⚠️ Video already exists in history, skipping duplicate');
        return;
      }

      String? finalThumbnailUrl = thumbnailUrl;

      if (finalThumbnailUrl == null || finalThumbnailUrl.isEmpty) {
        debugPrint('🎬 No thumbnail provided, generating...');

        if (videoPath.startsWith('http://') || videoPath.startsWith('https://')) {
          finalThumbnailUrl = await ThumbnailGenerator.generateFromUrl(videoPath);
        } else {
          finalThumbnailUrl = await ThumbnailGenerator.generateFromLocalVideo(videoPath);
        }

        if (finalThumbnailUrl != null) {
          debugPrint('✅ Thumbnail generated successfully');
        } else {
          debugPrint('⚠️ Failed to generate thumbnail, using default icon');
        }
      }

      final videoResult = VideoResultModel(
        videoUrl: videoPath,
        title: title ?? 'Video ${DateTime.now().millisecondsSinceEpoch}',
        thumbnailUrl: finalThumbnailUrl,
        timestamp: DateTime.now(),
      );

      _videos.insert(0, videoResult);
      await _saveToSecureStorage();
      notifyListeners();

      debugPrint('✅ Video added to history: $videoPath');
      debugPrint('📊 Total videos now: ${_videos.length}');
    } catch (e) {
      debugPrint('❌ Error adding video (secure): $e');
      rethrow;
    }
  }

  /// Regenerate thumbnail for a specific video
  Future<void> regenerateThumbnail(int index) async {
    try {
      if (index < 0 || index >= _videos.length) return;

      final video = _videos[index];
      debugPrint('🔄 Regenerating thumbnail for: ${video.videoUrl}');

      String? newThumbnail;
      if (video.videoUrl.startsWith('http://') || video.videoUrl.startsWith('https://')) {
        newThumbnail = await ThumbnailGenerator.generateFromUrl(video.videoUrl);
      } else {
        newThumbnail = await ThumbnailGenerator.generateFromLocalVideo(video.videoUrl);
      }

      if (newThumbnail != null) {
        if (video.thumbnailUrl != null) {
          await ThumbnailGenerator.deleteThumbnail(video.thumbnailUrl);
        }

        _videos[index] = VideoResultModel(
          videoUrl: video.videoUrl,
          title: video.title,
          thumbnailUrl: newThumbnail,
          timestamp: video.timestamp,
        );

        await _saveToSecureStorage();
        notifyListeners();
        debugPrint('✅ Thumbnail regenerated successfully');
      }
    } catch (e) {
      debugPrint('❌ Error regenerating thumbnail (secure): $e');
    }
  }

  /// Delete a video from history
  Future<void> deleteVideo(int index) async {
    try {
      if (index >= 0 && index < _videos.length) {
        final deletedVideo = _videos[index];
        final videoPath = deletedVideo.videoUrl;

        if (deletedVideo.thumbnailUrl != null) {
          await ThumbnailGenerator.deleteThumbnail(deletedVideo.thumbnailUrl);
        }

        if (videoPath.startsWith('/')) {
          final file = File(videoPath);
          if (await file.exists()) {
            await file.delete();
            debugPrint('🗑️ Deleted local file: $videoPath');
          }
        }

        _videos.removeAt(index);
        await _saveToSecureStorage();
        notifyListeners();
        debugPrint('🗑️ Removed video entry: ${deletedVideo.videoUrl}');
      }
    } catch (e) {
      debugPrint('❌ Error deleting video (secure): $e');
      rethrow;
    }
  }

  /// Clear all videos (and optionally local files)
  Future<void> clearAll({bool deleteLocalFiles = true}) async {
    try {
      if (deleteLocalFiles) {
        for (final video in _videos) {
          if (video.thumbnailUrl != null) {
            await ThumbnailGenerator.deleteThumbnail(video.thumbnailUrl);
          }

          final file = File(video.videoUrl);
          if (await file.exists()) {
            await file.delete();
          }
        }
        debugPrint('🧹 Deleted all local video files and thumbnails');
      }

      _videos.clear();
      await _secureStorage.delete(key: _storageKey);
      notifyListeners();
      debugPrint('🗑️ Cleared all video entries');
    } catch (e) {
      debugPrint('❌ Error clearing videos (secure): $e');
      rethrow;
    }
  }

  /// Save to Secure Storage
  Future<void> _saveToSecureStorage() async {
    try {
      final jsonString = jsonEncode(_videos.map((v) => v.toJson()).toList());
      await _secureStorage.write(key: _storageKey, value: jsonString);
      debugPrint('💾 Saved ${_videos.length} videos to secure storage');
    } catch (e) {
      debugPrint('❌ Error saving to secure storage: $e');
      rethrow;
    }
  }
}
