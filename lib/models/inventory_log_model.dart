import 'package:mongo_dart/mongo_dart.dart' as mongo;

class InventoryLog {
  final mongo.ObjectId id;
  final String productName;
  final int productQuantity;
  final DateTime logDateTime;
  final String transactionType;

  InventoryLog({
    required this.id,
    required this.productName,
    required this.productQuantity,
    required this.logDateTime,
    required this.transactionType,
  });

  // Factory method to create an InventoryLog instance from a JSON map
  factory InventoryLog.fromJson(Map<String, dynamic> json) {
    return InventoryLog(
      id: json['_id'] as mongo.ObjectId,
      productName: json['productName'] as String? ?? 'Unknown',
      productQuantity: (json['productQuantity'] as num?)?.toInt() ?? 0,
      logDateTime: DateTime.tryParse(json['logDateTime'] as String? ?? '') ?? DateTime.now(),
      transactionType: json['transactionType'] as String? ?? 'Unknown',
    );
  }

  // Method to convert an InventoryLog instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'productName': productName,
      'productQuantity': productQuantity,
      'logDateTime': logDateTime.toIso8601String(),
      'transactionType': transactionType,
    };
  }
}
