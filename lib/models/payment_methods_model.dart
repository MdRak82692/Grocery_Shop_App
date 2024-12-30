import 'package:mongo_dart/mongo_dart.dart' as mongo;

class PaymentMethod {
  final mongo.ObjectId id;
  final String paymentMethodName;

  PaymentMethod({required this.id, required this.paymentMethodName});

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['_id'] as mongo.ObjectId,
      paymentMethodName: json['paymentMethodName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'paymentMethodName': paymentMethodName,
    };
  }
}
