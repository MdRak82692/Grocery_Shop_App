import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'employee_leave_screen.dart';

class EditEmployeeLeaveScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;
  final mongo.ObjectId leaveId;

  const EditEmployeeLeaveScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
    required this.leaveId,
  }) : super(key: key);

  @override
  _EditEmployeeLeaveScreenState createState() =>
      _EditEmployeeLeaveScreenState();
}

class _EditEmployeeLeaveScreenState extends State<EditEmployeeLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedEmployeeName;
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _employeeNames = [];

  @override
  void initState() {
    super.initState();
    _fetchEmployeeNames();
    _fetchLeaveDetails();
  }

  Future<void> _fetchEmployeeNames() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employee');
      final employeeList = await collection.find().toList();

      await db.close();

      setState(() {
        _employeeNames = employeeList
            .map((e) => (e['firstName'] + ' ' + e['lastName']).toString())
            .toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch employee names. Error: $e');
    }
  }

  Future<void> _fetchLeaveDetails() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeLeave');
      final leaveDetails = await collection.findOne(mongo.where.id(widget.leaveId));

      if (leaveDetails != null) {
        setState(() {
          _selectedEmployeeName = leaveDetails['employeeName'];
          _subjectController.text = leaveDetails['subject'];
          _descriptionController.text = leaveDetails['description'];
        });
      }

      await db.close();
    } catch (e) {
      _showErrorDialog('Failed to fetch leave details. Error: $e');
    }
  }

  Future<void> _updateEmployeeLeave() async {
    if (_subjectController.text.isEmpty || _descriptionController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employeeLeave');
      final applicationDateTime = _getCurrentDateTimeInBangladesh();

      // Update the leave record
      await collection.update(
        mongo.where.id(widget.leaveId),
        mongo.modify
            .set('subject', _subjectController.text)
            .set('description', _descriptionController.text)
            .set ('status', 'Pending')
            .set('applicationDateTime', applicationDateTime),
      );

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeeLeaveScreen(
            email: widget.email,
            user: widget.user,
            shopName: widget.shopName,
            department: widget.department,
          ),
        ),
      );
      _showSuccessDialog('Leave application updated successfully.');
    } catch (e) {
      _showErrorDialog('Failed to update leave application. Error: $e');
    }
  }

   String _getCurrentDateTimeInBangladesh() {
    final now = DateTime.now();
    final bangladeshTimeZoneOffset = Duration(hours: 6);
    final bangladeshTime = now.toUtc().add(bangladeshTimeZoneOffset);
    return formatOrderDate(bangladeshTime);
  }

   String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Success',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Text(
          message,
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
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Error',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
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
              'OK',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Edit Employee Leave Details',
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
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => EmployeeLeaveScreen(
                  email: widget.email,
                  user: widget.user,
                  shopName: widget.shopName,
                  department: widget.department,
                ),
              ),
            );
          },
        ),
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildEmployeeDropdown(),  // Non-editable dropdown for employee name
                  SizedBox(height: 20),
                  _buildTextField(
                      _subjectController, 'Subject', 'Enter subject', Icons.subject),
                  SizedBox(height: 20),
                  _buildDescriptionTextField(_descriptionController, 'Description',
                      'Enter description', Icons.description),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateEmployeeLeave,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Update Leave Application',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'RobotoCondensed',
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        Color.fromARGB(255, 244, 20, 4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedEmployeeName,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Employee Name',
        hintText: 'Select employee name',
        labelStyle: TextStyle(
          fontSize: 18,
          fontFamily: 'RobotoCondensed',
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        hintStyle: TextStyle(
          fontSize: 18,
          fontFamily: 'RobotoCondensed',
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Colors.red,
            width: 10.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 3.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 3.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        prefixIcon: Icon(Icons.person, color: Colors.black),
      ),
      items: _employeeNames.map((name) {
        return DropdownMenuItem<String>(
          value: name,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
      onChanged: null,  // Making dropdown non-editable
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select an employee';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(
          fontSize: 18,
          fontFamily: 'RobotoCondensed',
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        hintStyle: TextStyle(
          fontSize: 18,
          fontFamily: 'RobotoCondensed',
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Colors.red,
            width: 10.0,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 3.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(50),
          borderSide: BorderSide(
            color: Colors.blue,
            width: 3.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        prefixIcon: Icon(icon, color: Colors.black),
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
  Widget _buildDescriptionTextField(
    TextEditingController controller, String label, String hint, IconData icon) {
  return TextFormField(
    controller: controller,
    maxLines: null,  
    keyboardType: TextInputType.multiline, 
    decoration: InputDecoration(
      filled: true,
      fillColor: Colors.white,
      labelText: label,
      alignLabelWithHint: true,  
      hintText: hint,
      labelStyle: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      hintStyle: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(
          color: Colors.red,
          width: 10.0,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(
          color: Colors.blue,
          width: 3.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(50),
        borderSide: BorderSide(
          color: Colors.blue,
          width: 3.0,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),  
      prefixIcon: Icon(icon, color: Colors.black),
    ),
    style: TextStyle(
      fontSize: 18,
      fontFamily: 'RobotoCondensed',
      fontWeight: FontWeight.bold,
      color: Colors.black,
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return 'Please enter $label';
      }
      return null;
    },
  );
}
}
