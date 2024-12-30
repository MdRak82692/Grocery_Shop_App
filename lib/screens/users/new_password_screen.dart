import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';

import '../departments/department_login_screen.dart';
import 'login_screen.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final Map<String, String> user;
  final String shopName;

  const NewPasswordScreen(
      {Key? key,
      required this.email,
      required this.user,
      required this.shopName})
      : super(key: key);

  @override
  _NewPasswordScreenState createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String passwordStrength = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitialDialog();
    });
  }

  void _showInitialDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Verify Confirmation Code',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Text(
          'Your Entered Confirmation Code is Corrected. Now Enter New Password.',
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

  void _showSucessDialog(String message) {
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

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    if (!_isPasswordStrong(newPassword)) {
      _showErrorDialog(
          'Password is weak. Please ensure it meets the required criteria.');
      return;
    }

    if (newPassword != confirmPassword) {
      _showErrorDialog('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('user');

      // Check if a user with the given email already exists
      final existingUser = await collection.findOne({'email': widget.email});

      if (existingUser == null) {
        // No user found, insert new user data
        await collection.insertOne({
          'shopownername': widget.user['shopOwnerName'],
          'shopname': widget.shopName,
          'contactnumber': widget.user['contactNumber'],
          'shopaddress': widget.user['address'],
          'email': widget.email,
          'password': newPassword,
        });
      } else {
        // User found, update the password only
        await collection.updateOne(
          {'email': widget.email},
          mongo.modify.set('password', newPassword),
        );
      }

      await db.close();

      setState(() {
        _isLoading = false;
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DepartmentLoginScreen(
            email: widget.email,
            user: {},
            shopName: widget.shopName,
          ),
        ),
      );
      _showSucessDialog(
          'Password has been Successfully Updated. Now You are Entered in Department Log In');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to reset password. Error: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Set background color
      appBar: AppBar(
        title: Text(
          'Reset Password',
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
                builder: (context) => LoginScreen(),
              ),
            );
          },
        ),
      ),
      body: Container(
        height: MediaQuery.of(context)
            .size
            .height, // Ensure the container takes full height
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.yellow,
              Colors.green,
              Colors.cyan
            ], // Gradient background
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
                SizedBox(height: 40), // Add space at the top
                Image.asset(
                  'assets/icon/logo.png', // Make sure the logo is placed in the assets folder
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
                    'Enter your new password',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'RobotoCondensed',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: _newPasswordController,
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
                        color: Colors
                            .blue, // Blue border color when enabled (not focused)
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
                      onPressed: _togglePasswordVisibility,
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
                SizedBox(height: 16.0),
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
                        color: Colors
                            .blue, // Blue border color when enabled (not focused)
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
                      onPressed: _toggleConfirmPasswordVisibility,
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
                        onPressed: _resetPassword,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          child: Text(
                            'Reset Password',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
