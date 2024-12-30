import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import '../home_screen.dart';
import './confirmation_code_screen.dart';

class PasswordChangeScreen extends StatefulWidget {
  final String email;
  final Map<String, String> user;
  final String shopName;
  final String department;

  const PasswordChangeScreen({
    super.key,
    required this.email,
    required this.user,
    required this.shopName,
    required this.department,
  });
  @override
  _PasswordChangeScreenState createState() => _PasswordChangeScreenState();
}

class _PasswordChangeScreenState extends State<PasswordChangeScreen> {
  final TextEditingController _oldPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;

  final String mongoDbUri = 'mongodb://localhost:27017';

  Future<void> _sendConfirmationCode() async {
    final oldPassword = _oldPasswordController.text;

    if (oldPassword.isEmpty) {
      _showErrorDialog('Please Enter the Password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _checkPasswordMatch(oldPassword);

      if (user == null) {
        _showErrorDialog(
            'Entered Password is not Correct. Please Enter the Correct Password.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('$mongoDbUri/$dbName');
      await db.open();

      var confirmationCodeCollection = db.collection('ConfirmationCode');

      final confirmationCode = _generateConfirmationCode();

      var result = await confirmationCodeCollection.insertOne({
        'email': widget.email,
        'confirmationCode': confirmationCode,
      });

      if (result.isSuccess) {
        print('Confirmation code inserted successfully: $confirmationCode');
      } else {
        print('Failed to insert confirmation code.');
        throw Exception('Failed to insert confirmation code.');
      }

      await _sendEmailConfirmationCode(widget.email, confirmationCode);

      setState(() {
        _isLoading = false;
      });

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationCodeScreen(
            email: widget.email,
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

  Future<Map<String, dynamic>?> _checkPasswordMatch(String email) async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('$mongoDbUri/$dbName');
      await db.open();

      final userCollection = db.collection('user');
      final user = await userCollection.findOne(mongo.where
          .eq('email', widget.email)
          .fields(['email', 'password', 'shopname']));
      print('$user');

      await db.close();

      return user;
    } catch (e) {
      _showErrorDialog('Failed to check password matching. Error: $e');
      return null;
    }
  }

  String _generateConfirmationCode() {
    return (100000 + (Random().nextInt(900000))).toString();
  }

  Future<void> _sendEmailConfirmationCode(
      String email, String confirmationCode) async {
    final smtpServer = gmail('mdrak82692@gmail.com', 'sunmcgbpvgrygpvh');
    final message = Message()
      ..from = Address('mdrak82692@gmail.com', 'Grocery Shop Management')
      ..recipients.add(widget.email)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'User Password Change',
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
                builder: (context) => HomeScreen(
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
                    'Enter Your Old Password',
                    style: TextStyle(
                      fontSize: 24,
                      fontFamily: 'RobotoCondensed',
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: _oldPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Old Password',
                    hintText: 'Enter Your Old Password',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
