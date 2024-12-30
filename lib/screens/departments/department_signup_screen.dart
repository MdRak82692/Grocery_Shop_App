import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import './department_confirmation_code_screen.dart';
import 'department_login_screen.dart';

class DepartmentSignupScreen extends StatefulWidget {
  final String email;
  final Map<String, String> user;
  final String shopName;

  const DepartmentSignupScreen({
    super.key,
    required this.email,
    required this.user,
    required this.shopName,
  });

  @override
  _DepartmentSignupScreenState createState() => _DepartmentSignupScreenState();
}

class _DepartmentSignupScreenState extends State<DepartmentSignupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  String? _selectedDepartment;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  String passwordStrength = '';

  final List<String> _departments = [
    'General Department',
    'Product Management Department',
    'Sales Department',
    'Account Department',
    'Supply Management Department',
    'Human Resources (HR) Department',
  ];

  final String mongoDbUri = 'mongodb://localhost:27017';

  Future<void> _sendConfirmationCode() async {
    final department = _selectedDepartment;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (department == null || password.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Please fill in all the required fields.');
      return;
    }
    if (!_isPasswordStrong(password)) {
      _showErrorDialog(
          'Password is weak. Please ensure it meets the required criteria.');
      return;
    }
    if (password != confirmPassword) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final departmentExists = await _checkDepartmentExists(department);

      if (departmentExists) {
        _showErrorDialog(
            'Selected Department already has an account. Please choose another department.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();
      print('$dbName');
      print('${widget.email}');

      var collection = db.collection('ConfirmationCode');

      final confirmationCode = _generateConfirmationCode();

      await collection.insertOne({
        'email': widget.email,
        'confirmationCode': confirmationCode,
      });

      await _sendEmailConfirmationCode(widget.email, confirmationCode);

      setState(() {
        _isLoading = false;
      });

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DepartmentConfirmationCodeScreen(
            department: department,
            email: widget.email,
            password: password,
            user: {},
            shopName: widget.shopName,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to send confirmation code. Error: $e');
    }
  }

  Future<bool> _checkDepartmentExists(String department) async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final departmentCollection = db.collection('departments');
      final existingDepartment =
          await departmentCollection.findOne({'department': department});

      await db.close();

      return existingDepartment != null;
    } catch (e) {
      _showErrorDialog('Failed to check department existence. Error: $e');
      return false;
    }
  }

  String _generateConfirmationCode() {
    // Generate a 6-digit random number as a confirmation code
    return (100000 + (Random().nextInt(900000))).toString();
  }

  Future<void> _sendEmailConfirmationCode(
      String email, String confirmationCode) async {
    final smtpServer = gmail('mdrak82692@gmail.com', 'sunmcgbpvgrygpvh');
    final message = Message()
      ..from = Address('mdrak82692@gmail.com', 'Grocery Shop Management')
      ..recipients.add(email)
      ..subject = 'Confirmation Code'
      ..text = 'Your confirmation code is $confirmationCode';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
    } on MailerException catch (e) {
      print('Message not sent. \n' + e.toString());
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }

  bool _isPasswordStrong(String password) {
    final hasUpperCase = password.contains(RegExp(r'[A-Z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasLowerCase = password.contains(RegExp(r'[a-z]'));
    final hasSpecialCharacters =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    final hasMinLength = password.length >= 8;

    if (hasUpperCase &&
        hasDigits &&
        hasLowerCase &&
        hasSpecialCharacters &&
        hasMinLength) {
      setState(() {
        passwordStrength = 'Strong';
      });
      return true;
    } else {
      setState(() {
        passwordStrength = 'Weak';
      });
      return false;
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

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Department Sign Up',
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
                builder: (context) => DepartmentLoginScreen(
                  email: widget.email,
                  user: widget.user,
                  shopName: widget.shopName,
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Image.asset(
                  'assets/icon/logo.png',
                  height: 100,
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Create Department Account',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'RobotoCondensed',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                DropdownButtonFormField<String>(
                  value: _selectedDepartment,
                  items: _departments.map((department) {
                    return DropdownMenuItem<String>(
                      value: department,
                      child: Text(
                        department,
                        style: TextStyle(
                          fontSize: 18,
                          fontFamily: 'RobotoCondensed',
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedDepartment = value;
                    });
                  },
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
                      borderRadius: BorderRadius.circular(10),
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    prefixIcon: Icon(Icons.business, color: Colors.black),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  onChanged: (value) {
                    _isPasswordStrong(value);
                  },
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'New Password',
                    hintText: 'Enter new password',
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 5.0),
                Text(
                  passwordStrength,
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: passwordStrength == 'Strong'
                        ? Colors.black
                        : Colors.red,
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Confirm New Password',
                    hintText: 'Enter Confirm new password',
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
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    prefixIcon: Icon(Icons.lock, color: Colors.black),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible =
                              !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 20.0),
                _isLoading
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _sendConfirmationCode,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          child: Text(
                            'Send Confirmation Code',
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
                SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DepartmentLoginScreen(
                          email: widget.email,
                          user: widget.user,
                          shopName: widget.shopName,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Already have a Department account? Log In',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'RobotoCondensed',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
