import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../home_screen.dart';
import '../departments/department_signup_screen.dart';
import '../departments/department_forget_password_screen.dart';

class DepartmentLoginScreen extends StatefulWidget {
  final String email;
  final Map<String, String> user;
  final String shopName;

  const DepartmentLoginScreen(
      {Key? key,
      required this.email,
      required this.user,
      required this.shopName})
      : super(key: key);

  @override
  _DepartmentLoginScreenState createState() => _DepartmentLoginScreenState();
}

class _DepartmentLoginScreenState extends State<DepartmentLoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedDepartment;
  bool _isPasswordVisible = false;

  final List<String> _departments = [
    'General Department',
    'Product Management Department',
    'Sales Department',
    'Account Department',
    'Supply Management Department',
    'Human Resources (HR) Department',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDepartment = null;
    print("Department Shop Name: ${widget.shopName}");
    print("Department Email: ${widget.email}");
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

  Future<void> _login() async {
    final department = _selectedDepartment;
    final password = _passwordController.text;

    if (department == null || password.isEmpty) {
      _showErrorDialog('Please Enter  Department and Password.');
      return;
    }

    setState(() {});

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('departments');
      final user = await collection.findOne({'department': department});
      print('$user');

      if (user == null) {
        _showErrorDialog(
            'Department & Password are not Corrected. Please Enter the Corrected Password and Select the Corrected Department');
      } else if (user['password'] == password) {
        setState(() {});

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
                email: widget.email,
                department: department,
                user: {},
                shopName: widget.shopName),
          ),
        );
        _showSucessDialog(
            'Department Log In Successful. Now You are Entered in $department Home Page');
      } else {
        _showErrorDialog(
            'Department & Password are not Corrected. Please Enter the Corrected Password and Select the Corrected Department');
      }

      await db.close();
    } catch (e) {
      setState(() {});
      _showErrorDialog('Failed to login. Error: $e');
    }
  }

  Future<void> _sigup() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DepartmentSignupScreen(
            email: widget.email, user: {}, shopName: widget.shopName),
      ),
    );
  }

  Future<void> _forgetpassword() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DepartmentForgetPasswordScreen(
            email: widget.email, user: {}, shopName: widget.shopName),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Department Log In',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 11, 145, 255),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
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
                    'Log In to Your Department',
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
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Password',
                    hintText: 'Enter your password',
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
                SizedBox(height: 20.0),
                ElevatedButton(
                  onPressed: _login,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    child: Text(
                      'Log In Department',
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
                  onPressed: _forgetpassword,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Forget Department Password',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'RobotoCondensed',
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                TextButton(
                  onPressed: _sigup,
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 30),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Don\'t have a Department Account? Sign Up',
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
