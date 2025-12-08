class VideoResultModel {
  final String videoUrl;
  final String title;
  final String? thumbnailUrl;
  final DateTime timestamp;

  VideoResultModel({
    required this.videoUrl,
    required this.title,
    this.thumbnailUrl,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'videoUrl': videoUrl,
    'title': title,
    'thumbnailUrl': thumbnailUrl,
    'timestamp': timestamp.toIso8601String(),
  };

  factory VideoResultModel.fromJson(Map<String, dynamic> json) => VideoResultModel(
    videoUrl: json['videoUrl'] ?? '',
    title: json['title'] ?? 'Unknown',
    thumbnailUrl: json['thumbnailUrl'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}