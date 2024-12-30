import 'package:mongo_dart/mongo_dart.dart';

class PurchaseOrder {
  final ObjectId id;
  final int orderId;
  final String suppliesName;
  final double totalPrice;
  final String paymentMethodName;
  final String status;
  final DateTime orderDateTime;
  final String productName; // New field

  PurchaseOrder({
    required this.id,
    required this.orderId,
    required this.suppliesName,
    required this.totalPrice,
    required this.paymentMethodName,
    required this.status,
    required this.orderDateTime,
    required this.productName, // Include in constructor
  });

  // Convert a PurchaseOrder into a Map. The keys must correspond to the names of the fields in your MongoDB collection.
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'orderId': orderId,
      'suppliesName': suppliesName,
      'totalPrice': totalPrice,
      'paymentMethodName': paymentMethodName,
      'status': status,
      'orderDateTime': orderDateTime.toIso8601String(),
      'productName': productName, // Include in map conversion
    };
  }

  // A method to initialize PurchaseOrder from a map. This is useful when retrieving data from MongoDB.
  factory PurchaseOrder.fromMap(Map<String, dynamic> map) {
    return PurchaseOrder(
      id: map['_id'],
      orderId: map['orderId'] is int
          ? map['orderId']
          : int.parse(map['orderId'].toString()), // Ensure orderId is an int
      suppliesName:
          map['suppliesName'] ?? '', // Provide a default value if null
      totalPrice: map['totalPrice'] is double
          ? map['totalPrice']
          : double.parse(
              map['totalPrice'].toString()), // Ensure totalPrice is a double
      paymentMethodName:
          map['paymentMethodName'] ?? '', // Provide a default value if null
      status: map['status'] ?? '', // Provide a default value if null
      orderDateTime: map['orderDateTime'] != null
          ? DateTime.parse(map['orderDateTime'])
          : DateTime.now(), // Provide a default if null
      productName: map['productName'] ?? '', // Handle null case for productName
    );
  }
}
