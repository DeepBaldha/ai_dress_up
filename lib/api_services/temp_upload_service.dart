import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../utils/global_variables.dart';
import '../utils/utils.dart';

/// Immutable state for TempUploadProvider
/// Holds all reactive fields that UI can listen to
class TempUploadState {
  final bool isLoading;
  final String status;
  final String? error;
  final String? uploadedUrl;

  const TempUploadState({
    this.isLoading = false,
    this.status = "",
    this.error,
    this.uploadedUrl,
  });

  TempUploadState copyWith({
    bool? isLoading,
    String? status,
    String? error,
    String? uploadedUrl,
  }) {
    return TempUploadState(
      isLoading: isLoading ?? this.isLoading,
      status: status ?? this.status,
      error: error,
      uploadedUrl: uploadedUrl ?? this.uploadedUrl,
    );
  }
}

/// ✅ Converted to Riverpod Notifier version
class TempUploadNotifier extends Notifier<TempUploadState> {
  /// PDF.co API key
  String pdfCoApiKey = GlobalVariables.pdfCoApiKey;

  /// URL prefix (http or https)
  String prefixForTempOrg = GlobalVariables.prefixForTempOrg;

  /// Flag to use only PDF.co (no tmpfiles attempt)
  bool isUsePdfCoOnly = GlobalVariables.isUsePdfCoOnly;

  @override
  TempUploadState build() {
    return const TempUploadState();
  }

  // ✅ Helper methods to update state
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

  void _setUploadedUrl(String? url) {
    state = state.copyWith(uploadedUrl: url);
  }

  /// Smart file upload handler
  /// Tries tmpfiles.org first → if failed → fallback to PDF.co
  Future<void> uploadFileToTemp(String filePath) async {
    _setLoading(true);
    _setError(null);
    _setUploadedUrl(null);
    _setStatus("📤 Starting upload process...");

    try {
      if (isUsePdfCoOnly) {
        showLog("Using PDF.co only for upload...");
        _setStatus("Using PDF.co only for upload...");
        final url = await uploadFileToPdfCo(filePath);
        if (url != null) {
          _setUploadedUrl(url);
          _setStatus("✅ Upload successful via PDF.co!");
        } else {
          _setError("❌ Upload failed via PDF.co");
        }
      } else {
        showLog("Trying tmpfiles.org first...");
        _setStatus("Trying tmpfiles.org first...");
        String? tmpFilesUrl = await uploadFileToTmpFiles(filePath);
        if (tmpFilesUrl != null) {
          _setUploadedUrl(tmpFilesUrl);
          showLog('Image URL is : ${tmpFilesUrl}');
          _setStatus("✅ Upload successful via tmpfiles.org!");
        } else {
          _setStatus("tmpfiles.org failed. Falling back to PDF.co...");
          final pdfUrl = await uploadFileToPdfCo(filePath);
          if (pdfUrl != null) {
            _setUploadedUrl(pdfUrl);
            _setStatus("✅ Upload successful via PDF.co!");
          } else {
            _setError("❌ Upload failed on both tmpfiles.org and PDF.co");
          }
        }
      }
    } catch (e) {
      _setError("Exception during upload: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Upload to tmpfiles.org
  Future<String?> uploadFileToTmpFiles(String filePath) async {
    final Uri uploadUrl = Uri.parse(
      'https://tmpfiles.org/api/v1/upload',
    );

    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        showLog("Error: File not found at $filePath");
        return null;
      }

      final request = http.MultipartRequest('POST', uploadUrl)
        ..files.add(await http.MultipartFile.fromPath('file', filePath));

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final jsonResponse = jsonDecode(responseBody);

        final originalUrl = jsonResponse['data']?['url'];
        if (jsonResponse['status'] == 'success' && originalUrl != null) {
          // Replace "org/" with "org/dl/"
          final downloadUrl = originalUrl.replaceFirst('org/', 'org/dl/');
          return downloadUrl;
        } else {
          showLog("Upload failed: Unexpected response structure");
          return null;
        }
      } else {
        showLog(
          "Failed to upload to tmpfiles. Status: ${response.statusCode}, Reason: ${response.reasonPhrase}",
        );
        return null;
      }
    } catch (e) {
      showLog("Exception occurred while uploading to tmpfiles: $e");
      return null;
    }
  }

  /// Upload to PDF.co
  Future<String?> uploadFileToPdfCo(String filePath) async {
    final fileName = filePath.split(Platform.pathSeparator).last;

    final presignUrl = Uri.parse(
      'https://api.pdf.co/v1/file/upload/get-presigned-url?name=$fileName&encrypt=true',
    );

    final headers = {'x-api-key': pdfCoApiKey};

    try {
      final presignResponse = await http.get(presignUrl, headers: headers);

      if (presignResponse.statusCode != 200) {
        showLog('Failed to get presigned URL: ${presignResponse.body}');
        return null;
      }

      final presignJson = jsonDecode(presignResponse.body);
      final presignedUrl = presignJson['presignedUrl'];
      final publicUrl = presignJson['url'];

      if (presignedUrl == null || publicUrl == null) {
        showLog('Invalid response from presign URL step');
        return null;
      }

      final fileBytes = await File(filePath).readAsBytes();

      final uploadResponse = await http.put(
        Uri.parse(presignedUrl),
        headers: {'Content-Type': 'application/octet-stream'},
        body: fileBytes,
      );

      if (uploadResponse.statusCode == 200) {
        showLog("Upload to PDF.co successful. File available at:\n$publicUrl");
        return publicUrl;
      } else {
        showLog(
          "Upload to PDF.co failed. Status: ${uploadResponse.statusCode}",
        );
        return null;
      }
    } catch (e) {
      showLog('Exception during upload to PDF.co: $e');
      return null;
    }
  }
}

/// ✅ Riverpod provider (replaces ChangeNotifierProvider)
final tempUploadProvider =
    NotifierProvider<TempUploadNotifier, TempUploadState>(
      () => TempUploadNotifier(),
    );
