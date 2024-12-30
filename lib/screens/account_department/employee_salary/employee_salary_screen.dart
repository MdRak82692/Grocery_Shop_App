import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../screens/home_screen.dart';
import 'add_employee_salary_screen.dart';
import 'edit_employee_salary_screen.dart';
import '../../../models/employee_salary_model.dart';

class EmployeeSalaryScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const EmployeeSalaryScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _EmployeeSalaryScreenState createState() => _EmployeeSalaryScreenState();
}

class _EmployeeSalaryScreenState extends State<EmployeeSalaryScreen> {
  List<EmployeeSalary> employeeSalaries = [];
  Map<String, bool> paymentStatus = {}; // Cache payment status
  Timer? _timer;
  String? searchText;
  bool isSearching = false;
  late String dbName;

  @override
  void initState() {
    super.initState();
    dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(microseconds: 1), (timer) {
      fetchEmployeeSalaries();
    });
  }

  Future<void> fetchEmployeeSalaries() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeSalary');
      final employeeSalaryList = await collection.find().toList();

      await db.close();

      // Pre-fetch payment status
      for (var employee in employeeSalaryList) {
        bool isPaid = await _isPaymentDone(EmployeeSalary.fromJson(employee));
        paymentStatus[employee['_id'].toString()] = isPaid;
      }

      if (mounted) {
        setState(() {
          employeeSalaries = employeeSalaryList
              .map((json) => EmployeeSalary.fromJson(json))
              .where((employeeSalary) =>
                  searchText == null ||
                  employeeSalary.employeeName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employeeSalary.position
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employeeSalary.department
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employeeSalary.salaryAmount.toString().contains(searchText!) ||
                  employeeSalary.paymentMethodName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching employee salaries: $e');
    }
  }

  Future<void> deleteEmployeeSalary(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeSalary');
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchEmployeeSalaries();
    } catch (e) {
      print('Error deleting employee salary: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Employee Salary',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this employee salary record?',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'No',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              deleteEmployeeSalary(id);
              Navigator.of(context).pop();
            },
            child: Text(
              'Yes',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<EmployeeSalary>> groupEmployeeSalariesByDepartment(
      List<EmployeeSalary> employeeSalaries) {
    Map<String, List<EmployeeSalary>> groupedEmployeeSalaries = {};
    for (var employeeSalary in employeeSalaries) {
      if (groupedEmployeeSalaries.containsKey(employeeSalary.department)) {
        groupedEmployeeSalaries[employeeSalary.department]!
            .add(employeeSalary);
      } else {
        groupedEmployeeSalaries[employeeSalary.department] = [employeeSalary];
      }
    }
    return groupedEmployeeSalaries;
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
    });
  }

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<EmployeeSalary>> groupedEmployeeSalaries =
        groupEmployeeSalariesByDepartment(employeeSalaries);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 26,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontFamily: 'RobotoCondensed',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 26,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    fetchEmployeeSalaries();
                  });
                },
              )
            : Text(
                'Employee Salary Management',
                style: TextStyle(
                  fontSize: 26,
                  fontFamily: 'RobotoCondensed',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
        backgroundColor: const Color.fromARGB(255, 11, 145, 255),
        leading: IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            if (isSearching) {
              _toggleSearch();
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeScreen(
                    email: widget.email,
                    user: widget.user,
                    shopName: widget.shopName,
                    department: widget.department,
                  ),
                ),
              );
            }
          },
        ),
        actions: [
          if (!isSearching)
            IconButton(
              icon: Icon(Icons.search, color: Colors.black),
              onPressed: _toggleSearch,
            ),
        ],
      ),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.yellow,
              Colors.green,
              Colors.cyan,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (groupedEmployeeSalaries.isEmpty)
                  _buildEmptyTable()
                else
                  for (var department in groupedEmployeeSalaries.keys)
                    _buildDepartmentTable(
                        department, groupedEmployeeSalaries[department]!),
                if (employeeSalaries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Employee Salary List available.',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newEmployeeSalary = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEmployeeSalaryScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newEmployeeSalary != null) {
            fetchEmployeeSalaries();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildEmptyTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.yellow,
                Colors.green,
                Colors.cyan,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Table(
              border: TableBorder.all(
                color: Color(0xFF006400),
                width: 5.0,
              ),
              columnWidths: {
                0: FractionColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 135, 87),
                  ),
                  children: [
                    Container(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Department: ',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 2, 27, 151),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.yellow,
                Colors.green,
                Colors.cyan,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Table(
              border: TableBorder.all(
                color: Color(0xFF006400),
                width: 5.0,
              ),
              columnWidths: const <int, TableColumnWidth>{
                0: FractionColumnWidth(0.07),
                1: FractionColumnWidth(0.18),
                2: FractionColumnWidth(0.13),
                3: FractionColumnWidth(0.15),
                4: FractionColumnWidth(0.20),
                5: FractionColumnWidth(0.13),
                6: FractionColumnWidth(0.07),
                7: FractionColumnWidth(0.07),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Employee Name'),
                    _buildTableHeaderCell('Position'),
                    _buildTableHeaderCell('Salary Amount'),
                    _buildTableHeaderCell('Payment Method Name'),
                    _buildTableHeaderCell('Payment Salary'),
                    _buildTableHeaderCell('Edit'),
                    _buildTableHeaderCell('Delete'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentTable(
      String department, List<EmployeeSalary> employeeSalaries) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.yellow,
                Colors.green,
                Colors.cyan,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Table(
              border: TableBorder.all(
                color: Color(0xFF006400),
                width: 5.0,
              ),
              columnWidths: const <int, TableColumnWidth>{
                0: FractionColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 255, 135, 87),
                  ),
                  children: [
                    Container(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Department: $department',
                          style: const TextStyle(
                            fontSize: 22,
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 2, 27, 151),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.yellow,
                Colors.green,
                Colors.cyan,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Table(
              border: TableBorder.all(
                color: Color(0xFF006400),
                width: 5.0,
              ),
              columnWidths: const <int, TableColumnWidth>{
                0: FractionColumnWidth(0.07),
                1: FractionColumnWidth(0.18),
                2: FractionColumnWidth(0.13),
                3: FractionColumnWidth(0.15),
                4: FractionColumnWidth(0.20),
                5: FractionColumnWidth(0.13),
                6: FractionColumnWidth(0.07),
                7: FractionColumnWidth(0.07),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Employee Name'),
                    _buildTableHeaderCell('Position'),
                    _buildTableHeaderCell('Salary Amount'),
                    _buildTableHeaderCell('Payment Method Name'),
                    _buildTableHeaderCell('Payment Salary'),
                    _buildTableHeaderCell('Edit'),
                    _buildTableHeaderCell('Delete'),
                  ],
                ),
                for (int i = 0; i < employeeSalaries.length; i++)
                  _buildEmployeeSalaryRow(i, employeeSalaries[i]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      height: 60,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 151, 12, 2),
          ),
        ),
      ),
    );
  }

  TableRow _buildEmployeeSalaryRow(int index, EmployeeSalary employeeSalary) {
    bool isPaid = paymentStatus[employeeSalary.id.toString()] ?? false;

    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        _buildTableCell('${index + 1}'),
        _buildTableCell(employeeSalary.employeeName),
        _buildTableCell(employeeSalary.position),
        _buildTableCell(employeeSalary.salaryAmount.toString()),
        _buildTableCell(employeeSalary.paymentMethodName),
        _buildFixedCell(
          isPaid
              ? Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.payment, color: Colors.red),
                  onPressed: () {
                    if (!isPaid) {
                      _processPayment(employeeSalary);
                    }
                  },
                ),
        ),
        Container(
          height: 55,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEmployeeSalaryScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                      employeeName: employeeSalary.employeeName,
                      position: employeeSalary.position,
                      departmentName: employeeSalary.department,
                      salaryAmount: employeeSalary.salaryAmount,
                      paymentMethodName: employeeSalary.paymentMethodName,
                    ),
                  ),
                ).then((_) => fetchEmployeeSalaries());
              },
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _showDeleteConfirmationDialog(employeeSalary.id);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFixedCell(Widget child) {
    return Container(
      height: 55,
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      height: 55,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Future<bool> _isPaymentDone(EmployeeSalary employeeSalary) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final paymentCollection = db.collection('payment');
      final now = DateTime.now();

      final paymentRecord = await paymentCollection.findOne({
        'paymentType': 'Employee Salary',
        'name': employeeSalary.employeeName,
        'totalPrice': employeeSalary.salaryAmount,
        'paymentMethodName': employeeSalary.paymentMethodName,
        'paymentDateTime': {
          '\$gte': formatOrderDate(DateTime(now.year, now.month, 1)),
          '\$lt': formatOrderDate(DateTime(now.year, now.month + 1, 1)),
        },
      });

      await db.close();

      return paymentRecord != null;
    } catch (e) {
      print('Error checking payment status: $e');
      return false;
    }
  }

  void _processPayment(EmployeeSalary employeeSalary) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final paymentCollection = db.collection('payment');
      final paymentDate = DateTime.now();

      await paymentCollection.insertOne({
        'paymentType': 'Employee Salary',
        'name': employeeSalary.employeeName,
        'totalPrice': employeeSalary.salaryAmount,
        'paymentMethodName': employeeSalary.paymentMethodName,
        'paymentDateTime': formatOrderDate(paymentDate),
      });

      await db.close();

      setState(() {
        fetchEmployeeSalaries();
      });
    } catch (e) {
      print('Error processing payment: $e');
    }
  }
}
