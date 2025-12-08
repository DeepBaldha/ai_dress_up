import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class ThumbnailGenerator {
  /// Generate thumbnail from local video file
  static Future<String?> generateFromLocalVideo(String videoPath) async {
    try {
      debugPrint('🎬 Generating thumbnail for: $videoPath');

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 400,
        quality: 75,
      );

      if (thumbnailPath != null) {
        debugPrint('✅ Thumbnail generated: $thumbnailPath');
        return thumbnailPath;
      }

      debugPrint('⚠️ Thumbnail generation returned null');
      return null;
    } catch (e) {
      debugPrint('❌ Error generating thumbnail: $e');
      return null;
    }
  }

  /// Generate thumbnail from video URL
  static Future<String?> generateFromUrl(String videoUrl) async {
    try {
      debugPrint('🌐 Generating thumbnail from URL: $videoUrl');

      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.PNG,
        maxHeight: 400,
        quality: 75,
      );

      if (thumbnailPath != null) {
        debugPrint('✅ URL Thumbnail generated: $thumbnailPath');
        return thumbnailPath;
      }

      debugPrint('⚠️ URL Thumbnail generation returned null');
      return null;
    } catch (e) {
      debugPrint('❌ Error generating thumbnail from URL: $e');
      return null;
    }
  }

  /// Generate thumbnail as Uint8List (for immediate display without saving)
  static Future<String?> generateThumbnailData(String videoPath) async {
    try {
      final uint8list = await VideoThumbnail.thumbnailData(
        video: videoPath,
        imageFormat: ImageFormat.PNG,
        maxHeight: 400,
        quality: 75,
      );

      if (uint8list != null) {
        // Save to temp file for consistent handling
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.png');
        await file.writeAsBytes(uint8list);
        return file.path;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Error generating thumbnail data: $e');
      return null;
    }
  }

  /// Delete thumbnail file
  static Future<void> deleteThumbnail(String? thumbnailPath) async {
    if (thumbnailPath == null || thumbnailPath.isEmpty) return;

    try {
      final file = File(thumbnailPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('🗑️ Deleted thumbnail: $thumbnailPath');
      }
    } catch (e) {
      debugPrint('❌ Error deleting thumbnail: $e');
    }
  }

  /// Clean up old thumbnails (optional maintenance)
  static Future<void> cleanupOldThumbnails() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final files = tempDir.listSync();

      for (final file in files) {
        if (file.path.contains('thumb_') && file is File) {
          final stat = await file.stat();
          final age = DateTime.now().difference(stat.modified);

          // Delete thumbnails older than 30 days
          if (age.inDays > 30) {
            await file.delete();
            debugPrint('🧹 Cleaned up old thumbnail: ${file.path}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error cleaning thumbnails: $e');
    }
  }
}