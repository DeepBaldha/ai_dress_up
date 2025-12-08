import 'dart:async';
import 'dart:convert';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for PolloApiProvider
/// Holds all reactive variables for the Pollo API task
class PolloApiState {
  final bool isLoading;
  final bool isChecking;
  final String status;
  final String? error;
  final String? videoUrl;

  const PolloApiState({
    this.isLoading = false,
    this.isChecking = false,
    this.status = "",
    this.error,
    this.videoUrl,
  });

  PolloApiState copyWith({
    bool? isLoading,
    bool? isChecking,
    String? status,
    String? error,
    String? videoUrl,
  }) {
    return PolloApiState(
      isLoading: isLoading ?? this.isLoading,
      isChecking: isChecking ?? this.isChecking,
      status: status ?? this.status,
      error: error,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier
class PolloApiNotifier extends Notifier<PolloApiState> {
  // ❌ REMOVED: final TempUploadNotifier tempUploadNotifier = TempUploadNotifier();
  // ✅ We'll use ref.read() to access it properly instead

  final String _polloApiUrl =
      'https://pollo.ai/api/platform/generation/pollo/pollo-v1-6';
  final String _statusUrl =
      'https://pollo.ai/api/platform/generation'; // will append /{id}/status

  String polloApiKey = GlobalVariables.polloApiKey;
  static const Duration _pollingDelay = Duration(seconds: 10);

  @override
  PolloApiState build() => const PolloApiState();

  // ✅ Helper setters to update immutable state
  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setChecking(bool value) {
    state = state.copyWith(isChecking: value);
  }

  void _setStatus(String message) {
    showLog('status is : $message');
    state = state.copyWith(status: message);
  }

  void _setError(String? message) {
    showLog('Error is : ❌ $message');
    state = state.copyWith(error: message);
  }

  void _setVideoUrl(String? url) {
    state = state.copyWith(videoUrl: url);
  }

  /// Main entry point for calling Pollo AI API.
  /// Returns the final video URL if success, or `null` if failed.
  Future<void> makePolloAiApiCall({
    required String fileUrl,
    required String prompt,
  }) async {
    _setLoading(true);
    _setError(null);
    _setVideoUrl(null);
    _setStatus("🚀 Starting Pollo API generation...");

    try {
      String imageUrl = "";
      if (fileUrl.contains("http")) {
        imageUrl = fileUrl;
      } else {
        _setStatus("📤 Uploading image to temporary server...");

        // ✅ FIX: Use ref.read() to access the provider properly
        final tempUploadNotifier = ref.read(tempUploadProvider.notifier);
        await tempUploadNotifier.uploadFileToTemp(fileUrl);

        // ✅ Read the state from the provider
        final tempUploadState = ref.read(tempUploadProvider);
        imageUrl = tempUploadState.uploadedUrl ?? "";
      }

      if (imageUrl.isEmpty) {
        _setError("❌ Image upload failed");
        _setLoading(false);
        return;
      }

      final response = await http.post(
        Uri.parse(_polloApiUrl),
        headers: {'x-api-key': polloApiKey, 'Content-Type': 'application/json'},
        body: jsonEncode({
          "input": {"prompt": prompt, "image": imageUrl},
        }),
      );

      if (response.statusCode != 200) {
        showLog("API call failed: ${response.statusCode} ${response.body}");
        showLog(
          "Input Body: ${jsonEncode({
            "input": {"prompt": prompt, "image": imageUrl},
          })}",
        );
        _setError("❌ API call failed: ${response.statusCode}");
        _setLoading(false);
        return;
      }

      final body = jsonDecode(response.body);
      final data = body['data'];
      final id = data['taskId'];
      final status = data['status'];

      if (status == 'failed' || id == null) {
        _setError("❌ Task failed or ID missing");
        _setLoading(false);
        return;
      }

      _setStatus("⏳ Task created, polling for completion...");
      _setChecking(true);
      final url = await _checkPolloStatusRecursively(id);

      if (url != null) {
        _setVideoUrl(url);
        _setStatus("✅ Pollo video generated successfully!");
      } else {
        _setError("❌ Pollo video generation failed or timed out.");
      }
    } catch (e) {
      _setError("makePolloAiApiCall error: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  /// Recursive polling to check status until success or failure.
  Future<String?> _checkPolloStatusRecursively(String id) async {
    if (!state.isChecking) return null;

    try {
      final response = await http.get(
        Uri.parse("$_statusUrl/$id/status"),
        headers: {'x-api-key': polloApiKey},
      );

      if (response.statusCode != 200) {
        showLog("Status check failed: ${response.statusCode}");
        _setChecking(false);
        return null;
      }

      final body = jsonDecode(response.body);
      final data = body['data'];

      showLog('Response from pollo is :$data');

      if (data != null && data.containsKey('generations')) {
        final gen = data['generations'][0];
        final status = gen['status'];

        if (status == 'succeed') {
          final url = gen['url'];
          _setChecking(false);
          showLog("✅ Pollo result URL: $url");
          _setVideoUrl(url);
          return url;
        } else if (status == 'failed') {
          showLog("❌ Pollo generation failed.");
          _setChecking(false);
          _setError("❌ Pollo generation failed.");
          return null;
        } else {
          _setStatus("⏳ Current status: $status. Waiting...");
        }
      }

      // Wait and poll again
      await Future.delayed(_pollingDelay);
      return await _checkPolloStatusRecursively(id);
    } catch (e) {
      showLog("Polling error: ${e.toString()}");
      _setChecking(false);
      _setError("Polling error: ${e.toString()}");
      return null;
    }
  }
}

/// ✅ Riverpod provider declaration
final polloApiProvider = NotifierProvider<PolloApiNotifier, PolloApiState>(
      () => PolloApiNotifier(),
);