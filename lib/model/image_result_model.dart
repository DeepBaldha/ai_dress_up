import 'package:intl/intl.dart';

class ImageResultModel {
  final String imagePath;
  final String title;
  final DateTime createdAt;

  ImageResultModel({
    required this.imagePath,
    required this.title,
    required this.createdAt,
  });

  String get formattedDate {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt);
  }

  Map<String, dynamic> toJson() {
    return {
      'imagePath': imagePath,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ImageResultModel.fromJson(Map<String, dynamic> json) {
    return ImageResultModel(
      imagePath: json['imagePath'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}