import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/global_variables.dart';
import '../utils/utils.dart';

// State class to hold the result
class DezgoProcessState {
  final String? processedImagePath;
  final bool isLoading;
  final String? error;

  DezgoProcessState({
    this.processedImagePath,
    this.isLoading = false,
    this.error,
  });

  DezgoProcessState copyWith({
    String? processedImagePath,
    bool? isLoading,
    String? error,
  }) {
    return DezgoProcessState(
      processedImagePath: processedImagePath ?? this.processedImagePath,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Provider for the service
final dezgoServiceProvider = Provider((ref) => DezgoService());

// State notifier provider
final dezgoProcessProvider =
    StateNotifierProvider<DezgoProcessNotifier, DezgoProcessState>(
      (ref) => DezgoProcessNotifier(ref.read(dezgoServiceProvider)),
    );

class DezgoProcessNotifier extends StateNotifier<DezgoProcessState> {
  final DezgoService _service;

  DezgoProcessNotifier(this._service) : super(DezgoProcessState());

  Future<String?> processImage({
    required String imagePath,
    required String prompt,
    double strength = 0.8,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      showLog('call3');
      final processedImagePath = await _service.image2Image(
        imagePath: imagePath,
        prompt: prompt,
        strength: strength,
      );


      showLog('call4');
      state = state.copyWith(
        processedImagePath: processedImagePath,
        isLoading: false,
      );

      return processedImagePath;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void reset() {
    state = DezgoProcessState();
  }
}

class DezgoService {
  final Dio _dio = Dio();
  static final String _apiKey = GlobalVariables.dezgoAPIKey;
  static const String _baseUrl = 'https://api.dezgo.com';

  Future<String> image2Image({
    required String imagePath,
    required String prompt,
    double strength = 0.8,
  }) async {
    try {

      showLog('call5');
      final formData = FormData.fromMap({
        'init_image': [
          await MultipartFile.fromFile(
            imagePath,
            filename: imagePath.split('/').last,
          ),
        ],
        'prompt': prompt,
        'strength': strength.toString(),
      });


      showLog('call6');

      final response = await _dio.post(
        '$_baseUrl/image2image',
        data: formData,
        options: Options(
          headers: {'X-Dezgo-Key': _apiKey},
          responseType: ResponseType.bytes,
        ),
      );

      showLog('REsponse is :${response.statusCode} and body is ${response.data}');

      if (response.statusCode == 200) {
        final savedPath = await _saveImageToLocal(response.data);
        return savedPath;
      } else {
        throw Exception('API request failed: ${response.statusMessage}');
      }
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to process image: $e');
    }
  }

  Future<String> _saveImageToLocal(List<int> imageBytes) async {
    try {
      final directory = await getTemporaryDirectory();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/processed_image_$timestamp.png';

      final file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      throw Exception('Failed to save image: $e');
    }
  }
}
