import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FreeVideoStorageService {
  static const String _usedFreeVideosKey = 'used_free_videos_global';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Get all used free video userNames (global)
  Future<Set<String>> getUsedFreeVideoKeys() async {
    try {
      final String? data = await _secureStorage.read(key: _usedFreeVideosKey);
      if (data == null || data.isEmpty) return {};

      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => e.toString()).toSet();
    } catch (e) {
      print('Error reading used free videos: $e');
      return {};
    }
  }

  // Mark a video as used (global)
  Future<bool> markVideoAsUsed(String videoUserName) async {
    try {
      final usedVideos = await getUsedFreeVideoKeys();
      usedVideos.add(videoUserName);

      final encoded = jsonEncode(usedVideos.toList());
      await _secureStorage.write(key: _usedFreeVideosKey, value: encoded);
      return true;
    } catch (e) {
      print('Error marking video as used: $e');
      return false;
    }
  }

  // Check if a video has been used (global)
  Future<bool> hasVideoBeenUsed(String videoUserName) async {
    final usedVideos = await getUsedFreeVideoKeys();
    return usedVideos.contains(videoUserName);
  }

  // Clear all used videos (for testing)
  Future<void> clearUsedVideos() async {
    await _secureStorage.delete(key: _usedFreeVideosKey);
  }

  // Remove specific video from used list
  Future<bool> removeUsedVideo(String videoUserName) async {
    try {
      final usedVideos = await getUsedFreeVideoKeys();
      usedVideos.remove(videoUserName);

      final encoded = jsonEncode(usedVideos.toList());
      await _secureStorage.write(key: _usedFreeVideosKey, value: encoded);
      return true;
    } catch (e) {
      print('Error removing used video: $e');
      return false;
    }
  }
}
