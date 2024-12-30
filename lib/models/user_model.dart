class UserModel {
  final String shopOwnerName;
  final String shopName;
  final String shopAddress;
  final String email;
  final String contactNumber;

  UserModel({
    required this.shopOwnerName,
    required this.shopName,
    required this.shopAddress,
    required this.email,
    required this.contactNumber,
  });

  // Method to convert the UserModel to a Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'shopOwnerName': shopOwnerName,
      'shopName': shopName,
      'shopAddress': shopAddress,
      'email': email,
      'contactNumber': contactNumber,
    };
  }

  // Method to create a UserModel from a Map (used when fetching data from the database)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      shopOwnerName: map['shopOwnerName'] ?? '',
      shopName: map['shopName'] ?? '',
      shopAddress: map['shopAddress'] ?? '',
      email: map['email'] ?? '',
      contactNumber: map['contactNumber'] ?? '',
    );
  }
}
