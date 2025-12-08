import 'dart:convert';
import 'dart:async';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for ViduApiProvider
/// Holds all reactive values like isLoading, status, error, videoUrl, etc.
class ViduApiState {
  final bool isLoading;
  final bool isChecking;
  final String status;
  final String? error;
  final String? videoUrl;

  const ViduApiState({
    this.isLoading = false,
    this.isChecking = false,
    this.status = "",
    this.error,
    this.videoUrl,
  });

  ViduApiState copyWith({
    bool? isLoading,
    bool? isChecking,
    String? status,
    String? error,
    String? videoUrl,
  }) {
    return ViduApiState(
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      status: status ?? this.status,
      error: error,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier
class ViduApiNotifier extends Notifier<ViduApiState> {
  final TempUploadNotifier tempUploadNotifier = TempUploadNotifier();

  static const String _baseUrl = 'https://api.vidu.com/ent/v2';
  static const Duration _pollingDelay = Duration(seconds: 10);

  @override
  ViduApiState build() => const ViduApiState();

  // ✅ Helper methods to update immutable state
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

  void _setError(String message) {
    showLog("❌ $message");
    state = state.copyWith(error: message);
  }

  void _setVideoUrl(String? url) {
    state = state.copyWith(videoUrl: url);
  }

  /// Generates video task in Vidu
  /// Returns the final video URL if successful, or `null` if failed.
  Future<void> generateVideoFromImage({
    required String selectedImage,
    required String prompt,
  }) async {
    _setLoading(true);
    _setError("");
    _setVideoUrl(null);
    _setStatus("🚀 Starting Vidu video generation...");

    try {
      String imageUrl = "";
      if (selectedImage.contains("http")) {
        imageUrl = selectedImage;
      } else {
        _setStatus("📤 Uploading image to temporary server...");
        await tempUploadNotifier.uploadFileToTemp(selectedImage);
        imageUrl = tempUploadNotifier.state.uploadedUrl ?? "";
      }

      if (imageUrl.isEmpty) {
        _setError("❌ Image upload failed");
        _setLoading(false);
        return;
      }

      final headers = {
        "Authorization": "Token ${GlobalVariables.viduApiKey}",
        "Content-Type": "application/json",
      };

      final body = jsonEncode({
        "model": "vidu2.0",
        "images": [imageUrl],
        "prompt": prompt,
        "duration": "4",
        "seed": "0",
        "resolution": "720p",
        "movement_amplitude": "auto",
      });

      final response = await http.post(
        Uri.parse("$_baseUrl/img2video"),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        showLog("✅ Vidu task creation response: $responseBody");

        if (responseBody['state'] == 'created') {
          final taskId = responseBody['task_id'];
          Fluttertoast.showToast(
            msg:
            "You can explore other videos while we process your task in the background.",
          );
          showLog("📨 Vidu Task ID: $taskId");

          _setChecking(true);
          _setStatus("⏳ Task created, waiting for completion...");
          final url = await _pollViduStatus(taskId);

          if (url != null) {
            _setVideoUrl(url);
            _setStatus("✅ Vidu video generated successfully!");
          } else {
            _setError("❌ Vidu generation failed or timed out.");
          }
        } else {
          _setError("❌ Vidu task creation failed: invalid state");
        }
      } else {
        _setError("❌ Vidu API error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      _setError("Vidu generation exception: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  /// Polls Vidu task status until success or failure
  Future<String?> _pollViduStatus(String taskId) async {
    if (!state.isChecking) return null;

    try {
      final headers = {
        "Authorization": "Token ${GlobalVariables.viduApiKey}",
        "Content-Type": "application/json",
      };

      final response = await http.get(
        Uri.parse("$_baseUrl/tasks/$taskId/creations"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final status = body['state'].toString();

        if (status == "success") {
          final url = body['creations'][0]['url'];
          showLog("✅ Vidu Video URL: $url");
          _setChecking(false);
          return url;
        } else if (status == "failed") {
          showLog("❌ Vidu task failed.");
          _setChecking(false);
          return null;
        } else {
          _setStatus("⏳ Still processing... Current state: $status");
          await Future.delayed(_pollingDelay);
          return await _pollViduStatus(taskId);
        }
      } else {
        _setError(
            "❌ Polling error: ${response.statusCode} ${response.reasonPhrase}");
        _setChecking(false);
        return null;
      }
    } catch (e) {
      _setError("Polling exception: ${e.toString()}");
      _setChecking(false);
      return null;
    }
  }
}

/// ✅ Riverpod provider declaration
final viduApiProvider =
NotifierProvider<ViduApiNotifier, ViduApiState>(() => ViduApiNotifier());
