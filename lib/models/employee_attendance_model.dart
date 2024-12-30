import 'package:mongo_dart/mongo_dart.dart' as mongo;

class EmployeeAttendance {
  final mongo.ObjectId id;
  final String employeeName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final String? totalWorkingHour; // Changed from int? to String?

  EmployeeAttendance({
    required this.id,
    required this.employeeName,
    required this.checkInTime,
    this.checkOutTime,
    this.totalWorkingHour,
  });

  // Factory method to create an EmployeeAttendance instance from a JSON map
  factory EmployeeAttendance.fromMap(Map<String, dynamic> map) {
    return EmployeeAttendance(
      id: map['_id'] as mongo.ObjectId,
      employeeName: map['employeeName'],
      checkInTime: DateTime.parse(map['checkInTime']),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'])
          : null,
      totalWorkingHour: map['totalWorkingHour'] as String?, // Cast to String?
    );
  }

  // Method to convert an EmployeeAttendance instance into a JSON map
  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'employeeName': employeeName,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'totalWorkingHour': totalWorkingHour, // Store as String
    };
  }
}
