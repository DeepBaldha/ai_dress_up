import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../ads/ads_variable.dart';
import '../api_services/temp_upload_service.dart';
import '../utils/firebase_analytics_service.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../utils/global_variables.dart';
import '../utils/loading_dialog.dart';
import '../utils/utils.dart';
import 'dart:io';

import '../view/image_result_full_screen.dart';
import 'credit_provider.dart';

/// --------------------
/// STATE MODEL
/// --------------------
class ClothChangeState {
  final bool isLoading;
  final bool isDownloading;
  final String? generatedImageUrl;
  final String? localImagePath;
  final String? errorMessage;
  final double downloadProgress;

  const ClothChangeState({
    this.isLoading = false,
    this.isDownloading = false,
    this.generatedImageUrl,
    this.localImagePath,
    this.errorMessage,
    this.downloadProgress = 0.0,
  });

  ClothChangeState copyWith({
    bool? isLoading,
    bool? isDownloading,
    String? generatedImageUrl,
    String? localImagePath,
    String? errorMessage,
    double? downloadProgress,
  }) {
    return ClothChangeState(
      isLoading: isLoading ?? this.isLoading,
      isDownloading: isDownloading ?? this.isDownloading,
      generatedImageUrl: generatedImageUrl,
      localImagePath: localImagePath,
      errorMessage: errorMessage,
      downloadProgress: downloadProgress ?? this.downloadProgress,
    );
  }
}

/// --------------------
/// NOTIFIER
/// --------------------
class ClothChangeNotifier extends StateNotifier<ClothChangeState> {
  final Ref ref;

  bool _isDisposed = false;

  ClothChangeNotifier(this.ref) : super(const ClothChangeState());

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _safeUpdate(void Function() fn) {
    if (!_isDisposed) fn();
  }

  /// --------------------
  /// MAIN GENERATE METHOD
  /// --------------------
  Future<void> generateClothChange({
    required BuildContext context,
    required File humanImage,
    required String garmentImageUrl,
    required int creditCharge,
  }) async {
    if (state.isLoading) return;

    _safeUpdate(() {
      state = state.copyWith(
        isLoading: true,
        isDownloading: false,
        errorMessage: null,
        generatedImageUrl: null,
        localImagePath: null,
        downloadProgress: 0.0,
      );
    });

    LoadingDialog.show(
      context,
      message: getTranslated(context)!.generating,
      secondMessage: getTranslated(
        context,
      )!.yourResultIsOnTheWayJustAFewMinutesToGo,
    );

    final creditNotifier = ref.read(creditProvider.notifier);
    await creditNotifier.deductCredit(creditCharge);

    bool shouldRefund = false;

    FirebaseAnalyticsService.logEvent(eventName: 'GENERATING_IMAGE_CLOTH_CHANGE');

    try {
      final imageUrl = await _callClothChangeApi(
        humanImage: humanImage,
        garmentImageUrl: garmentImageUrl,
      );

      if (imageUrl != null) {
        _safeUpdate(() {
          state = state.copyWith(isLoading: false, generatedImageUrl: imageUrl);
        });

        await _downloadAndNavigate(context, imageUrl);
      } else {
        shouldRefund = true;
        throw Exception("No image URL received");
      }

      if (state.errorMessage != null) {
        shouldRefund = true;
      }
    } catch (e) {
      shouldRefund = true;

      _safeUpdate(() {
        state = state.copyWith(
          isLoading: false,
          isDownloading: false,
          errorMessage: e.toString(),
        );
      });

      if (context.mounted) {
        LoadingDialog.hide(context);
        showToast("Something went wrong");
      }
    } finally {
      if (shouldRefund && !AdsVariable.showIMTester) {
        await creditNotifier.addCredit(creditCharge);
      }
    }
  }

  /// --------------------
  /// SEGMENT API CALL
  /// --------------------
  Future<String?> _callClothChangeApi({
    required File humanImage,
    required String garmentImageUrl,
  }) async {
    try {
      final dio = Dio();

      final tempUploadNotifier = ref.read(tempUploadProvider.notifier);
      await tempUploadNotifier.uploadFileToTemp(humanImage.path);

      final uploadState = ref.read(tempUploadProvider);
      final humanImageUrl = uploadState.uploadedUrl;


      showLog('call1');

      if (humanImageUrl == null) {
        throw Exception("Failed to upload human image: ${uploadState.error}");
      }

      showLog('call2');

      final requestBody = {
        "crop": false,
        "seed": 42,
        "steps": 30,
        "category": "dresses",
        "force_dc": false,
        "human_img": humanImageUrl,
        "garm_img": garmentImageUrl,
        "mask_only": false,
        "garment_des": "Fashionable outfit",
      };

      showLog('call3');

      final response = await dio.post(
        'https://api.segmind.com/v1/idm-vton',
        data: requestBody,
        options: Options(
          headers: {
            'x-api-key': GlobalVariables.segmindAPIKey,
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
      );

      showLog('call4 with response');

      if (response.statusCode == 200) {
        return await _saveRawFile(response.data);
      }

      throw Exception("API failed: ${response.statusMessage}");
    } catch (e) {
      rethrow;
    }
  }

  /// --------------------
  /// SAVE RAW IMAGE BYTES
  /// --------------------
  Future<String> _saveRawFile(List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/cloth_change_${DateTime.now().millisecondsSinceEpoch}.png';

    final file = File(filePath);
    await file.writeAsBytes(bytes);

    return filePath;
  }

  /// --------------------
  /// DOWNLOAD + NAVIGATE
  /// --------------------
  Future<void> _downloadAndNavigate(
    BuildContext context,
    String imageUrl,
  ) async {
    try {
      _safeUpdate(() {
        state = state.copyWith(isDownloading: true, downloadProgress: 0.0);
      });

      String localPath;

      if (imageUrl.startsWith("http")) {
        localPath = await _downloadImage(imageUrl);
      } else {
        localPath = imageUrl;
      }

      _safeUpdate(() {
        state = state.copyWith(
          isDownloading: false,
          localImagePath: localPath,
          downloadProgress: 1.0,
        );
      });

      if (!context.mounted) return;
      LoadingDialog.hide(context);

      await Future.delayed(const Duration(milliseconds: 150));

      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ImageResultFullScreen(
            imagePath: localPath,
            autoSave: true,
            from: "cloth_change",
          ),
        ),
      );
    } catch (e) {
      _safeUpdate(() {
        state = state.copyWith(
          isDownloading: false,
          isLoading: false,
          errorMessage: "Download failed: $e",
        );
      });

      if (context.mounted) {
        LoadingDialog.hide(context);
        showToast("Something went wrong");
      }
    }
  }

  /// --------------------
  /// DOWNLOAD IMAGE
  /// --------------------
  Future<String> _downloadImage(String url) async {
    final dio = Dio();
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        '${dir.path}/cloth_change_${DateTime.now().millisecondsSinceEpoch}.png';

    await dio.download(
      url,
      filePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = received / total;
          _safeUpdate(() {
            state = state.copyWith(downloadProgress: progress);
          });
        }
      },
    );

    return filePath;
  }

  /// --------------------
  /// RESET
  /// --------------------
  void reset() {
    _safeUpdate(() {
      state = const ClothChangeState();
    });
  }
}

/// Provider
final clothChangeProvider =
    StateNotifierProvider<ClothChangeNotifier, ClothChangeState>((ref) {
      return ClothChangeNotifier(ref);
    });
