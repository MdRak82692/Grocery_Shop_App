import 'package:mongo_dart/mongo_dart.dart' as mongo;

class Category {
  final mongo.ObjectId id;
  final String categoryName;

  Category({required this.id, required this.categoryName});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['_id'] as mongo.ObjectId,
      categoryName: json['categoryName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'categoryName': categoryName,
    };
  }
}
