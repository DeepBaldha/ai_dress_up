import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import '../model/image_item_model.dart';
import '../utils/global_variables.dart';
import '../utils/utils.dart';
import 'dart:convert';

enum ImageDataType {
  playstoreCategoryImages,
  googleCategoryImages,
  facebookCategoryImages,
  playstoreMenWomenImages,
  googleMenWomenImages,
  facebookMenWomenImages,
}

final imageDataProvider =
    StateNotifierProvider.family<
      ImageDataNotifier,
      AsyncValue<dynamic>,
      ImageDataType
    >((ref, dataType) => ImageDataNotifier(dataType));

final multiImageDataProvider =
    StateNotifierProvider.family<
      MultiImageDataNotifier,
      AsyncValue<Map<ImageDataType, dynamic>>,
      List<ImageDataType>
    >((ref, dataTypes) => MultiImageDataNotifier(dataTypes));

class ImageDataNotifier extends StateNotifier<AsyncValue<dynamic>> {
  ImageDataNotifier(this.dataType) : super(const AsyncValue.loading());

  final ImageDataType dataType;

  bool get _isMenWomenType {
    return dataType == ImageDataType.playstoreMenWomenImages ||
        dataType == ImageDataType.googleMenWomenImages ||
        dataType == ImageDataType.facebookMenWomenImages;
  }

  String get _dataUrl {
    switch (dataType) {
      case ImageDataType.playstoreCategoryImages:
        return GlobalVariables.clothChangeImagesPlayStoreURL;
      case ImageDataType.googleCategoryImages:
        return GlobalVariables.clothChangeImagesGoogleURL;
      case ImageDataType.facebookCategoryImages:
        return GlobalVariables.clothChangeImagesFacebookURL;
      case ImageDataType.playstoreMenWomenImages:
        return GlobalVariables.clothChangeMenWomenPlayStoreURL;
      case ImageDataType.googleMenWomenImages:
        return GlobalVariables.clothChangeMenWomenGoogleURL;
      case ImageDataType.facebookMenWomenImages:
        return GlobalVariables.clothChangeMenWomenFacebookURL;
    }
  }

  String get _logName {
    switch (dataType) {
      case ImageDataType.playstoreCategoryImages:
        return 'PlayStore Category Images';
      case ImageDataType.googleCategoryImages:
        return 'Google Category Images';
      case ImageDataType.facebookCategoryImages:
        return 'Facebook Category Images';
      case ImageDataType.playstoreMenWomenImages:
        return 'PlayStore Men/Women Images';
      case ImageDataType.googleMenWomenImages:
        return 'Google Men/Women Images';
      case ImageDataType.facebookMenWomenImages:
        return 'Facebook Men/Women Images';
    }
  }

  Future<void> fetchImageData() async {
    await _fetchWithRetry();
  }

  Future<void> _fetchWithRetry({int attemptCount = 0}) async {
    try {
      showLog('🌀 Trying to load $_logName (attempt ${attemptCount + 1})');
      state = const AsyncValue.loading();

      final response = await http.get(Uri.parse(_dataUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (_isMenWomenType) {
          final menWomenData = MenWomenImageModel.fromJson(decoded);
          state = AsyncValue.data(menWomenData);
          showLog(
            '✅ $_logName loaded: ${menWomenData.men.length} men, ${menWomenData.women.length} women',
          );
        } else {
          // Parse category format
          final categoryData = CategoryImageModel.fromJson(decoded);
          state = AsyncValue.data(categoryData);
          showLog(
            '✅ $_logName loaded: ${categoryData.categories.length} categories',
          );
        }
      } else {
        showLog(
          '⚠️ Failed with status ${response.statusCode} data type : ${_logName}, retrying in 3 seconds...',
        );
        await Future.delayed(Duration(seconds: 3));
        await _fetchWithRetry(attemptCount: attemptCount + 1);
      }
    } catch (e, st) {
      showLog('❌ Error fetching $_logName: $e, retrying in 3 seconds...');
      await Future.delayed(Duration(seconds: 3));
      await _fetchWithRetry(attemptCount: attemptCount + 1);
    }
  }
}

class MultiImageDataNotifier
    extends StateNotifier<AsyncValue<Map<ImageDataType, dynamic>>> {
  MultiImageDataNotifier(this.dataTypes) : super(const AsyncValue.loading());

  final List<ImageDataType> dataTypes;

  Future<void> fetchAllImageData() async {
    await _fetchAllWithRetry();
  }

  Future<void> _fetchAllWithRetry({int attemptCount = 0}) async {
    try {
      showLog(
        '🌀 Trying to load multiple image data: ${dataTypes.map((e) => e.name).join(", ")} (attempt ${attemptCount + 1})',
      );
      state = const AsyncValue.loading();

      final Map<ImageDataType, dynamic> results = {};

      await Future.wait(
        dataTypes.map((dataType) async {
          await _fetchSingleTypeWithRetry(dataType, results);
        }),
      );

      if (results.isEmpty) {
        showLog('⚠️ No data loaded, retrying in 3 seconds...');
        await Future.delayed(Duration(seconds: 3));
        await _fetchAllWithRetry(attemptCount: attemptCount + 1);
      } else {
        state = AsyncValue.data(results);
        showLog('✅ Successfully loaded ${results.length} image data types');
      }
    } catch (e, st) {
      showLog(
        '❌ Error fetching multiple image data: $e, retrying in 3 seconds...',
      );
      await Future.delayed(Duration(seconds: 3));
      await _fetchAllWithRetry(attemptCount: attemptCount + 1);
    }
  }

  Future<void> _fetchSingleTypeWithRetry(
    ImageDataType dataType,
    Map<ImageDataType, dynamic> results, {
    int attemptCount = 0,
  }) async {
    try {
      final url = _getUrlForType(dataType);
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        results[dataType] = _parseResponse(dataType, decoded);
        showLog('✅ ${dataType.name} loaded successfully');
      } else {
        showLog(
          '⚠️ ${dataType.name} failed with status ${response.statusCode}, retrying...',
        );
        await Future.delayed(Duration(seconds: 2));
        await _fetchSingleTypeWithRetry(
          dataType,
          results,
          attemptCount: attemptCount + 1,
        );
      }
    } catch (e) {
      showLog('❌ Error loading ${dataType.name}: $e, retrying...');
      await Future.delayed(Duration(seconds: 2));
      await _fetchSingleTypeWithRetry(
        dataType,
        results,
        attemptCount: attemptCount + 1,
      );
    }
  }

  String _getUrlForType(ImageDataType dataType) {
    switch (dataType) {
      case ImageDataType.playstoreCategoryImages:
        return GlobalVariables.clothChangeImagesPlayStoreURL;
      case ImageDataType.googleCategoryImages:
        return GlobalVariables.clothChangeImagesGoogleURL;
      case ImageDataType.facebookCategoryImages:
        return GlobalVariables.clothChangeImagesFacebookURL;
      case ImageDataType.playstoreMenWomenImages:
        return GlobalVariables.clothChangeMenWomenPlayStoreURL;
      case ImageDataType.googleMenWomenImages:
        return GlobalVariables.clothChangeMenWomenGoogleURL;
      case ImageDataType.facebookMenWomenImages:
        return GlobalVariables.clothChangeMenWomenFacebookURL;
    }
  }

  bool _isMenWomenType(ImageDataType dataType) {
    return dataType == ImageDataType.playstoreMenWomenImages ||
        dataType == ImageDataType.googleMenWomenImages ||
        dataType == ImageDataType.facebookMenWomenImages;
  }

  dynamic _parseResponse(ImageDataType dataType, dynamic decoded) {
    if (_isMenWomenType(dataType)) {
      return MenWomenImageModel.fromJson(decoded);
    } else {
      return CategoryImageModel.fromJson(decoded);
    }
  }
}
