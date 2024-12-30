import 'package:mongo_dart/mongo_dart.dart';

class Product {
  ObjectId id;
  String productName;
  String categoryName;
  double pricePerProduct;

  Product({
    required this.id,
    required this.productName,
    required this.categoryName,
    required this.pricePerProduct,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'] as ObjectId,
      productName: json['productName'] as String,
      categoryName: json['categoryName'] as String,
      pricePerProduct: json['pricePerProduct'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'categoryName': categoryName,
      'pricePerProduct': pricePerProduct,
    };
  }
}
