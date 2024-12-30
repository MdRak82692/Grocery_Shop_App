import 'package:mongo_dart/mongo_dart.dart';

class OrderDetails {
  ObjectId id;
  int orderId;
  String productName;
  String categoryName;
  int productQuantity;
  double pricePerProduct;

  OrderDetails({
    required this.id,
    required this.orderId,
    required this.productName,
    required this.categoryName,
    required this.productQuantity,
    required this.pricePerProduct,
  });

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    return OrderDetails(
      id: json['_id'] as ObjectId,
      orderId: json['orderId'] as int,
      productName: json['productName'] as String,
      categoryName: json['categoryName'] as String,
      productQuantity: json['productQuantity'] as int,
      pricePerProduct: json['pricePerProduct'].toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'orderId': orderId,
      'productName': productName,
      'categoryName': categoryName,
      'productQuantity': productQuantity,
      'pricePerProduct': pricePerProduct,
    };
  }
}
