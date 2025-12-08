import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

final videoLikeProvider = StateNotifierProvider<VideoLikeNotifier, VideoLikeState>((ref) {
  return VideoLikeNotifier();
});

class VideoLikeState {
  final Set<String> likedVideos;
  final Map<String, int> randomLikeCounts;

  VideoLikeState({
    required this.likedVideos,
    required this.randomLikeCounts,
  });

  VideoLikeState copyWith({
    Set<String>? likedVideos,
    Map<String, int>? randomLikeCounts,
  }) {
    return VideoLikeState(
      likedVideos: likedVideos ?? this.likedVideos,
      randomLikeCounts: randomLikeCounts ?? this.randomLikeCounts,
    );
  }
}

class VideoLikeNotifier extends StateNotifier<VideoLikeState> {
  VideoLikeNotifier() : super(VideoLikeState(likedVideos: {}, randomLikeCounts: {})) {
    _loadLikes();
  }

  static const String _likedVideosKey = 'liked_videos';
  static const String _randomCountsKey = 'random_like_counts';
  final _random = Random();

  Future<void> _loadLikes() async {
    final prefs = await SharedPreferences.getInstance();
    final likedVideos = prefs.getStringList(_likedVideosKey) ?? [];
    final randomCountsJson = prefs.getString(_randomCountsKey);

    Map<String, int> randomCounts = {};
    if (randomCountsJson != null) {
      final decoded = Map<String, dynamic>.from(
          const JsonDecoder().convert(randomCountsJson)
      );
      randomCounts = decoded.map((k, v) => MapEntry(k, v as int));
    }

    state = VideoLikeState(
      likedVideos: likedVideos.toSet(),
      randomLikeCounts: randomCounts,
    );
  }

  Future<void> _saveLikes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_likedVideosKey, state.likedVideos.toList());
    await prefs.setString(
      _randomCountsKey,
      const JsonEncoder().convert(state.randomLikeCounts),
    );
  }

  int getDisplayLikeCount(String userName, int? videoLikes) {
    if (videoLikes != null && videoLikes > 0) {
      return videoLikes;
    }

    if (!state.randomLikeCounts.containsKey(userName)) {
      final seed = userName.hashCode;
      return Random(seed).nextInt(9000) + 1000;
    }

    return state.randomLikeCounts[userName]!;
  }

  Future<void> ensureRandomCount(String userName) async {
    if (!state.randomLikeCounts.containsKey(userName)) {
      final seed = userName.hashCode;
      final randomCount = Random(seed).nextInt(9000) + 1000;

      state = state.copyWith(
        randomLikeCounts: {...state.randomLikeCounts, userName: randomCount},
      );
      await _saveLikes();
    }
  }

  Future<void> toggleLike(String userName) async {
    try {
      final isLiked = state.likedVideos.contains(userName);
      final newLikedVideos = {...state.likedVideos};

      if (isLiked) {
        newLikedVideos.remove(userName);
      } else {
        newLikedVideos.add(userName);
      }

      state = state.copyWith(likedVideos: newLikedVideos);
      await _saveLikes();
    } catch (e) {
      print('Error toggling like: $e');
    }
  }

  bool isLiked(String userName) {
    return state.likedVideos.contains(userName);
  }
}