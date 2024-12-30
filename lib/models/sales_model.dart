import 'package:mongo_dart/mongo_dart.dart' as mongo;

String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

class Sales {
  final mongo.ObjectId id;
  final String customerName;
  final String contactNumber;
  final String productName;
  final int productQuantity;
  final double pricePerProduct;
  final double totalPrice;
  final String paymentMethodName;
  final double totalPriceOfAllProducts;
  final DateTime salesDateTime; // Added salesDateTime

  Sales({
    required this.id,
    required this.customerName,
    required this.contactNumber,
    required this.productName,
    required this.productQuantity,
    required this.pricePerProduct,
    required this.totalPrice,
    required this.paymentMethodName,
    required this.totalPriceOfAllProducts,
    required this.salesDateTime, // Initialize salesDateTime
  });

  factory Sales.fromJson(Map<String, dynamic> json) {
    return Sales(
      id: json['_id'] as mongo.ObjectId,
      customerName: json['customerName'] ?? '', // Handle potential null values
      contactNumber: json['contactNumber'] ?? '', // Handle potential null values
      productName: json['productName'] ?? '', // Handle potential null values
      productQuantity: json['productQuantity'] ?? 0, // Provide default value if null
      pricePerProduct: (json['pricePerProduct'] as num?)?.toDouble() ?? 0.0, // Safeguard null
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0, // Safeguard null
      paymentMethodName: json['paymentMethodName'] ?? '', // Handle potential null values
      totalPriceOfAllProducts: (json['totalPriceOfAllProducts'] as num?)?.toDouble() ?? 0.0, // Safeguard null
      salesDateTime: DateTime.parse(json['salesDateTime'] as String), // Convert String to DateTime
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customerName': customerName,
      'contactNumber': contactNumber,
      'productName': productName,
      'productQuantity': productQuantity,
      'pricePerProduct': pricePerProduct,
      'totalPrice': totalPrice,
      'paymentMethodName': paymentMethodName,
      'totalPriceOfAllProducts': totalPriceOfAllProducts,
      'salesDateTime': formatOrderDate(salesDateTime),
    };
  }
}
