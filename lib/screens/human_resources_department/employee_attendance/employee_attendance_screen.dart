import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../screens/home_screen.dart';
import 'add_employee_attendance_screen.dart';
import '../../../models/employee_attendance_model.dart';

class EmployeeAttendanceScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const EmployeeAttendanceScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _EmployeeAttendanceScreenState createState() =>
      _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  List<EmployeeAttendance> attendances = [];
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
      fetchAttendances();
    });
  }

  Future<void> fetchAttendances() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeAttendance');
      final attendanceList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          attendances = attendanceList
              .map((json) => EmployeeAttendance.fromMap(json))
              .where((attendance) =>
                  searchText == null ||
                  attendance.employeeName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  attendance.checkInTime
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  (attendance.checkOutTime?.toString().toLowerCase() ?? '')
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }

 Future<void> checkOutAttendance(mongo.ObjectId id) async {
  try {
    final db = mongo.Db('mongodb://localhost:27017/$dbName');
    await db.open();

    final collection = db.collection('employeeAttendance');
    final checkOutTime = DateTime.now();

    await collection.update(
      mongo.where.id(id),
      mongo.modify.set('checkOutTime', formatOrderDate(checkOutTime) + ' ' + formatOrderTime(checkOutTime)),
    );

    final attendance = await collection.findOne(mongo.where.id(id));
    if (attendance != null) {
      final checkInTime = DateTime.parse(attendance['checkInTime']);
      final totalWorkingDuration = checkOutTime.difference(checkInTime);

      // Formatting total working time as "X hours Y minutes Z seconds"
      final totalWorkingHours = totalWorkingDuration.inHours;
      final totalWorkingMinutes = totalWorkingDuration.inMinutes % 60;
      final totalWorkingSeconds = totalWorkingDuration.inSeconds % 60;
      final formattedTotalWorkingTime = 
        '$totalWorkingHours hours $totalWorkingMinutes minutes $totalWorkingSeconds seconds';

      await collection.update(
        mongo.where.id(id),
        mongo.modify.set('totalWorkingHour', formattedTotalWorkingTime),
      );
    }

    await db.close();
    fetchAttendances();
  } catch (e) {
    print('Error checking out: $e');
  }
}

  void _showCheckOutConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Check Out Employee',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to check out this employee?',
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
              checkOutAttendance(id);
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

  Map<String, List<EmployeeAttendance>> groupAttendancesByDate(
      List<EmployeeAttendance> attendances) {
    Map<String, List<EmployeeAttendance>> groupedAttendances = {};
    for (var attendance in attendances) {
      String date = formatOrderDate(attendance.checkInTime);
      if (groupedAttendances.containsKey(date)) {
        groupedAttendances[date]!.add(attendance);
      } else {
        groupedAttendances[date] = [attendance];
      }
    }
    return groupedAttendances;
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

  String formatOrderTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<EmployeeAttendance>> groupedAttendances =
        groupAttendancesByDate(attendances);

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
                    fetchAttendances();
                  });
                },
              )
            : Text(
                'Employee Attendance Management',
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
                if (groupedAttendances.isEmpty)
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
                                          'Date: ',
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
                                0: FractionColumnWidth(0.1),
                                1: FractionColumnWidth(0.2),
                                2: FractionColumnWidth(0.2),
                                3: FractionColumnWidth(0.2),
                                4: FractionColumnWidth(0.2),
                                5: FractionColumnWidth(0.1),
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
                                          'Employee Name',
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
                                          'Check In Time',
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
                                          'Check Out Time',
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
                                          'Total Working Hours',
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
                                            'Check Out',
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
                  for (var date in groupedAttendances.keys)
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
                                            'Date: $date',
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
                                  0: FractionColumnWidth(0.1),
                                1: FractionColumnWidth(0.2),
                                2: FractionColumnWidth(0.2),
                                3: FractionColumnWidth(0.2),
                                4: FractionColumnWidth(0.2),
                                5: FractionColumnWidth(0.1),
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
                                            'Employee Name',
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
                                            'Check In Time',
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
                                            'Check Out Time',
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
                                            'Total Working Hours',
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
                                            'Check Out',
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
                                      i < groupedAttendances[date]!.length;
                                      i++)
                                    _buildAttendanceRow(
                                        i, groupedAttendances[date]![i]),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                if (attendances.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Attendance Records available.',
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
          final newAttendance = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddEmployeeAttendanceScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newAttendance != null) {
            fetchAttendances();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  TableRow _buildAttendanceRow(int index, EmployeeAttendance attendance) {
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
              attendance.employeeName,
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
              formatOrderDate(attendance.checkInTime) + ' ' + formatOrderTime(attendance.checkInTime),
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
              attendance.checkOutTime != null
                  ? formatOrderDate(attendance.checkOutTime!)+ ' ' + formatOrderTime(attendance.checkOutTime!)
                  : 'N/A',
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
      attendance.totalWorkingHour != null
          ? (attendance.totalWorkingHour as String) // Explicitly casting to String
          : 'N/A',
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
            child: attendance.checkOutTime == null
                ? IconButton(
                    icon: Icon(Icons.logout, color: Colors.orange),
                    onPressed: () {
                      _showCheckOutConfirmationDialog(attendance.id);
                    },
                  )
                : Icon(
                    Icons.check_circle,
                    color: Colors.green,
                  ),
          ),
        ),
      ],
    );
  }
}
