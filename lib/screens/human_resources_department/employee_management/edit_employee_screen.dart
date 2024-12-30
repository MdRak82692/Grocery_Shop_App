import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/employee_model.dart';
import 'employee_management_screen.dart';

class EditEmployeeScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;
  final Employee employee;

  const EditEmployeeScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
    required this.employee,
  }) : super(key: key);

  @override
  _EditEmployeeScreenState createState() => _EditEmployeeScreenState();
}

class _EditEmployeeScreenState extends State<EditEmployeeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _positionController;
  late TextEditingController _contactNumberController;
  late TextEditingController _emailController;
  DateTime? _selectedJoinDate;
  late String _selectedDepartment;

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.employee.firstName);
    _lastNameController = TextEditingController(text: widget.employee.lastName);
    _positionController = TextEditingController(text: widget.employee.position);
    _contactNumberController =
        TextEditingController(text: widget.employee.contactNumber);
    _emailController = TextEditingController(text: widget.employee.email);
    _selectedJoinDate = widget.employee.joinDate;
    _selectedDepartment = widget.employee.department;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Successful',
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

  Future<void> _selectJoinDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedJoinDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onSurface: const Color.fromARGB(255, 158, 12, 1),
            ),
            textTheme: TextTheme(
              headlineMedium: TextStyle(
                fontSize: 20,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.yellow,
              ),
              bodySmall: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              bodyLarge: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              labelLarge: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedJoinDate) {
      setState(() {
        _selectedJoinDate = picked;
      });
    }
  }

  Future<void> _updateEmployee() async {
    final firstName = _firstNameController.text;
    final lastName = _lastNameController.text;
    final position = _positionController.text;
    final contactNumber = _contactNumberController.text;
    final email = _emailController.text;

    if (firstName.isEmpty ||
        lastName.isEmpty ||
        position.isEmpty ||
        contactNumber.isEmpty ||
        email.isEmpty ||
        _selectedJoinDate == null) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('employee');

      // Check for duplicate Contact Number and Email (excluding the current employee)
      final existingEmployee = await collection.findOne(mongo.where
          .ne('_id', widget.employee.id)
          .eq('contactNumber', contactNumber)
          .or(mongo.where.eq('email', email)));

      if (existingEmployee != null &&
          existingEmployee['_id'] != widget.employee.id) {
        if (existingEmployee['contactNumber'] == contactNumber &&
            existingEmployee['email'] == email) {
          _showErrorDialog(
              'The Contact Number & Email are Exist. Please Enter New Contact Number & Email');
        } else if (existingEmployee['contactNumber'] == contactNumber) {
          _showErrorDialog(
              'The Contact Number is Exist. Please Enter New Contact Number');
        } else if (existingEmployee['email'] == email) {
          _showErrorDialog('The Email is Exist. Please Enter New Email');
        }
        await db.close();
        return;
      }

      // Update employee data
      await collection.update(
        mongo.where.id(widget.employee.id),
        mongo.modify
            .set('firstName', firstName)
            .set('lastName', lastName)
            .set('position', position)
            .set('department', _selectedDepartment)
            .set('contactNumber', contactNumber)
            .set('email', email)
            .set('joinDate', formatOrderDate(_selectedJoinDate!)),
      );

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => EmployeeManagementScreen(
            email: widget.email,
            user: widget.user,
            shopName: widget.shopName,
            department: widget.department,
          ),
        ),
      );
      _showSuccessDialog('Employee Data has been Updated Successfully.');
    } catch (e) {
      _showErrorDialog('Failed to update employee. Error: $e');
    }
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

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Edit Employee Details',
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
                builder: (context) => EmployeeManagementScreen(
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
                  _buildTextField(
                    _firstNameController,
                    'First Name',
                    'Enter first name',
                    Icon(Icons.person, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _lastNameController,
                    'Last Name',
                    'Enter last name',
                    Icon(Icons.person, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _positionController,
                    'Position',
                    'Enter position',
                    Icon(Icons.business_center, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildDepartmentDropdown(),
                  SizedBox(height: 20),
                  _buildTextField(
                    _contactNumberController,
                    'Contact Number',
                    'Enter contact number',
                    Icon(Icons.phone, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _emailController,
                    'Email',
                    'Enter email',
                    Icon(Icons.email, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildJoinDatePickerField(
                    context,
                    Icon(Icons.calendar_today, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateEmployee,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Update Employee Information',
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

  Widget _buildTextField(
      TextEditingController controller, String label, String hint, Icon icon) {
    return TextFormField(
      controller: controller,
      readOnly: label == 'Join Date',
      onTap: label == 'Join Date'
          ? () => _selectJoinDate(context)
          : null, // Only allow date picker for Join Date field
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
        prefixIcon: icon,
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

  Widget _buildDepartmentDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedDepartment,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Department',
        hintText: 'Select the Department',
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
        prefixIcon: Icon(Icons.business, color: Colors.black),
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDepartment = newValue!;
        });
      },
      items: <String>[
        'General Department',
        'Product Management Department',
        'Sales Department',
        'Account Department',
        'Supply Management Department',
        'Human Resources (HR) Department',
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJoinDatePickerField(BuildContext context, Icon icon) {
    return TextFormField(
      controller: TextEditingController(
        text: _selectedJoinDate != null
            ? formatOrderDate(_selectedJoinDate!)
            : 'YYYY-MM-DD',
      ),
      readOnly: true,
      onTap: () => _selectJoinDate(context),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Join Date',
        hintText: _selectedJoinDate != null
            ? formatOrderDate(_selectedJoinDate!)
            : 'Select Join Date',
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
        prefixIcon: icon,
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }
}
