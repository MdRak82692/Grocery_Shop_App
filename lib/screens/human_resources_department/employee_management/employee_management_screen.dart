import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../screens/home_screen.dart';
import 'add_employee_screen.dart';
import 'edit_employee_screen.dart';
import '../../../models/employee_model.dart';

class EmployeeManagementScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const EmployeeManagementScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _EmployeeManagementScreenState createState() =>
      _EmployeeManagementScreenState();
}

class _EmployeeManagementScreenState extends State<EmployeeManagementScreen> {
  List<Employee> employees = [];
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
      fetchEmployees();
    });
  }

  Future<void> fetchEmployees() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employee');
      final employeeList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          employees = employeeList
              .map((json) => Employee.fromJson(json))
              .where((employee) =>
                  searchText == null ||
                  employee.firstName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employee.lastName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employee.position
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employee.department
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  employee.contactNumber.contains(searchText!) ||
                  employee.email
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
  }

  Future<void> deleteEmployee(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employee');
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchEmployees();
    } catch (e) {
      print('Error deleting employee: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Employee',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this employee?',
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
              deleteEmployee(id);
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

  Map<String, List<Employee>> groupEmployeesByDepartment(
      List<Employee> employees) {
    Map<String, List<Employee>> groupedEmployees = {};
    for (var employee in employees) {
      if (groupedEmployees.containsKey(employee.department)) {
        groupedEmployees[employee.department]!.add(employee);
      } else {
        groupedEmployees[employee.department] = [employee];
      }
    }
    return groupedEmployees;
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
    });
  }

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Employee>> groupedEmployees =
        groupEmployeesByDepartment(employees);

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
                    fetchEmployees();
                  });
                },
              )
            : Text(
                'Employee Management',
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
                if (groupedEmployees.isEmpty)
                  Column(
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
                          child: Container(
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
                                    color:
                                        const Color.fromARGB(255, 255, 135, 87),
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
                                            color: const Color.fromARGB(
                                                255, 2, 27, 151),
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
                          child: Container(
                            child: Table(
                              border: TableBorder.all(
                                color: Color(0xFF006400),
                                width: 5.0,
                              ),
                              columnWidths: {
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
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'SL NO',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Name',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Position',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Contact Number',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Email',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Joining Date',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
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
                      ),
                    ],
                  )
                else
                  for (var department in groupedEmployees.keys)
                    Column(
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
                            child: Container(
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
                                      color: const Color.fromARGB(
                                          255, 255, 135, 87),
                                    ),
                                    children: [
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Department: $department',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 2, 27, 151),
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
                            child: Container(
                              child: Table(
                                border: TableBorder.all(
                                  color: Color(0xFF006400),
                                  width: 5.0,
                                ),
                                columnWidths: {
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
                                    decoration:
                                        BoxDecoration(color: Colors.blue),
                                    children: [
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'SL NO',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Name',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Position',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Contact Number',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Email',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Joining Date',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Edit',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Delete',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(
                                                  255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  for (int i = 0;
                                      i < groupedEmployees[department]!.length;
                                      i++)
                                    _buildEmployeeRow(
                                        i, groupedEmployees[department]![i]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                if (employees.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Employee List available.',
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
          final newEmployee = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEmployeeScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newEmployee != null) {
            fetchEmployees();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  TableRow _buildEmployeeRow(int index, Employee employee) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        Container(
          height: 55,
          child: Center(
            child: Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: Text(
              '${employee.firstName} ${employee.lastName}',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: Text(
              employee.position,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: Text(
              employee.contactNumber,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: Text(
              employee.email,
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: Text(
              formatOrderDate(employee.joinDate),
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Container(
          height: 55,
          child: Center(
            child: IconButton(
              icon: Icon(Icons.edit, color: Colors.orange),
              onPressed: () async {
                final updatedEmployee = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditEmployeeScreen(
                      employee: employee,
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    ),
                  ),
                );
                if (updatedEmployee != null) {
                  fetchEmployees();
                }
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
                _showDeleteConfirmationDialog(employee.id);
              },
            ),
          ),
        ),
      ],
    );
  }
}
