import 'package:flutter/material.dart';

import 'screens/users/login_screen.dart';
import 'screens/users/signup_screen.dart';
import 'screens/users/confirmation_code_screen.dart';
import 'screens/users/forget_password_screen.dart';

import 'screens/departments/department_login_screen.dart';
import 'screens/departments/department_signup_screen.dart';
import 'screens/departments/department_forget_password_screen.dart';

void main() {
  runApp(GroceryShopManagementApp());
}

class GroceryShopManagementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grocery Shop Management',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignupScreen(),
        '/confirmationCode': (context) => ConfirmationCodeScreen(
              email: '',
              user: {},
              shopName: '',
            ),
        '/resetpassword': (context) => ForgetPasswordScreen(),
        '/departmentLogin': (context) => DepartmentLoginScreen(
              email: '',
              user: {},
              shopName: '',
            ),
        '/departmentSignup': (context) => DepartmentSignupScreen(
              email: '',
              user: {},
              shopName: '',
            ),
        '/resetdepartmentpassword': (context) => DepartmentForgetPasswordScreen(
              email: '',
              user: {},
              shopName: '',
            ),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
