import 'dart:convert';
import 'dart:io';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for FaceSwapProvider
class FaceSwapState {
  final bool isLoading;
  final String status;
  final String? resultPath;
  final String? error;

  const FaceSwapState({
    this.isLoading = false,
    this.status = "",
    this.resultPath,
    this.error,
  });

  FaceSwapState copyWith({
    bool? isLoading,
    String? status,
    String? resultPath,
    String? error,
  }) {
    return FaceSwapState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      resultPath: resultPath ?? this.resultPath,
      error: error,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier
class FaceSwapNotifier extends Notifier<FaceSwapState> {
  final TempUploadNotifier tempUploadNotifier = TempUploadNotifier();

  static const modeFaceRegular = "faceRegular";
  static const modeFaceSegmind = "faceSegmind";
  static const modeFaceFast = "faceFast";
  static const modeFaceSwapperAi = "faceSwapperAi";

  static String defaultMode = GlobalVariables.defaultFaceSwapApiToUse;
  static String fastFaceSwapKey = GlobalVariables.fastFaceSwapKey;
  static String faceSwapSegmindKey = GlobalVariables.faceSwapSegmindKey;
  static String faceSwapperToken = GlobalVariables.faceSwapperToken;

  @override
  FaceSwapState build() => const FaceSwapState();

  // ✅ Private state update helpers
  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setStatus(String message) {
    showLog(message);
    state = state.copyWith(status: message);
  }

  void _setError(String? message) {
    showLog("❌ $message");
    state = state.copyWith(error: message);
  }

  void _setResult(String? path) {
    state = state.copyWith(resultPath: path);
  }

  /// ✅ Wraps your existing swapFaceSmart logic with provider updates
  Future<void> swapFaceSmart({
    required String sourceImg,
    required String targetImg,
  }) async {
    _setLoading(true);
    _setError(null);
    _setResult(null);
    _setStatus("🔄 Starting smart face swap...");

    List<String> fallbacks = [
      defaultMode,
      modeFaceSegmind,
      modeFaceFast,
      modeFaceSwapperAi,
    ];

    try {
      for (String mode in fallbacks.toSet().toList()) {
        if (kDebugMode) showLog("🔄 Trying face swap using mode: $mode");
        _setStatus("Trying mode: $mode");

        try {
          String? path;
          switch (mode) {
            case modeFaceRegular:
              path = await _callFaceRegular(
                sourceImg,
                targetImg,
                tempUploadNotifier,
              );
              break;
            case modeFaceSegmind:
              path = await _callSegmind(sourceImg, targetImg);
              break;
            case modeFaceFast:
              path = await _callFastFaceSwap(
                targetImg,
                sourceImg,
                tempUploadNotifier,
              );
              break;
            case modeFaceSwapperAi:
              path = await _callFaceSwapperAi(sourceImg, targetImg);
              break;
          }
          if (path != null) {
            _setStatus("✅ Success using $mode");
            _setResult(path);
            _setLoading(false);
            return;
          } else {
            _setStatus("⚠️ Failed to get image using $mode");
          }
        } catch (e) {
          if (kDebugMode) showLog("❌ Error during $mode: $e");
        }
      }
      _setStatus("❌ All face swap attempts failed.");
      _setError("All face swap attempts failed.");
    } catch (e) {
      _setError("Error in face swap: $e");
    } finally {
      _setLoading(false);
    }
  }


  static Future<String?> _callFaceSwapperAi(
    String sourceImg,
    String targetImg,
  ) async {
    if (kDebugMode) {
      showLog("🟡 [faceSwapperAi] Starting FaceSwapper.ai API call");
    }

    try {
      String sourceBase64 = await _getBase64FromImageUrl(sourceImg);
      String targetBase64 = await _getBase64FromImageUrl(targetImg);

      var headers = {'Content-Type': 'application/json'};

      var body = json.encode({
        "target": targetBase64,
        "source": sourceBase64,
        "security": {
          "token": faceSwapperToken,
          "type": "invisible",
          "id": "faceswapper",
        },
      });

      var request = http.Request(
        'POST',
        Uri.parse('https://api.faceswapper.ai/swap'),
      );
      request.headers.addAll(headers);
      request.body = body;

      http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        var jsonResponse = json.decode(responseBody);

        if (jsonResponse['result'] != null) {
          String base64Image = jsonResponse['result'];

          final bytes = base64Decode(base64Image);
          final directory = await getApplicationDocumentsDirectory();
          final filePath =
              '${directory.path}/face_swapper_ai_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File(filePath);
          await file.writeAsBytes(bytes);

          if (kDebugMode) showLog("✅ [faceSwapperAi] Image saved at $filePath");
          return filePath;
        } else {
          if (kDebugMode) {
            showLog("❌ [faceSwapperAi] No result field in response.");
          }
        }
      } else {
        if (kDebugMode) {
          showLog("❌ [faceSwapperAi] HTTP error: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (kDebugMode) showLog("❌ [faceSwapperAi] Exception: $e");
    }

    return null;
  }

  static Future<String?> _callFaceRegular(
    String sourceImg,
    String targetImg,
    TempUploadNotifier tempUploadProvider,
  ) async {
    if (kDebugMode) showLog("🟡 [faceRegular] Starting regular API call");

    String source = sourceImg;
    String target = targetImg;

    if (!sourceImg.startsWith("http")) {
      if (kDebugMode) showLog("📤 Uploading source image to temp server...");
      await tempUploadProvider.uploadFileToTemp(sourceImg);
      source = tempUploadProvider.state.uploadedUrl ?? "";
      if (source.isEmpty) {
        if (kDebugMode) showLog("❌ Failed to upload source image.");
        return null;
      }
    }

    if (!targetImg.startsWith("http")) {
      if (kDebugMode) showLog("📤 Uploading target image to temp server...");
      await tempUploadProvider.uploadFileToTemp(targetImg);
      target = tempUploadProvider.state.uploadedUrl ?? "";
      if (target.isEmpty) {
        if (kDebugMode) showLog("❌ Failed to upload target image.");
        return null;
      }
    }

    var headers = {
      'Content-Type': 'application/json',
      'X-Rapidapi-Key': fastFaceSwapKey,
      'X-Rapidapi-Host': 'faceswap-image-transformation-api.p.rapidapi.com',
    };

    var request = http.Request(
      'POST',
      Uri.parse(
        'https://faceswap-image-transformation-api.p.rapidapi.com/faceswapgroup',
      ),
    );

    request.body = json.encode({
      "SourceImageUrl": source,
      "TargetImageUrl": target,
      "MatchGender": false,
      "MaximumFaceSwapNumber": 1,
    });

    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();

    if (response.statusCode == 200) {
      String responseBody = await response.stream.bytesToString();
      var result = json.decode(responseBody);

      if (result['Success'] == true) {
        String resultImageUrl = result['ResultImageUrl'];
        if (kDebugMode) showLog("📥 Downloading image from: $resultImageUrl");

        var imageResponse = await http.get(Uri.parse(resultImageUrl));
        if (imageResponse.statusCode == 200) {
          final tempDir = await getTemporaryDirectory();
          String dirPath = '${tempDir.path}/face_swap';
          Directory(dirPath).createSync(recursive: true);

          String filePath =
              '$dirPath/face_swap_${DateTime.now().millisecondsSinceEpoch}.jpg';
          File file = File(filePath);
          await file.writeAsBytes(imageResponse.bodyBytes);
          return filePath;
        } else {
          if (kDebugMode) {
            showLog(
              "❌ Failed to download image. Status: ${imageResponse.statusCode}",
            );
          }
        }
      } else {
        if (kDebugMode) {
          showLog("❌ Face swap API response: ${result['Message']}");
        }
      }
    } else {
      if (kDebugMode) showLog("❌ HTTP failed. Status: ${response.statusCode}");
    }

    return null;
  }

  static Future<String?> _callSegmind(
    String targetUrl,
    String sourceFaceUrl,
  ) async {
    if (kDebugMode) showLog("🟡 [faceSegmind] Starting Segmind API call");

    String target = await _getBase64FromImageUrl(targetUrl);
    String source = await _getBase64FromImageUrl(sourceFaceUrl);

    var headers = {
      'x-api-key': faceSwapSegmindKey,
      'content-type': 'application/json',
    };

    var request = http.Request(
      'POST',
      Uri.parse('https://api.segmind.com/v1/faceswap-v2'),
    );
    request.body = json.encode({
      "target_img": target,
      "source_img": source,
      "input_faces_index": 0,
      "source_faces_index": 0,
      "base64": true,
    });

    request.headers.addAll(headers);
    http.StreamedResponse response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      var resultData = jsonDecode(responseBody);
      String? base64Image = resultData['image'];

      if (base64Image != null) {
        if (kDebugMode) showLog("📥 Decoding and saving Segmind image...");
        final bytes = base64Decode(base64Image);
        final directory = await getApplicationDocumentsDirectory();
        final filePath =
            '${directory.path}/face_swap_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(filePath);
        await file.writeAsBytes(bytes);
        return filePath;
      } else {
        if (kDebugMode) showLog("❌ Segmind API returned null image.");
      }
    } else {
      if (kDebugMode) {
        showLog("❌ Segmind API failed. Status: ${response.statusCode}");
      }
      if (kDebugMode) showLog("❌ Segmind API failed. Status: $responseBody");
    }

    return null;
  }

  static Future<String?> _callFastFaceSwap(
    String baseImageUrl,
    String swapImageUrl,
    TempUploadNotifier tempUploadProvider,
  ) async {
    if (kDebugMode) showLog("🟡 [faceFast] Starting Fast Face Swap API call");

    try {
      if (!baseImageUrl.startsWith("http")) {
        if (kDebugMode) showLog("📤 Uploading base image to temp...");
        await tempUploadProvider.uploadFileToTemp(baseImageUrl);
        baseImageUrl = tempUploadProvider.state.uploadedUrl ?? "";
        if (baseImageUrl.isEmpty) {
          if (kDebugMode) showLog("❌ Failed to upload base image.");
          return null;
        }
      }

      if (!swapImageUrl.startsWith("http")) {
        if (kDebugMode) showLog("📤 Uploading swap image to temp...");
        await tempUploadProvider.uploadFileToTemp(swapImageUrl);
        swapImageUrl = tempUploadProvider.state.uploadedUrl ?? "";
        if (swapImageUrl.isEmpty) {
          if (kDebugMode) showLog("❌ Failed to upload swap image.");
          return null;
        }
      }

      final headers = {
        'Content-Type': 'application/json',
        'x-rapidapi-key': fastFaceSwapKey,
        'x-rapidapi-host': 'fast-face-swap-image.p.rapidapi.com',
      };

      final body = jsonEncode({
        'base_image_url': baseImageUrl,
        'swap_image_url': swapImageUrl,
      });

      final response = await http.post(
        Uri.parse('https://fast-face-swap-image.p.rapidapi.com/'),
        headers: headers,
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final imageUrl = data['image']['url'];
        showLog("Success to face swap in fastface $imageUrl");
        if (kDebugMode) showLog("📥 FastFace API returned URL: $imageUrl");

        if (imageUrl != null) {
          var imageResponse = await http.get(Uri.parse(imageUrl));
          if (imageResponse.statusCode == 200) {
            final directory = await getApplicationDocumentsDirectory();
            final filePath =
                '${directory.path}/face_fast_${DateTime.now().millisecondsSinceEpoch}.jpg';
            final file = File(filePath);
            await file.writeAsBytes(imageResponse.bodyBytes);
            return filePath;
          } else {
            if (kDebugMode) {
              showLog(
                "❌ Failed to download FastFace image. Status: ${imageResponse.statusCode}",
              );
            }
          }
        }
      } else {
        if (kDebugMode) {
          showLog("❌ FastFace API failed. Status: ${response.statusCode}");
        }
      }
    } catch (e) {
      if (kDebugMode) showLog("❌ Exception in FastFace API: $e");
    }
    return null;
  }

  static Future<String> _getBase64FromImageUrl(String imagePath) async {
    if (kDebugMode) showLog("📷 Converting image to base64: $imagePath");

    try {
      if (imagePath.startsWith("http")) {
        final response = await http.get(Uri.parse(imagePath));
        if (response.statusCode == 200) {
          return base64Encode(response.bodyBytes);
        } else {
          throw Exception('❌ Failed to load image from URL: $imagePath');
        }
      } else {
        final file = File(imagePath);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          return base64Encode(bytes);
        } else {
          throw Exception('❌ Local image file not found: $imagePath');
        }
      }
    } catch (e) {
      if (kDebugMode) showLog("❌ Error in _getBase64FromImageUrl: $e");
      rethrow;
    }
  }
}

/// ✅ Riverpod provider declaration
final faceSwapProvider = NotifierProvider<FaceSwapNotifier, FaceSwapState>(
  () => FaceSwapNotifier(),
);
