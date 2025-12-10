class ImageModel {
  final String url;
  final String title;

  ImageModel({
    required this.url,
    this.title = '',
  });

  factory ImageModel.fromJson(dynamic json) {
    if (json is String) {
      return ImageModel(
        url: json,
        title: json.split('/').last.split('.').first,
      );
    }

    return ImageModel(
      url: json['url'] ?? '',
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'title': title,
    };
  }

  ImageModel copyWith({
    String? url,
    String? title,
  }) {
    return ImageModel(
      url: url ?? this.url,
      title: title ?? this.title,
    );
  }
}
