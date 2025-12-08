import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../model/video_model.dart';
import '../utils/utils.dart';
import 'free_storage_service.dart';

class FreeVideoUsageState {
  final Set<String> usedVideoUserNames;
  final bool isLoading;

  FreeVideoUsageState({
    required this.usedVideoUserNames,
    this.isLoading = false,
  });

  FreeVideoUsageState copyWith({
    Set<String>? usedVideoUserNames,
    bool? isLoading,
  }) {
    return FreeVideoUsageState(
      usedVideoUserNames: usedVideoUserNames ?? this.usedVideoUserNames,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class FreeVideoUsageNotifier extends StateNotifier<FreeVideoUsageState> {
  final FreeVideoStorageService _storageService;

  FreeVideoUsageNotifier(this._storageService)
    : super(FreeVideoUsageState(usedVideoUserNames: {})) {
    _loadUsedVideos();
  }

  // Load used videos from storage
  Future<void> _loadUsedVideos() async {
    state = state.copyWith(isLoading: true);
    final usedVideos = await _storageService.getUsedFreeVideoKeys();
    state = state.copyWith(usedVideoUserNames: usedVideos, isLoading: false);
  }

  // Check if a video can be used for free
  bool canUseFree(VideoModel video) {
    if (!video.isOneTimeFree) return false;
    return !state.usedVideoUserNames.contains(video.userName);
  }

  // Mark video as used
  Future<bool> markAsUsed(VideoModel video) async {
    if (!video.isOneTimeFree) return false;

    final success = await _storageService.markVideoAsUsed(video.userName);

    showLog('there is success : ${success}');

    if (success) {
      state = state.copyWith(
        usedVideoUserNames: {...state.usedVideoUserNames, video.userName},
      );
    }

    return success;
  }

  // Get updated video model with correct free status
  VideoModel getUpdatedVideo(VideoModel video) {
    if (!video.isOneTimeFree) return video;

    final hasBeenUsed = state.usedVideoUserNames.contains(video.userName);

    if (hasBeenUsed) {
      return video.copyWith(isOneTimeFree: false);
    }
    return video;
  }

  // Process a list of videos and update their free status
  List<VideoModel> updateVideoList(List<VideoModel> videos) {
    return videos.map((video) => getUpdatedVideo(video)).toList();
  }

  // Clear all used videos (admin/testing)
  Future<void> clearAllUsedVideos() async {
    await _storageService.clearUsedVideos();
    state = state.copyWith(usedVideoUserNames: {});
  }

  // Refresh from storage
  Future<void> refresh() async {
    await _loadUsedVideos();
  }
}

// Providers
final freeVideoStorageServiceProvider = Provider<FreeVideoStorageService>((
  ref,
) {
  return FreeVideoStorageService();
});

final freeVideoUsageProvider =
    StateNotifierProvider<FreeVideoUsageNotifier, FreeVideoUsageState>((ref) {
      final storageService = ref.watch(freeVideoStorageServiceProvider);
      return FreeVideoUsageNotifier(storageService);
    });
