import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;

import '../../../models/payment_methods_model.dart';
import 'payment_method_screen.dart';

class EditPaymentMethodScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;
  final PaymentMethod paymentMethod; // Corrected reference to PaymentMethod

  const EditPaymentMethodScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
    required this.paymentMethod,
  }) : super(key: key);

  @override
  _EditPaymentMethodScreenState createState() =>
      _EditPaymentMethodScreenState();
}

class _EditPaymentMethodScreenState extends State<EditPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _paymentMethodNameController;

  @override
  void initState() {
    super.initState();
    _paymentMethodNameController = TextEditingController(
        text: widget.paymentMethod.paymentMethodName); // Fixed typo
  }

  @override
  void dispose() {
    _paymentMethodNameController.dispose();
    super.dispose();
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

  Future<void> _updatePaymentMethod() async {
    if (_formKey.currentState!.validate()) {
      final paymentMethodName = _paymentMethodNameController.text;

      try {
        final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
        final db = mongo.Db('mongodb://localhost:27017/$dbName');
        await db.open();

        final collection = db.collection('paymentMethod');

        final existingMethod = await collection
            .findOne(mongo.where.eq('paymentMethodName', paymentMethodName));

        if (existingMethod != null &&
            existingMethod['_id'] != widget.paymentMethod.id) {
          _showErrorDialog(
              'Payment Method Name already exists. Please Enter New Payment Method Name.');
        } else {
          await collection.update(
            mongo.where.id(widget.paymentMethod.id),
            mongo.modify.set('paymentMethodName', paymentMethodName),
          );

          await db.close();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentMethodScreen(
                email: widget.email,
                user: widget.user,
                shopName: widget.shopName,
                department: widget.department,
              ),
            ),
          );
          _showSucessDialog(
              'Payment Method Data has been Updated Successfully.');
        }
      } catch (e) {
        _showErrorDialog('Failed to update payment method. Error: $e');
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
          'Edit Payment Method Details',
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
                builder: (context) => PaymentMethodScreen(
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
                  _buildTextField(_paymentMethodNameController,
                      'Payment Method Name', 'Enter Payment Method name'),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updatePaymentMethod,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Update Payment Method',
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
      TextEditingController controller, String label, String hint) {
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
        prefixIcon: Icon(Icons.category, color: Colors.black),
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
