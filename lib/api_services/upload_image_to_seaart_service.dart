import 'dart:convert';
import 'dart:io';
import 'package:ai_dress_up/api_services/temp_upload_service.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for UploadImageToSeaArtService
/// Holds simple reactive upload state for UI or internal usage
class UploadImageSeaArtState {
  final bool isUploading;
  final String? uploadedUrl;
  final String? error;

  const UploadImageSeaArtState({
    this.isUploading = false,
    this.uploadedUrl,
    this.error,
  });

  UploadImageSeaArtState copyWith({
    bool? isUploading,
    String? uploadedUrl,
    String? error,
  }) {
    return UploadImageSeaArtState(
      isUploading: isUploading ?? this.isUploading,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
      error: error,
    );
  }
}

/// ✅ Riverpod Notifier replacing ChangeNotifier for UploadImageToSeaArtService
class UploadImageToSeaArtNotifier extends Notifier<UploadImageSeaArtState> {
  final TempUploadNotifier tempUploadNotifier = TempUploadNotifier();

  static const String _uploadMetaUrl =
      'https://www.seaart.ai/api/v1/resource/uploadImageByPreSign';
  static const String _uploadConfirmUrl =
      'https://www.seaart.ai/api/v1/resource/confirmImageUploadedByPreSign';
  static const String _uploadUrlEndpoint =
      'https://www.seaart.ai/api/v1/resource/uploadImageByUrl';
  static String cookie = GlobalVariables.seaArtCookie;

  @override
  UploadImageSeaArtState build() => const UploadImageSeaArtState();

  void _setUploading(bool value) {
    state = state.copyWith(isUploading: value);
  }

  void _setError(String? value) {
    state = state.copyWith(error: value);
  }

  void _setUploadedUrl(String? url) {
    state = state.copyWith(uploadedUrl: url);
  }

  /// 🔹 Unified handler function with fallback
  Future<String?> handleUpload({
    required String filePath,
    bool isUrl = false,
  }) async {
    _setUploading(true);
    _setError(null);
    _setUploadedUrl(null);

    try {
      String? result;
      if (isUrl) {
        result = await _uploadViaUrl(filePath, cookie);
        if (result != null) {
          _setUploadedUrl(result);
          return result;
        }

        showLog("⚠️ Falling back to file upload...");
        result = await _uploadViaFile(filePath, cookie);
        _setUploadedUrl(result);
        return result;
      } else {
        result = await _uploadViaFile(filePath, cookie);
        if (result != null) {
          _setUploadedUrl(result);
          return result;
        }

        showLog("⚠️ Falling back to URL upload...");
        result = await _uploadViaUrl(filePath, cookie);
        _setUploadedUrl(result);
        return result;
      }
    } catch (e) {
      _setError("❌ Upload failed: $e");
      showLog("❌ UploadImageToSeaArtService error: $e");
    } finally {
      _setUploading(false);
    }
    return null;
  }

  /// 🔹 Upload via remote URL (after temp hosting)
  Future<String?> _uploadViaUrl(String filePath, String cookie) async {
    try {
      // Step 1: Upload to temporary hosting
      await tempUploadNotifier.uploadFileToTemp(filePath);
      final uploadedUrl = tempUploadNotifier.state.uploadedUrl ?? "";
      if (uploadedUrl.isEmpty) {
        showLog("❌ Temp upload failed.");
        return null;
      }

      // Step 2: Send uploaded URL to SeaArt API
      final response = await http.post(
        Uri.parse(_uploadUrlEndpoint),
        headers: _defaultHeaders(cookie),
        body: jsonEncode({"url": uploadedUrl}),
      );

      // Step 3: Extract access_url
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        showLog("RESPONSE ==> $body");
        final accessUrl = body['data']?['access_url'];
        if (accessUrl != null) {
          showLog("✅ access_url: $accessUrl");
          return accessUrl;
        } else {
          showLog("❌ access_url missing in response");
        }
      } else {
        showLog("❌ SeaArt URL upload error: ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      showLog("❌ URL upload error: $e");
    }
    return null;
  }

  /// 🔹 Upload via direct file method
  Future<String?> _uploadViaFile(String filePath, String cookie) async {
    try {
      String filePathh = "";
      if (filePath.contains("http")) {
        var dir = await getApplicationDocumentsDirectory();
        int microSeconds = DateTime.now().microsecondsSinceEpoch;
        filePathh = "${dir.path}/image_expand_$microSeconds.png";
        await downloadFileToAppDirectory(
          fileUrl: filePath,
          filePathToSave: filePathh,
        );
      } else {
        filePathh = filePath;
      }
      final File file = File(filePathh);
      final info = await imageInfo(file);

      // Step 1: Request pre-signed URL
      final metaRes = await http.post(
        Uri.parse(_uploadMetaUrl),
        headers: _defaultHeaders(cookie),
        body: jsonEncode({
          "content_type": info['content_type'],
          "file_name": info['file_name'],
          "file_size": info['file_size'],
          "category": 16,
          "hash_val": info['hash_val'],
        }),
      );

      if (metaRes.statusCode != 200) {
        showLog("❌ Failed to get pre-sign URL: ${metaRes.body}");
        return null;
      }

      showLog('response code is : ${metaRes.statusCode}');
      final metaJson = jsonDecode(metaRes.body);
      showLog('meta json : ${metaJson}');
      final String fileId = metaJson['data']['file_id'] ?? "";
      showLog('3');
      final String preSignUrl = metaJson['data']['pre_sign'] ?? "";

      showLog('4');

      if (preSignUrl.isEmpty) {
        return metaJson['data']['img_url'];
      }

      // Step 2: Upload image to S3
      final uploadRes = await http.put(
        Uri.parse(preSignUrl),
        headers: {'Content-Type': info['content_type']},
        body: await file.readAsBytes(),
      );

      if (uploadRes.statusCode != 200) {
        showLog("❌ Upload failed: ${uploadRes.body}");
        return null;
      }

      // Step 3: Confirm upload
      final confirmRes = await http.post(
        Uri.parse(_uploadConfirmUrl),
        headers: _defaultHeaders(cookie),
        body: jsonEncode({"file_id": fileId, "category": 16}),
      );

      if (confirmRes.statusCode != 200) {
        showLog("❌ Confirmation failed: ${confirmRes.body}");
        return null;
      }

      final confirmJson = jsonDecode(confirmRes.body);
      final String? finalUrl = confirmJson['data']?['url'];

      if (finalUrl == null || finalUrl.isEmpty) {
        showLog("❌ No final URL found in confirmation");
        return null;
      }
      return finalUrl;
    } on Exception catch (e) {
      showLog("ERROR IN _uploadViaFile $e");
      return null;
    }
  }

  /// 📦 Extract file metadata
  static Future<Map<String, dynamic>> imageInfo(File file) async {
    final bytes = await file.readAsBytes();
    return {
      'content_type': lookupMimeType(file.path) ?? 'application/octet-stream',
      'file_name': path.basename(file.path),
      'file_size': bytes.length,
      'hash_val': sha256.convert(bytes).toString(),
    };
  }

  /// 🧾 Common headers
  static Map<String, String> _defaultHeaders(String cookie) {
    return {'cookie': cookie, 'Content-Type': 'application/json'};
  }

  /// 📥 Download file to app directory (used when input is a remote URL)
  static Future<void> downloadFileToAppDirectory({
    required String fileUrl,
    required String filePathToSave,
  }) async {
    try {
      showLog("📥 Downloading file from: $fileUrl");

      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode == 200) {
        final File file = File(filePathToSave);
        await file.writeAsBytes(response.bodyBytes);
        showLog("✅ File downloaded successfully to: $filePathToSave");
      } else {
        showLog("❌ Failed to download file: ${response.statusCode}");
        throw Exception('Failed to download file: ${response.statusCode}');
      }
    } catch (e) {
      showLog("❌ Error downloading file: $e");
      throw Exception('Error downloading file: $e');
    }
  }
}

/// ✅ Riverpod provider declaration
final uploadImageToSeaArtProvider =
NotifierProvider<UploadImageToSeaArtNotifier, UploadImageSeaArtState>(
        () => UploadImageToSeaArtNotifier());
