import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/image_result_model.dart';

final imageResultProvider = ChangeNotifierProvider<ImageResultNotifier>((ref) {
  return ImageResultNotifier();
});

class ImageResultNotifier extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  static const String _storageKey = 'generated_images';

  List<ImageResultModel> _images = [];

  List<ImageResultModel> get images => _images;
  int get imageCount => _images.length;
  bool get isEmpty => _images.isEmpty;

  /// Load images from Secure Storage
  Future<void> loadImages() async {
    try {
      final imagesJson = await _secureStorage.read(key: _storageKey);
      if (imagesJson != null) {
        final List<dynamic> decoded = jsonDecode(imagesJson);
        _images =
            decoded.map((json) => ImageResultModel.fromJson(json)).toList();
        _images.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading images (secure): $e');
    }
  }

  /// Save a new image (imagePath can be URL or local path)
  Future<void> saveImage({
    required String imagePath,
    required String title,
  }) async {
    try {
      final newImage = ImageResultModel(
        imagePath: imagePath,
        title: title,
        createdAt: DateTime.now(),
      );

      _images.insert(0, newImage);
      await _persistImages();
      notifyListeners();
    } catch (e) {
      debugPrint('Error saving image (secure): $e');
    }
  }

  /// Delete a specific image
  Future<void> deleteImage(int index) async {
    try {
      if (index >= 0 && index < _images.length) {
        _images.removeAt(index);
        await _persistImages();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error deleting image (secure): $e');
    }
  }

  /// Clear all images
  Future<void> clearAll() async {
    try {
      _images.clear();
      await _secureStorage.delete(key: _storageKey);
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing images (secure): $e');
    }
  }

  /// Persist images securely
  Future<void> _persistImages() async {
    try {
      final List<Map<String, dynamic>> jsonList =
      _images.map((img) => img.toJson()).toList();
      await _secureStorage.write(
        key: _storageKey,
        value: jsonEncode(jsonList),
      );
    } catch (e) {
      debugPrint('Error persisting images (secure): $e');
    }
  }
}
