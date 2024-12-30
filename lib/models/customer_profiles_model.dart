import 'package:mongo_dart/mongo_dart.dart' as mongo;

class CustomerProfile {
  final mongo.ObjectId id;
  final String customerName;
  final String contactNumber;

  CustomerProfile({
    required this.id,
    required this.customerName,
    required this.contactNumber,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['_id'] as mongo.ObjectId,
      customerName: json['customerName'],
      contactNumber: json['contactNumber'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'customerName': customerName,
      'contactNumber': contactNumber,
    };
  }
}
