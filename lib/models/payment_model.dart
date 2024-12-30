import 'package:mongo_dart/mongo_dart.dart' as mongo;

class Payment {
  final mongo.ObjectId id;
  final String paymentType;
  final String name;
  final double totalPrice;
  final String paymentMethodName;
  final DateTime paymentDateTime;

  Payment({
    required this.id,
    required this.paymentType,
    required this.name,
    required this.totalPrice,
    required this.paymentMethodName,
    required this.paymentDateTime,
  });

  // Factory method to create a Payment instance from a JSON map
  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'] as mongo.ObjectId,
      paymentType: json['paymentType'] as String? ?? 'Unknown',
      name: json['name'] as String? ?? 'Unknown',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      paymentMethodName: json['paymentMethodName'] as String? ?? 'Unknown',
      paymentDateTime: DateTime.tryParse(json['paymentDateTime'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // Method to convert a Payment instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'paymentType': paymentType,
      'name': name,
      'totalPrice': totalPrice,
      'paymentMethodName': paymentMethodName,
      'paymentDateTime': paymentDateTime.toIso8601String(),
    };
  }
}
