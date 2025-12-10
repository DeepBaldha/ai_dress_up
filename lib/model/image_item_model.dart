// Base Image Item Model
class ImageItemModel {
  final String image;
  final String title;

  ImageItemModel({
    required this.image,
    required this.title,
  });

  factory ImageItemModel.fromJson(Map<String, dynamic> json) {
    return ImageItemModel(
      image: json['image'] ?? '',
      title: json['title'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image': image,
      'title': title,
    };
  }
}

// Category Model (for category-based images)
class Category {
  final String name;
  final List<ImageItemModel> items;

  Category({
    required this.name,
    required this.items,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      name: json['name'] ?? '',
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => ImageItemModel.fromJson(item))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

// Category Image Model (for PlayStore, Google, Facebook category images)
class CategoryImageModel {
  final List<Category> categories;

  CategoryImageModel({
    required this.categories,
  });

  factory CategoryImageModel.fromJson(Map<String, dynamic> json) {
    return CategoryImageModel(
      categories: (json['categories'] as List<dynamic>?)
          ?.map((category) => Category.fromJson(category))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }
}

// Men/Women Image Model (for PlayStore, Google, Facebook men/women images)
class MenWomenImageModel {
  final List<ImageItemModel> men;
  final List<ImageItemModel> women;

  MenWomenImageModel({
    required this.men,
    required this.women,
  });

  factory MenWomenImageModel.fromJson(Map<String, dynamic> json) {
    return MenWomenImageModel(
      men: (json['men'] as List<dynamic>?)
          ?.map((item) => ImageItemModel.fromJson(item))
          .toList() ??
          [],
      women: (json['women'] as List<dynamic>?)
          ?.map((item) => ImageItemModel.fromJson(item))
          .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'men': men.map((item) => item.toJson()).toList(),
      'women': women.map((item) => item.toJson()).toList(),
    };
  }
}