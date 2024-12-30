import 'package:mongo_dart/mongo_dart.dart';

class SuppliesProfile {
  ObjectId id;
  String suppliesName;
  String contactNumber;
  String productName;
  String supplyCompanyName;

  SuppliesProfile({
    required this.id,
    required this.suppliesName,
    required this.contactNumber,
    required this.productName,
    required this.supplyCompanyName,
  });

  factory SuppliesProfile.fromJson(Map<String, dynamic> json) {
    return SuppliesProfile(
      id: json['_id'] as ObjectId,
      suppliesName: json['suppliesName'] as String,
      contactNumber: json['contactNumber'] as String,
      productName: json['productName'] as String,
      supplyCompanyName: json['supplyCompanyName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'suppliesName': suppliesName,
      'contactNumber': contactNumber,
      'productName': productName,
      'supplyCompanyName': supplyCompanyName,
    };
  }
}
