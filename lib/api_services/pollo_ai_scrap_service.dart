import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';

//twerk id = "cmakv6z7d05msxhwunk51b8yk"
//jiggle id = "cmb6b9e6r00t524kfrdloybli"
//__Host-next-auth.csrf-token=c150799db4fb986673a87b069ae5b01fd0d857f399d139efb9da1c39ee150a61%7C7f8d8229a200eb28e5a079df0e01705c12474cad54fc91c30b442ba82d6dcc9a; user_group=139; _gcl_au=1.1.1496514058.1750312019; _fwb=194rs6ir2j4uStDQy8ng0jw.1750312019666; _ga=GA1.1.1211320556.1750312020; _yjsu_yjad=1750312020.aaff1c7f-7abf-4db5-b58e-7f67e988dc42; FPID=FPID2.2.h4M%2BAwkJ36zahA4kCdSibMo3dj39cBHWY6AOdPhe3O0%3D.1750312020; FPLC=uARfAyikPfNqQUJZZv5Exk9daZQDn1dhZp8PrdZiIYlyO%2FbskG6pqVYZFPToSPxfqEOIhXofM0E%2Fenn7d8Mv3AMtV%2Bs2d6%2FZRKmhufx4a1xFJwR8KyuPYrJopSu5SA%3D%3D; first-visit-url=https%3A%2F%2Fpollo.ai%2F; _fbp=fb.1.1750312021430.242665664530326632; __Secure-next-auth.callback-url=https%3A%2F%2Fpollo.ai%2Fsign-in-google%3ForiginUrl%3Dhttps%253A%252F%252Fpollo.ai%252F; \$user-info=%7B%22id%22%3A%22cmc2ys1n405usw3k79uiqjc05%22%2C%22name%22%3A%22Sanket%20Rola%22%2C%22email%22%3A%22sanket.rola.beetonz%40gmail.com%22%2C%22firstName%22%3A%22Sanket%22%2C%22lastName%22%3A%22Rola%22%2C%22image%22%3A%22https%3A%2F%2Flh3.googleusercontent.com%2Fa%2FACg8ocKSRsTW4aygIWDq13FrW9cD72tkWnyDiIBC-_ncdcckNIcOoA%3Ds96-c%22%7D; __stripe_mid=ddb02e70-c7c8-429f-8bde-c59c1cfe8af1e99c59; wcs_bt=s_40bba8efa686:1750319108; _rdt_uuid=1750312020246.60990a73-5c11-4490-bd0a-79631d87ecb1; _uetsid=d13f68f04cd011f08c64ebb7c56fab58; _uetvid=d13f96e04cd011f084518588391a3b5d; __Secure-next-auth.session-token=eyJhbGciOiJkaXIiLCJlbmMiOiJBMjU2R0NNIn0..NDJLq-akefTWhVa0.ZWYa2NxyOzBHMcC29Fgvpkk04pjcg7isfX5Iy3vN19u7aes1wg5ISO-Hzddl3ek6z1N32NsexCZzeV7wPYltpPvikxLen031jb0UtSNoQTZ56H649sphq1rVPvD8PBGFS3IaUefht9GO8LhJzVKXy-zEMVOmdQVhUZN-T2FU1awHY9UvgZBJlf11SWXKB8NaV0UopcJWL9zzyXIJzDKJcrtXNhNP8sHFyBWUKuK0RWq5Eaiam2X4L7pdKyHcY5M8iaZu7f8gJOM3j4Rb5aHuYFSCCZwwT8iAybhpr7OGTQIeSPlYKTLsb_YaCtLuZNBCeB36pmT7bGlmf6E-k-42jFR3Tzif7frJ5ebIevIYd3PJF3MKhxUJHBVwPmoLK9-9FBUNs-F6mXX0RQ9Lzu58NOaZZaiBXRaS3GAKNTayhxbvQWyKIL9r5tYewzczeVuCIGPtLVZARAdbpx6IOy3NawOeeg_Id_taCQk7zaos_GCwefgs2k3Y86i0Za9JUPlZC1eEneKxIbqWBYUJdFLiKbgBc4K_GokW9cnkgY7w9Xh9pGSYgDt1vHVh5nQRneyQCho0sAGEpT9hm21A.GW_V2q7LsNNNZayV45Y4CQ; _ga_R1DHFQR2J8=GS2.1.s1750334919\$o4\$g1\$t1750335062\$j60\$l0\$h0

/// Immutable state for PolloAiScrapProvider
/// Holds the reactive variables: loading, status, error, and videoUrl
class PolloAiScrapState {
  final bool isLoading;
  final String status;
  final String? error;
  final String? videoUrl;

  const PolloAiScrapState({
    this.isLoading = false,
    this.status = "",
    this.error,
    this.videoUrl,
  });

  PolloAiScrapState copyWith({
    bool? isLoading,
    String? status,
    String? error,
    String? videoUrl,
  }) {
    return PolloAiScrapState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      error: error,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier
class PolloAiScrapNotifier extends Notifier<PolloAiScrapState> {
  static String polloCookie = GlobalVariables.polloCookie;

  String signUrl = "";
  String accessURL = "";
  static const int _maxStatusPollLimit = 5;
  static int _statusPollTry = 0;

  @override
  PolloAiScrapState build() => const PolloAiScrapState();

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setStatus(String msg) {
    showLog(msg);
    state = state.copyWith(status: msg);
  }

  void _setError(String? msg) {
    showLog("❌ $msg");
    state = state.copyWith(error: msg);
  }

  void _setVideoUrl(String? url) {
    state = state.copyWith(videoUrl: url);
  }

  /// Main API flow with provider tracking
  Future<void> uploadAndGetResultUsingPollScrap({
    required String templateId,
    required String filePath,
  }) async {
    _setLoading(true);
    _setError(null);
    _setVideoUrl(null);
    _setStatus("📝 Step 1: Getting signed URL...");

    try {
      final signResult = await getPolloSignedUrl();
      if (signResult == null) {
        _setError("❌ Failed at Step 1: getPolloSignedUrl");
        _setLoading(false);
        return;
      }

      _setStatus("📤 Step 2: Uploading file to signed URL...");
      final uploadSuccess = await uploadFileToPolloSignedUrl(
        filePath: filePath,
        signedUrl: signUrl,
      );

      if (!uploadSuccess) {
        _setError("❌ Failed at Step 2: uploadFileToPolloSignedUrl");
        _setLoading(false);
        return;
      }

      _setStatus("🎬 Step 3: Creating video task...");
      final videoTaskId = await createPolloVideoTask(
        templateId: templateId,
        imageUrl: accessURL,
      );

      if (videoTaskId == null) {
        _setError("❌ Failed at Step 3: createPolloVideoTask");
        _setLoading(false);
        return;
      }

      _setStatus("⏳ Step 4: Polling for video result...");
      final resultUrl = await getVideoResultWithPolling(
        taskId: videoTaskId.toString(),
      );
      if (resultUrl == null) {
        _setError("❌ Failed at Step 4: getVideoResultWithPolling");
        _setLoading(false);
        return;
      }

      _setStatus("✅ Success! Video URL: $resultUrl");
      _setVideoUrl(resultUrl);
    } catch (e) {
      _setError("❌ Exception: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Step 1: Get Pollo signed upload URL
  Future<Map<String, dynamic>?> getPolloSignedUrl() async {
    final headers = {'Content-Type': 'application/json', 'Cookie': polloCookie};

    final String filename = "${DateTime.now().microsecondsSinceEpoch}.jpg";
    final uri = Uri.parse('https://pollo.ai/api/upload/sign');
    final body = json.encode({"filename": filename, "type": "image"});

    const int maxRetries = 5;
    const Duration delay = Duration(milliseconds: 500);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final request = http.Request('POST', uri)
          ..body = body
          ..headers.addAll(headers);

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();
        showLog(
          'Attempt $attempt response [${response.statusCode}]: $responseBody',
        );
        if (response.statusCode == 200) {
          var result = json.decode(responseBody);
          signUrl = result["sign"];
          accessURL = result["accessURL"];
          return result;
        } else {
          showLog(
            'Attempt $attempt failed with status: ${response.statusCode}',
          );
        }
      } catch (e) {
        showLog('Attempt $attempt encountered an error: $e');
      }

      if (attempt < maxRetries) {
        await Future.delayed(delay);
      }
    }
    showLog("❌ Failed to get signed URL after $maxRetries attempts.");
    return null;
  }

  /// Step 2: Upload file to Pollo signed URL
  Future<bool> uploadFileToPolloSignedUrl({
    required String filePath,
    required String signedUrl,
  }) async {
    try {
      final file = await getLocalFileFromPathOrUrl(filePath);

      if (!await file.exists()) {
        showLog("❌ File does not exist at path: $filePath");
        return false;
      }

      final bytes = await file.readAsBytes();
      final headers = {
        'Content-Type': 'image/jpeg',
        'Origin': 'https://pollo.ai',
      };

      final request = http.Request('PUT', Uri.parse(signedUrl))
        ..bodyBytes = bytes
        ..headers.addAll(headers);

      final response = await request.send();

      if (response.statusCode == 200) {
        showLog("✅ File uploaded successfully.");
        return true;
      } else {
        final respStr = await response.stream.bytesToString();
        showLog("❌ Upload failed with status ${response.statusCode}: $respStr");
        return false;
      }
    } catch (e) {
      showLog("❌ Exception during upload: $e");
      return false;
    }
  }

  /// Step 3: Create Pollo video generation task
  Future<int?> createPolloVideoTask({
    required String templateId,
    required String imageUrl,
    int maxRetries = 15,
    Duration delay = const Duration(seconds: 5),
  }) async {
    final uri = Uri.parse(
      'https://pollo.ai/api/trpc/video.createVideoByTemplate?batch=1',
    );
    final headers = {'Content-Type': 'application/json', 'Cookie': polloCookie};

    final body = jsonEncode({
      "0": {
        "json": {
          "protectionMode": false,
          "prompt": null,
          "templateId": templateId,
          "soundId": null,
          "published": true,
          "templateImage": [imageUrl],
          "configType": "template2video",
          "entryCode": "Templates",
        },
        "meta": {
          "values": {
            "prompt": ["undefined"],
            "soundId": ["undefined"],
          },
        },
      },
    });

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final request = http.Request('POST', uri)
          ..headers.addAll(headers)
          ..body = body;

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final parsed = jsonDecode(responseBody);
          final videoId = parsed[0]?["result"]?["data"]?["json"]?["id"];

          if (videoId != null) {
            showLog("✅ Created video task on attempt $attempt: $videoId");
            return videoId;
          } else {
            showLog(
              "⚠️ Attempt $attempt: ID not found in response. Retrying...",
            );
          }
        } else {
          showLog(
            "❌ Attempt $attempt failed with status ${response.statusCode}: $responseBody",
          );
        }
      } catch (e) {
        showLog("❌ Attempt $attempt error: $e");
      }

      if (attempt < maxRetries) {
        await Future.delayed(delay);
      }
    }
    showLog("❌ Failed to create video task after $maxRetries attempts.");
    return null;
  }

  /// Step 4: Poll for video generation completion
  Future<String?> getVideoResultWithPolling({
    required String taskId,
    int pollLimit = 36,
    Duration pollDelay = const Duration(seconds: 5),
    int currentTry = 0,
  }) async {
    final url =
        'https://pollo.ai/api/trpc/generationStyle.listAllStyles,video.getGeneratingVideo?batch=1&input=%7B%220%22%3A%7B%22json%22%3A%7B%7D%7D%2C%221%22%3A%7B%22json%22%3A%7B%22id%22%3A$taskId%7D%7D%7D';
    final headers = {'Cookie': polloCookie, 'Content-Type': 'application/json'};

    try {
      final request = http.Request('GET', Uri.parse(url));
      request.headers.addAll(headers);

      final streamedResponse = await request.send();

      if (streamedResponse.statusCode != 200) {
        if (_statusPollTry < _maxStatusPollLimit) {
          showLog(
            "Attempt ${_statusPollTry + 1} (status poll): Received status ${streamedResponse.statusCode}. Retrying after delay...",
          );
          _statusPollTry++;
          await Future.delayed(pollDelay);
          return getVideoResultWithPolling(
            taskId: taskId,
            pollLimit: pollLimit,
            pollDelay: pollDelay,
            currentTry: currentTry,
          );
        } else {
          showLog(
            "❌ Max status poll attempts reached. Last status code: ${streamedResponse.statusCode}",
          );
          _statusPollTry = 0;
          return null;
        }
      }

      _statusPollTry = 0;
      final responseBody = await streamedResponse.stream.bytesToString();
      final jsonData = json.decode(responseBody);

      if (jsonData is List && jsonData.length > 1) {
        final videoList =
            jsonData[1]["result"]["data"]["json"]["data"]["videoList"]
                as List<dynamic>?;

        if (videoList == null || videoList.isEmpty) {
          showLog("❌ videoList is empty or missing.");
          return null;
        }

        final videoInfo = videoList[0];
        final status = videoInfo["status"] ?? "";

        if (status == "failed") {
          showLog(
            "❌ Video generation failed: ${videoInfo["failMsg"] ?? "No message"}",
          );
          return null;
        } else if (status == "succeed") {
          showLog("✅ Video generation succeeded.");
          return videoInfo["videoUrlNoWatermark"];
        } else {
          if (currentTry < pollLimit) {
            showLog("ℹ️ Status is '$status'. Polling again after delay...");
            await Future.delayed(pollDelay);
            return getVideoResultWithPolling(
              taskId: taskId,
              pollLimit: pollLimit,
              pollDelay: pollDelay,
              currentTry: currentTry + 1,
            );
          } else {
            showLog("❌ Max polling attempts reached without success.");
            return null;
          }
        }
      } else {
        showLog("❌ Unexpected response format or missing required data.");
        return null;
      }
    } catch (e) {
      showLog("❌ Exception in getVideoResultWithPolling: $e");
      _statusPollTry = 0;
      return null;
    }
  }

  /// Utility: Download or return local file
  Future<File> getLocalFileFromPathOrUrl(String filePath) async {
    if (filePath.startsWith('http')) {
      final dio = Dio();
      final tempDir = await getTemporaryDirectory();
      final fileName = filePath.split('/').last;
      final tempFile = File('${tempDir.path}/$fileName');

      try {
        final response = await dio.download(filePath, tempFile.path);
        if (response.statusCode == 200) {
          showLog('✅ Downloaded file to ${tempFile.path}');
          return tempFile;
        } else {
          throw Exception(
            'Failed to download file. Status code: ${response.statusCode}',
          );
        }
      } catch (e) {
        showLog('❌ Error downloading file: $e');
        rethrow;
      }
    } else {
      return File(filePath);
    }
  }
}

/// ✅ Riverpod provider declaration
final polloAiScrapProvider =
    NotifierProvider<PolloAiScrapNotifier, PolloAiScrapState>(
      () => PolloAiScrapNotifier(),
    );
