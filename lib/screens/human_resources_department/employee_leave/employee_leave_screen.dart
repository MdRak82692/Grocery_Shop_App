import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../screens/home_screen.dart';
import 'add_employee_leave_screen.dart';
import 'edit_employee_leave_screen.dart';
import '../../../models/employee_leave_model.dart';

class EmployeeLeaveScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const EmployeeLeaveScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _EmployeeLeaveScreenState createState() => _EmployeeLeaveScreenState();
}

class _EmployeeLeaveScreenState extends State<EmployeeLeaveScreen> {
  List<EmployeeLeave> leaves = [];
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
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      fetchLeaves();
    });
  }

  Future<void> fetchLeaves() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeLeave');
      final leaveList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          leaves = leaveList
              .map((json) => EmployeeLeave.fromJson(json))
              .where((leave) =>
                  searchText == null ||
                  leave.employeeName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  leave.subject
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  leave.description
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  leave.applicationDateTime
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  leave.status
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching leaves: $e');
    }
  }

  bool _hasExistingApprovalOrRejection(EmployeeLeave leave) {
    for (var existingLeave in leaves) {
      if (existingLeave.employeeName == leave.employeeName &&
          existingLeave.subject == leave.subject &&
          existingLeave.description == leave.description &&
          (existingLeave.status == 'Approved' || existingLeave.status == 'Rejected')) {
        return true;
      }
    }
    return false;
  }

  Future<void> approveLeave(mongo.ObjectId id, EmployeeLeave leave) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeLeave');
      final approvalTime = DateTime.now();

      // Insert a new record with approval status
      await collection.insert({
        'employeeName': leave.employeeName,
        'subject': leave.subject,
        'description': leave.description,
        'applicationDateTime': formatOrderDateTime(approvalTime),
        'status': 'Approved',
      });

      await db.close();
      _refreshLeaveStatus(leave, 'Approved');
    } catch (e) {
      print('Error approving leave: $e');
    }
  }

  Future<void> rejectLeave(mongo.ObjectId id, EmployeeLeave leave) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeLeave');
      final rejectionTime = DateTime.now();

      // Insert a new record with rejection status
      await collection.insert({
        'employeeName': leave.employeeName,
        'subject': leave.subject,
        'description': leave.description,
        'applicationDateTime': formatOrderDateTime(rejectionTime),
        'status': 'Rejected',
      });

      await db.close();
      _refreshLeaveStatus(leave, 'Rejected');
    } catch (e) {
      print('Error rejecting leave: $e');
    }
  }

  void _refreshLeaveStatus(EmployeeLeave leave, String newStatus) {
    // Update the leave status and hide the action icons
    leave = leave.copyWith(status: newStatus);
    fetchLeaves(); // Refresh the list to hide the icons
  }

  void _showApprovalConfirmationDialog(mongo.ObjectId id, EmployeeLeave leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Approve Leave',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Text(
          'Are you sure you want to approve this leave?',
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
              approveLeave(id, leave);
              Navigator.of(context).pop();
            },
            child: Text(
              'Yes',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRejectionConfirmationDialog(mongo.ObjectId id, EmployeeLeave leave) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Leave',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to reject this leave?',
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
              rejectLeave(id, leave);
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

  Map<String, List<EmployeeLeave>> groupLeavesByStatus(List<EmployeeLeave> leaves) {
    Map<String, List<EmployeeLeave>> groupedLeaves = {};
    for (var leave in leaves) {
      String status = leave.status;
      if (groupedLeaves.containsKey(status)) {
        groupedLeaves[status]!.add(leave);
      } else {
        groupedLeaves[status] = [leave];
      }
    }
    return groupedLeaves;
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
    });
  }

  String formatOrderDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<EmployeeLeave>> groupedLeaves = groupLeavesByStatus(leaves);

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
                    fetchLeaves();
                  });
                },
              )
            : Text(
                'Employee Leave Application',
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
                if (leaves.isEmpty)
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
                                        'Status: ',
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
                            columnWidths: {
                              0: FractionColumnWidth(0.06),
                              1: FractionColumnWidth(0.15),
                              2: FractionColumnWidth(0.1),
                              3: FractionColumnWidth(0.3),
                              4: FractionColumnWidth(0.19),
                              5: FractionColumnWidth(0.08),
                              6: FractionColumnWidth(0.06),
                              7: FractionColumnWidth(0.06),  
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
                                          color: const Color.fromARGB(255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Employee Name',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Subject',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Description',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Application Date & Time',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Approval',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Reject',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(255, 151, 12, 2),
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
                                          color: const Color.fromARGB(255, 151, 12, 2),
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
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                          child: Text(
                            'No Leaving Application available.',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'RobotoCondensed',
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  for (var status in groupedLeaves.keys)
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
                                      color: const Color.fromARGB(255, 255, 135, 87),
                                    ),
                                    children: [
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Status: $status Applications',
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
                                  0: FractionColumnWidth(0.06),
                                  1: FractionColumnWidth(0.15),
                                  2: FractionColumnWidth(0.1),
                                  3: FractionColumnWidth(0.3),
                                  4: FractionColumnWidth(0.19),
                                  5: FractionColumnWidth(0.08),
                                  6: FractionColumnWidth(0.06),
                                  7: FractionColumnWidth(0.06),
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
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Employee Name',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Subject',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Description',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Application Date & Time',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Approval',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        height: 60,
                                        child: Center(
                                          child: Text(
                                            'Reject',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontFamily: 'RobotoCondensed',
                                              fontWeight: FontWeight.bold,
                                              color: const Color.fromARGB(255, 151, 12, 2),
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
                                              color: const Color.fromARGB(255, 151, 12, 2),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  for (int i = 0; i < groupedLeaves[status]!.length; i++)
                                    _buildLeaveRow(i, groupedLeaves[status]![i]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newLeave = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEmployeeLeaveScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newLeave != null) {
            fetchLeaves();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

 TableRow _buildLeaveRow(int index, EmployeeLeave leave) {
  return TableRow(
    decoration: BoxDecoration(color: Colors.white),
    children: [
      _buildCell('${index + 1}'), // SL NO
      _buildCell(leave.employeeName), // Employee Name
      _buildCell(leave.subject), // Subject
      _buildDescriptionCell(leave.description), // Description (Justified)
      _buildCell(formatOrderDateTime(leave.applicationDateTime)), // Application Date & Time
      _buildApprovalCell(leave), // Approval Icon
      _buildRejectCell(leave), // Reject Icon
      _buildEditCell(leave), // Edit Icon
    ],
  );
}

Widget _buildCell(String text) {
  return Container(
    padding: EdgeInsets.all(8.0),
    alignment: Alignment.center,  // Center align content
    child: Text(
      text,
      textAlign: TextAlign.center,  // Center align text
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );
}

Widget _buildDescriptionCell(String text) {
  return Container(
    padding: EdgeInsets.all(8.0),
    alignment: Alignment.centerLeft,  // Left align content
    child: Text(
      text,
      textAlign: TextAlign.justify,  // Justify text
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    ),
  );
}

Widget _buildApprovalCell(EmployeeLeave leave) {
  if (leave.status == 'Pending' && !_hasExistingApprovalOrRejection(leave)) {
    return Container(
      padding: EdgeInsets.all(8.0),
      alignment: Alignment.center,  // Center align icon
      child: IconButton(
        icon: Icon(Icons.check_circle, color: Colors.green),
        onPressed: () {
          _approveLeaveAction(leave);
        },
      ),
    );
  } else if (leave.status == 'Approved') {
    return _buildFinalIconCell(Icons.check_circle, Colors.green);
  } else {
    return _buildEmptyCell();
  }
}

Widget _buildRejectCell(EmployeeLeave leave) {
  if (leave.status == 'Pending' && !_hasExistingApprovalOrRejection(leave)) {
    return Container(
      padding: EdgeInsets.all(8.0),
      alignment: Alignment.center,  // Center align icon
      child: IconButton(
        icon: Icon(Icons.cancel, color: Colors.red),
        onPressed: () {
          _rejectLeaveAction(leave);
        },
      ),
    );
  } else if (leave.status == 'Rejected') {
    return _buildFinalIconCell(Icons.cancel, Colors.red);
  } else {
    return _buildEmptyCell();
  }
}

Widget _buildEditCell(EmployeeLeave leave) {
  if (leave.status == 'Pending' && !_hasExistingApprovalOrRejection(leave)) {
    return Container(
      padding: EdgeInsets.all(8.0),
      alignment: Alignment.center,  // Center align icon
      child: IconButton(
        icon: Icon(Icons.edit, color: Colors.blue),
        onPressed: () async {
          final updatedLeave = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditEmployeeLeaveScreen(
                department: widget.department,
                email: widget.email,
                user: widget.user,
                shopName: widget.shopName,
                leaveId: leave.id,  // Pass the leaveId here
              ),
            ),
          );
          if (updatedLeave != null) {
            fetchLeaves();
          }
        },
      ),
    );
  } else {
    return _buildEmptyCell();
  }
}

Widget _buildFinalIconCell(IconData icon, Color color) {
  return Container(
    padding: EdgeInsets.all(8.0),
    alignment: Alignment.center,  // Center align content
    child: Icon(icon, color: color),
  );
}

void _approveLeaveAction(EmployeeLeave leave) async {
  // Update the leave status to 'Approved' and refresh the list
  await approveLeave(leave.id, leave);
  setState(() {
    _refreshLeaveStatus(leave, 'Approved');
  });
}

void _rejectLeaveAction(EmployeeLeave leave) async {
  // Update the leave status to 'Rejected' and refresh the list
  await rejectLeave(leave.id, leave);
  setState(() {
    _refreshLeaveStatus(leave, 'Rejected');
  });
}

Widget _buildEmptyCell() {
  return Container(
    padding: EdgeInsets.all(8.0),
    alignment: Alignment.center,  // Center align content
    child: SizedBox.shrink(),  // Empty content
  );
 }
}