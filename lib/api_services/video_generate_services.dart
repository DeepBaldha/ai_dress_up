import 'dart:async';
import 'package:ai_dress_up/api_services/pollo_ai_scrap_service.dart';
import 'package:ai_dress_up/api_services/pollo_api_services.dart';
import 'package:ai_dress_up/api_services/sea_art_scrap_services.dart';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:ai_dress_up/api_services/vidu_api_services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/video_model.dart';
import '../utils/utils.dart';
import 'face_swap_services.dart';
import 'kling_302_api_services.dart';

/// Immutable state for VideoGeneratorProvider
/// Holds top-level video generation workflow state
class VideoGeneratorState {
  final bool isLoading;
  final String? videoUrl;
  final String? error;
  final String status;

  const VideoGeneratorState({
    this.isLoading = false,
    this.videoUrl,
    this.error,
    this.status = "",
  });

  VideoGeneratorState copyWith({
    bool? isLoading,
    String? videoUrl,
    String? error,
    String? status,
  }) {
    return VideoGeneratorState(
      isLoading: isLoading ?? this.isLoading,
      videoUrl: videoUrl ?? this.videoUrl,
      error: error,
      status: status ?? this.status,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier
class VideoGeneratorNotifier extends Notifier<VideoGeneratorState> {
  // Providers (dependencies)
  late final PolloApiNotifier _polloApi;
  late final PolloAiScrapNotifier _polloAiScrapService;
  late final Kling302ApiNotifier _kling302apiService;
  late final ViduApiNotifier _viduApiService;
  late final SeaArtScarpNotifier _seaArtScrapeProvider;
  late final TempUploadNotifier _tempUploadProvider;
  late final FaceSwapNotifier _faceSwapProvider;

  @override
  VideoGeneratorState build() {
    // Inject dependencies from the global provider graph
    _polloApi = ref.read(polloApiProvider.notifier);
    _polloAiScrapService = ref.read(polloAiScrapProvider.notifier);
    _kling302apiService = ref.read(kling302ApiProvider.notifier);
    _viduApiService = ref.read(viduApiProvider.notifier);
    _seaArtScrapeProvider = ref.read(seaArtScarpProvider.notifier);
    _tempUploadProvider = ref.read(tempUploadProvider.notifier);
    _faceSwapProvider = ref.read(faceSwapProvider.notifier);
    return const VideoGeneratorState();
  }

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setVideoUrl(String? url) {
    state = state.copyWith(videoUrl: url);
  }

  void _setError(String? err) {
    state = state.copyWith(error: err);
  }

  void _setStatus(String message) {
    showLog(message);
    state = state.copyWith(status: message);
  }

  String? _handleResult(String? url, String source) {
    if (url != null) {
      if (kDebugMode) showLog("✅ [$source] Video generated: $url");
      return url;
    } else {
      if (kDebugMode) showLog("❌ [$source] Failed to generate video.");
      return null;
    }
  }

  /// Generates video using multiple backends (Pollo, SeaArt, Kling, Vidu, etc.)
  /// Returns video URL if success, `null` if failed
  Future<void> generateVideoCall({
    required VideoModel videoModel,
    required String inputImagePath,
    required String userImagePath,
    required String prompt,
    List input = const [],
  }) async {
    _setLoading(true);
    _setVideoUrl(null);
    _setError(null);
    _setStatus("Preparing video generation...");

    try {
      String image = "";
      // if (videoModel.faceSwapInputImage) {
      //   _setStatus("Swapping faces...");
      //   await _faceSwapProvider.swapFaceSmart(
      //     sourceImg: userImagePath,
      //     targetImg: inputImagePath,
      //   );
      //   image = _faceSwapProvider.state.resultPath ?? '';
      //   if (image.isEmpty) {
      //     showLog("Failed to swap face");
      //     showToast("Something went wrong, please try again later");
      //     _setLoading(false);
      //     return;
      //   }
      // } else {
      //   image = userImagePath;
      // }

      if (!image.contains("http")) {
        _setStatus("Uploading image to temp...");
        await _tempUploadProvider.uploadFileToTemp(image);
        image = _tempUploadProvider.state.uploadedUrl ?? "";
      }

      if (image.isEmpty) {
        showLog("Failed to upload in temp");
        showToast("Something went wrong, please try again later");
        _setLoading(false);
        return;
      }

      // You can adjust this default for testing
      videoModel.apiType = "seaart_scrap_tempid";
      videoModel.seaArtTemplateId = "d103ghde878c73dctog0";

      String? result;

      switch (videoModel.apiType) {
        case "pollo_api":
          try {
            if (kDebugMode) {
              showLog(
                "🚀 [VideoGeneratorService] Starting Pollo video generation...",
              );
            }
            await _polloApi.makePolloAiApiCall(fileUrl: image, prompt: prompt);
            result = _handleResult(
              _polloApi.state.videoUrl,
              "VideoGeneratorService/pollo_api",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService pollo_api] Error: $e");
          }
          break;

        case "pollo_scrap":
          try {
            showLog(
              "🚀 [VideoGeneratorService] Starting Pollo Scrap generation...",
            );
            await _polloAiScrapService.uploadAndGetResultUsingPollScrap(
              filePath: image,
              templateId: videoModel.poloTemplateId,
            );
            result = _handleResult(
              _polloAiScrapService.state.videoUrl,
              "VideoGeneratorService/pollo_scrap",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService pollo_scrap] Error: $e");
          }
          break;

        case "seaart_scrap_prompt":
          try {
            showLog(
              "🚀 [VideoGeneratorService] Starting Sea Art Scrap generation...",
            );
            await _seaArtScrapeProvider.generateVideoFromImageUsingPrompt(
              imagePath: image,
              prompt: videoModel.prompt,
              modelNo: videoModel.seaArtModelNo,
              versionNo: videoModel.seaArtVersionNo,
            );
            result = _handleResult(
              _seaArtScrapeProvider.state.videoUrl,
              "VideoGeneratorService/seaart_scrap_prompt",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService seaart_scrap_prompt] Error: $e");
          }
          break;

        case "seaart_scrap_tempid":
          try {
            showLog(
              "🚀 [VideoGeneratorService] Starting Sea Art Scrap generation...",
            );
            await _seaArtScrapeProvider.generateVideoFromTemplate(
              imagePath: image,
              templateId: videoModel.seaArtTemplateId,
            );
            result = _handleResult(
              _seaArtScrapeProvider.state.videoUrl,
              "VideoGeneratorService/seaart_scrap_tempid",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService seaart_scrap_tempid] Error: $e");
          }
          break;

        case "seaart_scrap_apply":
          try {
            showLog(
              "🚀 [VideoGeneratorService] Starting Sea Art Scrap generation...",
            );
            await _seaArtScrapeProvider.generateVideoFromApplyId(
              imagePath: image,
              videoModel: videoModel,
            );
            result = _handleResult(
              _seaArtScrapeProvider.state.videoUrl,
              "VideoGeneratorService/seaart_scrap_apply",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService seaart_scrap_apply] Error: $e");
          }
          break;

        case "302_kling":
          try {
            showLog(
              "🚀 [VideoGeneratorService] Starting Kling video generation...",
            );
            await _kling302apiService.makeKling302ApiCall(
              selectedImage: image,
              prompt: videoModel.prompt,
            );
            result = _handleResult(
              _kling302apiService.state.videoUrl,
              "VideoGeneratorService/302_kling",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService 302_kling] Error: $e");
          }
          break;

        case "vidu":
          try {
            showLog(
              "🚀 [VideoGeneratorService] Starting Vidu video generation...",
            );
            await _viduApiService.generateVideoFromImage(
              selectedImage: image,
              prompt: videoModel.prompt,
            );
            result = _handleResult(
              _viduApiService.state.videoUrl,
              "VideoGeneratorService/vidu",
            );
          } catch (e) {
            showLog("❌ [VideoGeneratorService vidu] Error: $e");
          }
          break;

        default:
          showLog(
            "❌ [VideoGeneratorService] Unknown apiType: ${videoModel.apiType}",
          );
          showToast("Unknown video generation type");
          break;
      }

      if (result != null) {
        _setStatus("✅ Video generation completed!");
        _setVideoUrl(result);
      } else {
        _setStatus("❌ Video generation failed.");
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}

/// ✅ Riverpod provider declaration
final videoGeneratorProvider =
    NotifierProvider<VideoGeneratorNotifier, VideoGeneratorState>(
      () => VideoGeneratorNotifier(),
    );
