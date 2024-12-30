import 'package:mongo_dart/mongo_dart.dart' as mongo;

class Employee {
  final mongo.ObjectId id;
  final String firstName;
  final String lastName;
  final String position;
  final String department;
  final String contactNumber;
  final String email;
  final DateTime joinDate;

  Employee({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.position,
    required this.department,
    required this.contactNumber,
    required this.email,
    required this.joinDate,
  });

  // Factory method to create an Employee instance from a JSON map
  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] as mongo.ObjectId,
      firstName: json['firstName'],
      lastName: json['lastName'],
      position: json['position'],
      department: json['department'],
      contactNumber: json['contactNumber'],
      email: json['email'],
      joinDate: DateTime.parse(json['joinDate']),
    );
  }

  // Method to convert an Employee instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'firstName': firstName,
      'lastName': lastName,
      'position': position,
      'department': department,
      'contactNumber': contactNumber,
      'email': email,
      'joinDate': joinDate.toIso8601String(),
    };
  }
}
