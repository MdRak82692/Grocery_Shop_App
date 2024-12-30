import 'package:mongo_dart/mongo_dart.dart' as mongo;

class EmployeeSalary {
  final mongo.ObjectId id;
  final String employeeName;
  final String position;
  final String department;
  final double salaryAmount;
  final String paymentMethodName;
  final DateTime paymentDate;

  EmployeeSalary({
    required this.id,
    required this.employeeName,
    required this.position,
    required this.department,
    required this.salaryAmount,
    required this.paymentMethodName,
    required this.paymentDate,
  });

  // Factory method to create an EmployeeSalary instance from a JSON map
  factory EmployeeSalary.fromJson(Map<String, dynamic> json) {
    return EmployeeSalary(
      id: json['_id'] as mongo.ObjectId,
      employeeName: json['employeeName'] as String? ?? 'Unknown',
      position: json['position'] as String? ?? 'Unknown',
      department: json['department'] as String? ?? 'Unknown',
      salaryAmount: (json['salaryAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethodName: json['paymentMethodName'] as String? ?? 'Unknown',
      paymentDate: DateTime.tryParse(json['paymentDate'] as String? ?? '') ?? DateTime.now(),
    );
  }

  // Method to convert an EmployeeSalary instance into a JSON map
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'employeeName': employeeName,
      'position': position,
      'department': department,
      'salaryAmount': salaryAmount,
      'paymentMethodName': paymentMethodName,
      'paymentDate': paymentDate.toIso8601String(),
    };
  }
}
