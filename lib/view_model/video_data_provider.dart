import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
import '../utils/global_variables.dart';
import '../model/video_model.dart';
import '../utils/utils.dart';
import 'dart:convert';

enum VideoDataType { homeNormal, homeFacebook, homeGoogle }

final videoDataProvider =
    StateNotifierProvider.family<
      VideoDataNotifier,
      AsyncValue<dynamic>,
      VideoDataType
    >((ref, dataType) => VideoDataNotifier(dataType));

final multiVideoDataProvider =
    StateNotifierProvider.family<
      MultiVideoDataNotifier,
      AsyncValue<Map<VideoDataType, dynamic>>,
      List<VideoDataType>
    >((ref, dataTypes) => MultiVideoDataNotifier(dataTypes));

class VideoDataNotifier extends StateNotifier<AsyncValue<dynamic>> {
  VideoDataNotifier(this.dataType) : super(const AsyncValue.loading());

  final VideoDataType dataType;

  String get _dataUrl {
    switch (dataType) {
      case VideoDataType.homeNormal:
        return GlobalVariables.videoHomeURL;
      case VideoDataType.homeFacebook:
        return GlobalVariables.videoListForFacebookAds;
      case VideoDataType.homeGoogle:
        return GlobalVariables.videoListForGoogleAds;
    }
  }

  String get _logName {
    switch (dataType) {
      case VideoDataType.homeFacebook:
        return 'Facebook';
      case VideoDataType.homeGoogle:
        return 'Google';
      case VideoDataType.homeNormal:
        return 'PlayStore';
    }
  }

  Future<void> fetchVideoData() async {
    await _fetchWithRetry();
  }

  Future<void> _fetchWithRetry({int attemptCount = 0}) async {
    try {
      showLog(
        '🌀 Trying to load $_logName video data (attempt ${attemptCount + 1})',
      );
      state = const AsyncValue.loading();

      final response = await http.get(Uri.parse(_dataUrl));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        final videos = (decoded as List<dynamic>)
            .map((item) => VideoModel.fromJson(item))
            .toList();

        final originalVideos = videos;
        final shuffledVideos = [...videos]..shuffle();

        state = AsyncValue.data({
          'original': originalVideos,
          'shuffled': shuffledVideos,
        });

        showLog('✅ $_logName video data loaded: ${videos.length} items');
      }
      else {
        showLog(
          '⚠️ Failed with status ${response.statusCode} data type : ${_logName}, retrying in 3 seconds...',
        );
        await Future.delayed(Duration(seconds: 3));
        await _fetchWithRetry(attemptCount: attemptCount + 1);
      }
    } catch (e, st) {
      showLog(
        '❌ Error fetching $_logName video data: $e, retrying in 3 seconds...',
      );
      await Future.delayed(Duration(seconds: 3));
      await _fetchWithRetry(attemptCount: attemptCount + 1);
    }
  }
}

class MultiVideoDataNotifier
    extends StateNotifier<AsyncValue<Map<VideoDataType, dynamic>>> {
  MultiVideoDataNotifier(this.dataTypes) : super(const AsyncValue.loading());

  final List<VideoDataType> dataTypes;

  Future<void> fetchAllVideoData() async {
    await _fetchAllWithRetry();
  }

  Future<void> _fetchAllWithRetry({int attemptCount = 0}) async {
    try {
      showLog(
        '🌀 Trying to load multiple video data: ${dataTypes.map((e) => e.name).join(", ")} (attempt ${attemptCount + 1})',
      );
      state = const AsyncValue.loading();

      final Map<VideoDataType, dynamic> results = {};

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
        showLog('✅ Successfully loaded ${results.length} data types');
      }
    } catch (e, st) {
      showLog(
        '❌ Error fetching multiple video data: $e, retrying in 3 seconds...',
      );
      await Future.delayed(Duration(seconds: 3));
      await _fetchAllWithRetry(attemptCount: attemptCount + 1);
    }
  }

  Future<void> _fetchSingleTypeWithRetry(
    VideoDataType dataType,
    Map<VideoDataType, dynamic> results, {
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

  String _getUrlForType(VideoDataType dataType) {
    switch (dataType) {
      case VideoDataType.homeNormal:
        return GlobalVariables.videoHomeURL;
      case VideoDataType.homeFacebook:
        return GlobalVariables.videoListForFacebookAds;
      case VideoDataType.homeGoogle:
        return GlobalVariables.videoListForGoogleAds;
    }
  }

  dynamic _parseResponse(VideoDataType dataType, dynamic decoded) {
    return (decoded as List<dynamic>)
        .map((item) => VideoModel.fromJson(item))
        .toList();
  }
}
