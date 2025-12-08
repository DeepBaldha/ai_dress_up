import 'dart:async';
import 'dart:convert';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for Kling302ApiProvider
/// Holds all reactive values like isLoading, videoUrl, error, etc.
class Kling302ApiState {
  final bool isLoading;
  final bool isChecking;
  final String? videoUrl;
  final String? error;
  final String status;

  const Kling302ApiState({
    this.isLoading = false,
    this.isChecking = false,
    this.videoUrl,
    this.error,
    this.status = "",
  });

  Kling302ApiState copyWith({
    bool? isLoading,
    bool? isChecking,
    String? videoUrl,
    String? error,
    String? status,
  }) {
    return Kling302ApiState(
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      videoUrl: videoUrl ?? this.videoUrl,
      error: error,
      status: status ?? this.status,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier
class Kling302ApiNotifier extends Notifier<Kling302ApiState> {
  final TempUploadNotifier tempUploadNotifier = TempUploadNotifier();

  static const String _baseUrl = 'https://api.302.ai/klingai';
  static const Duration _pollingDelay = Duration(seconds: 20);

  @override
  Kling302ApiState build() => const Kling302ApiState();

  // ✅ Helper methods to update state
  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setChecking(bool value) {
    state = state.copyWith(isChecking: value);
  }

  void _setStatus(String message) {
    showLog(message);
    state = state.copyWith(status: message);
  }

  void _setError(String? message) {
    showLog("❌ $message");
    state = state.copyWith(error: message);
  }

  void _setVideoUrl(String? url) {
    state = state.copyWith(videoUrl: url);
  }

  /// Main API call to Kling (image to 5s video).
  /// Returns the video URL if successful, or `null` if failed.
  Future<void> makeKling302ApiCall({
    required String selectedImage,
    required String prompt,
  }) async {
    _setLoading(true);
    _setError(null);
    _setVideoUrl(null);
    _setStatus(
      "<================ makeKling302ApiCall CALLED ================>",
    );

    try {
      final headers = {'Authorization': 'Bearer ${GlobalVariables.api302Key}'};

      String imageUrl = "";
      if (selectedImage.contains("http")) {
        imageUrl = selectedImage;
      } else {
        _setStatus("📤 Uploading image to temp...");
        await tempUploadNotifier.uploadFileToTemp(selectedImage);
        imageUrl = tempUploadNotifier.state.uploadedUrl ?? "";
      }

      if (imageUrl.isEmpty) {
        _setError("❌ ERROR IN TEMP UPLOAD");
        _setLoading(false);
        return;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_baseUrl/m2v_16_img2video_5s'),
      );

      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath('input_image', selectedImage),
      );
      request.fields.addAll({
        'prompt': prompt,
        'negative_prompt': '',
        'aspect_ratio': '1:1',
      });

      final response = await request.send();
      final responseBody = jsonDecode(await response.stream.bytesToString());

      if (response.statusCode == 200) {
        final taskId = responseBody['data']['task']['id'];
        Fluttertoast.showToast(
          msg:
              "You can explore other videos while we process your task in the background.",
        );
        showLog("🎬 Kling Task ID: $taskId");
        _setChecking(true);
        _setStatus("🕒 Task submitted successfully, waiting for video...");
        final url = await _pollKlingStatus(taskId);

        if (url != null) {
          _setVideoUrl(url);
          _setStatus("✅ Kling video generated successfully!");
        } else {
          _setError("❌ Kling video generation failed.");
        }
      } else {
        _setError("❌ API Error: ${response.reasonPhrase}");
        showLog(responseBody.toString());
      }
    } catch (e) {
      _setError("makeKling302ApiCall error: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  /// Recursive polling for Kling task status.
  Future<String?> _pollKlingStatus(String taskId) async {
    if (!state.isChecking) return null;

    try {
      final headers = {'Authorization': 'Bearer ${GlobalVariables.api302Key}'};
      final response = await http.get(
        Uri.parse('$_baseUrl/task/$taskId/fetch?geo=global'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final status = body['data']['status'].toString();

        if (status == "99") {
          final url = body['data']['works'][0]['resource']['resource'];
          showLog("✅ Kling Video URL: $url");
          _setChecking(false);
          return url;
        } else if (status == "50") {
          showLog("❌ Kling Task Failed");
          _setChecking(false);
          return null;
        } else {
          _setStatus("⏳ Processing... Status Code: $status");
          await Future.delayed(_pollingDelay);
          return await _pollKlingStatus(taskId);
        }
      } else {
        showLog("❌ Polling Error: ${response.reasonPhrase}");
        _setChecking(false);
        return null;
      }
    } catch (e) {
      showLog("Polling exception: ${e.toString()}");
      _setChecking(false);
      return null;
    }
  }
}

/// ✅ Riverpod provider declaration
final kling302ApiProvider =
    NotifierProvider<Kling302ApiNotifier, Kling302ApiState>(
      () => Kling302ApiNotifier(),
    );
