import 'package:mongo_dart/mongo_dart.dart' as mongo;

class EmployeeLeave {
  final mongo.ObjectId id;
  final String employeeName;
  final String subject;
  final String description;
  final DateTime applicationDateTime;
  final String status;

  EmployeeLeave({
    required this.id,
    required this.employeeName,
    required this.subject,
    required this.description,
    required this.applicationDateTime,
    required this.status,
  });

  // Factory method to create an EmployeeLeave instance from a JSON map
  factory EmployeeLeave.fromJson(Map<String, dynamic> json) {
    return EmployeeLeave(
      id: json['_id'] as mongo.ObjectId,
      employeeName: json['employeeName'],
      subject: json['subject'],
      description: json['description'],
      applicationDateTime: DateTime.parse(json['applicationDateTime']),
      status: json['status'],
    );
  }

  // Method to convert an EmployeeLeave instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeName': employeeName,
      'subject': subject,
      'description': description,
      'applicationDateTime': applicationDateTime.toIso8601String(),
      'status': status,
    };
  }

  // copyWith method to create a new instance with updated fields
  EmployeeLeave copyWith({
    mongo.ObjectId? id,
    String? employeeName,
    String? subject,
    String? description,
    DateTime? applicationDateTime,
    String? status,
  }) {
    return EmployeeLeave(
      id: id ?? this.id,
      employeeName: employeeName ?? this.employeeName,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      applicationDateTime: applicationDateTime ?? this.applicationDateTime,
      status: status ?? this.status,
    );
  }
}
