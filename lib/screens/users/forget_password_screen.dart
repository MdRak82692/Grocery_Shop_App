import 'package:flutter/material.dart';
import 'dart:math';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import './confirmation_code_screen.dart';
import 'login_screen.dart';

class ForgetPasswordScreen extends StatefulWidget {
  @override
  _ForgetPasswordScreenState createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  final String mongoDbUri = 'mongodb://localhost:27017';

  Future<void> _sendConfirmationCode() async {
    final email = _emailController.text;

    if (email.isEmpty) {
      _showErrorDialog('Please Enter the Email.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _checkEmailExists(email);

      if (user == null) {
        _showErrorDialog(
            'Entered Email is not Correct. Please Enter the Correct Email.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final shopname = user['shopname'] as String;

      final dbName = email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('$mongoDbUri/$dbName');
      await db.open();

      var confirmationCodeCollection = db.collection('ConfirmationCode');

      final confirmationCode = _generateConfirmationCode();

      var result = await confirmationCodeCollection.insertOne({
        'email': email,
        'confirmationCode': confirmationCode,
      });

      // Add a print statement to verify insertion
      if (result.isSuccess) {
        print('Confirmation code inserted successfully: $confirmationCode');
      } else {
        print('Failed to insert confirmation code.');
        throw Exception('Failed to insert confirmation code.');
      }

      await _sendEmailConfirmationCode(email, confirmationCode);

      setState(() {
        _isLoading = false;
      });

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationCodeScreen(
            email: _emailController.text.trim(),
            user: {},
            shopName: shopname,
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

  Future<Map<String, dynamic>?> _checkEmailExists(String email) async {
    try {
      final dbName = email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('$mongoDbUri/$dbName');
      await db.open();

      final userCollection = db.collection('user');
      final user = await userCollection.findOne(
          mongo.where.eq('email', email).fields(['email', 'shopname']));
      print('$userCollection');

      await db.close();

      return user;
    } catch (e) {
      _showErrorDialog('Failed to check email existence. Error: $e');
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
        title: Text(
          'User Forget Password',
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
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.green, Colors.cyan],
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
                    'Enter Your Email',
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
                  controller: _emailController,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    labelText: 'Email',
                    hintText: 'Enter your email',
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
                    prefixIcon: Icon(Icons.email, color: Colors.black),
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
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Remember Password? Log In',
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
