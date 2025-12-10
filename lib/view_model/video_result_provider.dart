import 'dart:convert';
import 'dart:io';
import 'package:ai_dress_up/utils/shared_preference_utils.dart';
import 'package:ai_dress_up/view_model/thumbnail_generator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/video_result_model.dart';

final videoResultProvider =
ChangeNotifierProvider<VideoResultNotifier>((ref) {
  return VideoResultNotifier();
});

class VideoResultNotifier extends ChangeNotifier {
  static const String _storageKey = 'video_results_history_secure';

  List<VideoResultModel> _videos = [];
  bool _isLoading = false;
  bool isInitialized = false;

  List<VideoResultModel> get videos => _videos;
  int get videoCount => _videos.length;
  bool get isEmpty => _videos.isEmpty;
  bool get isLoading => _isLoading;

  Future<void> loadVideos() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final jsonString = SharedPreferenceUtils.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _videos = jsonList
            .map((json) => VideoResultModel.fromJson(json))
            .toList();
      } else {
        _videos = [];
      }

      isInitialized = true;
    } catch (e) {
      debugPrint('❌ Error loading videos: $e');
      _videos = [];
      isInitialized = true;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addVideo(
      String videoPath, {
        String? title,
        String? thumbnailUrl,
      }) async {
    try {
      if (!isInitialized) {
        await loadVideos();
      }

      // Avoid duplicates
      if (_videos.any((v) => v.videoUrl == videoPath)) {
        debugPrint('⚠️ Video already exists. Skipped.');
        return;
      }

      // Generate thumbnail if needed
      String? finalThumb = thumbnailUrl;

      if (finalThumb == null || finalThumb.isEmpty) {
        if (videoPath.startsWith('http')) {
          finalThumb =
          await ThumbnailGenerator.generateFromUrl(videoPath);
        } else {
          finalThumb = await ThumbnailGenerator.generateFromLocalVideo(
              videoPath);
        }
      }

      final newVideo = VideoResultModel(
        videoUrl: videoPath,
        title: title ?? 'Video ${DateTime.now().millisecondsSinceEpoch}',
        thumbnailUrl: finalThumb,
        timestamp: DateTime.now(),
      );

      _videos.insert(0, newVideo);

      await _save();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error adding video: $e');
    }
  }

  Future<void> _save() async {
    try {
      final jsonString =
      jsonEncode(_videos.map((v) => v.toJson()).toList());

      await SharedPreferenceUtils.saveString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('❌ Error saving videos: $e');
    }
  }

  Future<void> regenerateThumbnail(int index) async {
    try {
      if (index < 0 || index >= _videos.length) return;

      final video = _videos[index];
      String? newThumb;

      if (video.videoUrl.startsWith('http')) {
        newThumb =
        await ThumbnailGenerator.generateFromUrl(video.videoUrl);
      } else {
        newThumb =
        await ThumbnailGenerator.generateFromLocalVideo(video.videoUrl);
      }

      if (newThumb != null) {
        _videos[index] = VideoResultModel(
          videoUrl: video.videoUrl,
          title: video.title,
          thumbnailUrl: newThumb,
          timestamp: video.timestamp,
        );

        await _save();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Error regenerating thumbnail: $e');
    }
  }

  Future<void> deleteVideo(int index) async {
    try {
      if (index < 0 || index >= _videos.length) return;

      final video = _videos[index];

      // Delete local file if exists
      if (video.videoUrl.startsWith('/')) {
        final file = File(video.videoUrl);
        if (await file.exists()) await file.delete();
      }

      _videos.removeAt(index);

      await _save();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error deleting video: $e');
    }
  }

  Future<void> clearAll({bool deleteLocalFiles = true}) async {
    try {
      if (deleteLocalFiles) {
        for (final video in _videos) {
          if (video.videoUrl.startsWith('/')) {
            final file = File(video.videoUrl);
            if (await file.exists()) await file.delete();
          }
        }
      }

      _videos.clear();
      await SharedPreferenceUtils.saveString(_storageKey, "[]");

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error clearing videos: $e');
    }
  }
}
