import 'dart:async';
import 'dart:convert';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../api_services/upload_image_to_seaart_service.dart';
import '../model/video_model.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for SeaArtScarpProvider
class SeaArtScarpState {
  final bool isLoading;
  final String? videoUrl;
  final String? errorMessage;
  final int progress; // 0-100

  const SeaArtScarpState({
    this.isLoading = false,
    this.videoUrl,
    this.errorMessage,
    this.progress = 0,
  });

  SeaArtScarpState copyWith({
    bool? isLoading,
    String? videoUrl,
    String? errorMessage,
    int? progress,
  }) {
    return SeaArtScarpState(
      isLoading: isLoading ?? this.isLoading,
      videoUrl: videoUrl ?? this.videoUrl,
      errorMessage: errorMessage,
      progress: progress ?? this.progress,
    );
  }
}

/// ✅ Riverpod Notifier with Progress Tracking
class SeaArtScarpNotifier extends Notifier<SeaArtScarpState> {
  final TempUploadNotifier tempUploadNotifier = TempUploadNotifier();

  /// Common headers including your full cookie
  final Map<String, String> _headers = {
    'cookie': GlobalVariables.seaArtCookie,
    'Content-Type': 'application/json',
  };

  @override
  SeaArtScarpState build() => const SeaArtScarpState();

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  void _setVideoUrl(String? url) {
    state = state.copyWith(videoUrl: url);
  }

  void _setProgress(int progress) {
    state = state.copyWith(progress: progress);
  }

  /// ------------------ MAIN API CALLS WITH PROGRESS ------------------

  Future<void> generateVideoFromImageUsingPrompt({
    required String imagePath,
    required String prompt,
    required String modelNo,
    required String versionNo,
    Function(int)? onProgressUpdate,
  }) async {
    _setLoading(true);
    _setError(null);
    _setVideoUrl(null);
    _setProgress(0);

    try {
      // Step 1: Upload image (0% progress)
      onProgressUpdate?.call(0);

      final uploadNotifier = ref.read(uploadImageToSeaArtProvider.notifier);
      final imageUrl = await uploadNotifier.handleUpload(filePath: imagePath);

      showLog('image url is : $imageUrl');

      if (imageUrl == null) throw Exception("Failed to upload image");

      // Step 2: Create video task (still at 0% until we get taskId)
      final taskId = await createVideoTask(
        imageUrl: imageUrl,
        prompt: prompt,
        modelNo: modelNo,
        versionNo: versionNo,
      );
      if (taskId == null) throw Exception("Failed to create video task");

      showLog('task id is : $taskId');

      // Step 3: Poll task and update progress
      final videoUrl = await getVideoUrlByTaskId(
        taskId,
        onProgressUpdate: onProgressUpdate,
      );

      if (videoUrl == null) {
        throw Exception("Video generation failed or cancelled");
      }

      showLog('Video URL is : $videoUrl');
      _setVideoUrl(videoUrl);
      _setProgress(100);
      onProgressUpdate?.call(100);
    } catch (e) {
      _setError(e.toString());
      showLog("❌ generateVideoFromImage error: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateVideoFromApplyId({
    required String imagePath,
    required VideoModel videoModel,
    Function(int)? onProgressUpdate,
  }) async {
    _setLoading(true);
    _setError(null);
    _setVideoUrl(null);
    _setProgress(0);

    try {
      onProgressUpdate?.call(0);

      final taskId = await createVideoTaskForApplyId(
        imagePath: imagePath,
        videoModel: videoModel,
      );
      if (taskId == null) throw Exception("Failed to create task");

      final videoUrl = await getVideoUrlByTaskId(
        taskId,
        onProgressUpdate: onProgressUpdate,
      );

      if (videoUrl == null) throw Exception("Video generation failed");

      _setVideoUrl(videoUrl);
      _setProgress(100);
      onProgressUpdate?.call(100);
    } catch (e) {
      _setError(e.toString());
      showLog("❌ generateVideoFromApplyId error: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateVideoFromTemplate({
    required String imagePath,
    required String templateId,
    Function(int)? onProgressUpdate,
  }) async {
    _setLoading(true);
    _setError(null);
    _setVideoUrl(null);
    _setProgress(0);

    try {
      onProgressUpdate?.call(0);

      final uploadNotifier = ref.read(uploadImageToSeaArtProvider.notifier);
      final imageUrl = await uploadNotifier.handleUpload(filePath: imagePath);

      if (imageUrl == null) throw Exception("Failed to upload image");

      final taskId = await createVideoTaskForTemplateId(
        imageUrl: imageUrl,
        templateId: templateId,
      );
      showLog('Come with task ID :${taskId}');
      if (taskId == null) throw Exception("Failed to create task");
      showLog('Come with nothing');
      final videoUrl = await getVideoUrlByTaskId(
        taskId,
        onProgressUpdate: onProgressUpdate,
      );

      showLog('Task ID');

      if (videoUrl == null) throw Exception("Failed to generate video");

      _setVideoUrl(videoUrl);
      _setProgress(100);
      onProgressUpdate?.call(100);
    } catch (e) {
      _setError(e.toString());
      showLog("❌ generateVideoFromTemplate error: ${e.toString()}");
    } finally {
      _setLoading(false);
    }
  }

  /// ------------------ PRIVATE HELPERS ------------------

  Future<String?> createVideoTaskForTemplateId({
    required String imageUrl,
    required String templateId,
  }) async {
    const String url = 'https://www.seaart.ai/api/v1/task/v2/video/img-to-video';

    try {
      final Map<String, dynamic> body = {
        "meta": {
          "prompt": "",
          "generate_video": {
            "image_opts": [
              {"mode": "image", "url": imageUrl},
            ],
          },
          "generate": {
            "anime_enhance": 2,
            "mode": 0,
            "gen_mode": 0,
            "prompt_magic_mode": 2,
          },
          "task_from": "web",
        },
        "template_id": templateId,
        "model_no": "",
        "model_ver_no": "",
      };

      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        showLog('Response is $json');
        return json['data']?['id'];
      }
    } catch (e) {
      showLog("❌ createVideoTaskForTemplateId error: $e");
    }
    return null;
  }

  Future<String?> createVideoTaskForApplyId({
    required String imagePath,
    required VideoModel videoModel,
  }) async {
    const String applyUrl = 'https://www.seaart.ai/api/v1/creativity/generate/apply';

    try {
      final uploadNotifier = ref.read(uploadImageToSeaArtProvider.notifier);
      final imageUrl = await uploadNotifier.handleUpload(filePath: imagePath);

      if (imageUrl == null) return null;

      var inputs = videoModel.seaArtApplyInput;
      inputs[0]["val"] = imageUrl;

      final response = await http.post(
        Uri.parse(applyUrl),
        headers: _headers,
        body: jsonEncode({
          "apply_id": videoModel.seaArtApplyId,
          "inputs": inputs,
          "ss": 52,
        }),
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body['data']?['id'];
      }
    } catch (e) {
      showLog("❌ getApplyTaskId error: $e");
    }
    return null;
  }

  Future<String?> createVideoTask({
    required String imageUrl,
    required String prompt,
    required String modelNo,
    required String versionNo,
  }) async {
    try {
      final uri = Uri.parse('https://www.seaart.ai/api/v1/task/v2/video/img-to-video');

      final Map<String, dynamic> body = {
        "model_no": modelNo,
        "model_ver_no": versionNo,
        "meta": {
          "prompt": prompt,
          "generate_video": {
            "relevance": 0.5,
            "camera_control_option": {"mode": "Camera Movement", "offset": 0},
            "generate_video_duration": 5,
            "image_opts": [
              {"mode": "first_frame", "url": imageUrl},
            ],
            "quality_mode": "360p",
            "motion_mode": "normal",
            "style": "",
          },
          "width": 704,
          "height": 1248,
          "lora_models": [],
          "aspect_ratio": "9:16",
          "generate": {
            "anime_enhance": 2,
            "mode": 0,
            "gen_mode": 0,
            "prompt_magic_mode": 2,
          },
          "negative_prompt": "",
          "n_iter": 1,
        },
        "ss": 52,
      };

      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      showLog('There is response : ${response.statusCode}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        showLog('Response is : $json');
        return json['data']?['id'];
      }
    } catch (e) {
      showLog("❌ createVideoTask error: $e");
    }
    return null;
  }

  Future<String?> getVideoUrlByTaskId(
      String taskId, {
        Function(int)? onProgressUpdate,
      }) async {
    const String url = 'https://www.seaart.ai/api/v1/task/batch-progress';
    showLog('Starting polling for task: $taskId');

    try {
      while (true) {
        final response = await http.post(
          Uri.parse(url),
          headers: _headers,
          body: jsonEncode({
            "task_ids": [taskId],
            "ss": 52,
          }),
        );

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          showLog('Polling response: ${json['data']}');

          final items = json['data']?['items'];
          if (items != null && items.isNotEmpty) {
            final item = items[0];
            final statusDesc = item['status_desc'];

            // 🔥 Extract progress from response
            final int progress = item['process'] ?? 0;
            showLog('📊 Current progress: $progress%');

            _setProgress(progress);
            onProgressUpdate?.call(progress);

            if (statusDesc == 'finish') {
              final uris = item['img_uris'];
              _setProgress(100);
              onProgressUpdate?.call(100);
              return uris != null && uris.isNotEmpty ? uris[0]['url'] : null;
            } else if (statusDesc == 'waiting' || statusDesc == 'processing') {
              await Future.delayed(const Duration(seconds: 10));
              continue;
            } else {
              showLog("❌ Task failed or cancelled: $statusDesc");
              return null;
            }
          }
        }

        await Future.delayed(const Duration(seconds: 10));
      }
    } catch (e) {
      showLog("❌ getVideoUrlByTaskId error: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> pollTaskOnce(String taskId) async {
    const String url = 'https://www.seaart.ai/api/v1/task/batch-progress';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: _headers,
        body: jsonEncode({
          "task_ids": [taskId],
          "ss": 52,
        }),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final items = json['data']?['items'];

        if (items != null && items.isNotEmpty) {
          final item = items[0];
          final statusDesc = item['status_desc'];
          final int progress = item['process'] ?? 0;

          if (statusDesc == 'finish') {
            final uris = item['img_uris'];
            final videoUrl = uris != null && uris.isNotEmpty ? uris[0]['url'] : null;

            return {
              'progress': 100,
              'status': 'completed',
              'videoUrl': videoUrl,
            };
          } else if (statusDesc == 'waiting' || statusDesc == 'processing') {
            return {
              'progress': progress,
              'status': 'processing',
              'videoUrl': null,
            };
          } else {
            // Failed or cancelled
            return {
              'progress': progress,
              'status': 'failed',
              'videoUrl': null,
            };
          }
        }
      }
    } catch (e) {
      showLog("❌ _pollTaskOnce error: $e");
    }

    return null;
  }


}

final seaArtScarpProvider = NotifierProvider<SeaArtScarpNotifier, SeaArtScarpState>(
      () => SeaArtScarpNotifier(),
);