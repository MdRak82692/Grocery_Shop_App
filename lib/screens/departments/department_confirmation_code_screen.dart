import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../home_screen.dart';
import 'department_login_screen.dart';

class DepartmentConfirmationCodeScreen extends StatefulWidget {
  final String department;
  final String email;
  final String password;
  final Map<String, String> user;
  final String shopName;

  const DepartmentConfirmationCodeScreen(
      {Key? key,
      required this.department,
      required this.email,
      required this.password,
      required this.user,
      required this.shopName})
      : super(key: key);

  @override
  _DepartmentConfirmationCodeScreenState createState() =>
      _DepartmentConfirmationCodeScreenState();
}

class _DepartmentConfirmationCodeScreenState
    extends State<DepartmentConfirmationCodeScreen> {
  final TextEditingController _confirmationCodeController =
      TextEditingController();
  bool _isLoading = false;

  Future<void> _verifyConfirmationCode() async {
    final confirmationCode = _confirmationCodeController.text;

    if (confirmationCode.isEmpty) {
      _showErrorDialog('Please enter the Confirmation Code.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate the database name from the email
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      // Fetch the confirmation code from the database
      final collection = db.collection('ConfirmationCode');
      final document = await collection.findOne(
        mongo.where.eq('email', widget.email).sortBy('_id', descending: true),
      );

      // Close the database connection
      await db.close();

      // Check if the confirmation code matches
      if (document != null &&
          document['confirmationCode'] == confirmationCode) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              department: widget.department,
              email: widget.email,
              user: {},
              shopName: widget.shopName,
            ),
          ),
        );
        _showSucessDialog(
            'Password has been Successfully Updated. Now You are Entered in ${widget.department} Home Page');

        final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
        final db = mongo.Db('mongodb://localhost:27017/$dbName');
        await db.open();

        final collection = db.collection('departments');

        // Check if a user with the given email already exists
        final existingUser =
            await collection.findOne({'department': widget.department});

        if (existingUser == null) {
          // No user found, insert new user data
          await collection.insertOne({
            'department': widget.department,
            'email': widget.email,
            'password': widget.password,
          });
        } else {
          // User found, update the password only
          await collection.updateOne(
            {'department': widget.department},
            mongo.modify.set('password', widget.password),
          );
        }

        await db.close();
      } else {
        // If not match, show an error dialog
        _showErrorDialog(
            'Confirmation Code is not correct. Please enter the correct code.');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to verify confirmation code. Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInfoDialog(
          'Confirmation Code has been sent to your email. Please check your email.');
    });
  }

  void _showInfoDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Confirmation Code Sent',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], // Set background color
      appBar: AppBar(
        title: Text(
          'Department Confirmation Code',
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
                    'Enter the Confirmation Code',
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
                  controller: _confirmationCodeController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Confirmation Code',
                    hintText: 'Enter confirmation code',
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
                    prefixIcon:
                        Icon(Icons.confirmation_number, color: Colors.black),
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
                        onPressed: _verifyConfirmationCode,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          child: Text(
                            'Verify Code',
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
