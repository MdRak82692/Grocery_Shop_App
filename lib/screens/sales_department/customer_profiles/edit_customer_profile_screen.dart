import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'customer_profiles_screen.dart';
import '../../../models/customer_profiles_model.dart';

class EditCustomerProfileScreen extends StatefulWidget {
  final String email;
  final CustomerProfile customerProfile;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const EditCustomerProfileScreen({
    Key? key,
    required this.email,
    required this.customerProfile,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _EditCustomerProfileScreenState createState() =>
      _EditCustomerProfileScreenState();
}

class _EditCustomerProfileScreenState extends State<EditCustomerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _customerNameController;
  late TextEditingController _contactNumberController;

  @override
  void initState() {
    super.initState();
    _customerNameController =
        TextEditingController(text: widget.customerProfile.customerName);
    _contactNumberController =
        TextEditingController(text: widget.customerProfile.contactNumber);
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  Future<void> _updateCustomerProfile() async {
    if (_formKey.currentState!.validate()) {
      final customerName = _customerNameController.text;
      final contactNumber = _contactNumberController.text;

      try {
        final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
        final db = mongo.Db('mongodb://localhost:27017/$dbName');
        await db.open();

        final collection = db.collection('customerProfiles');

        // Check if the new contact number already exists in another profile
        final existingProfile = await collection.findOne(mongo.where
            .eq('contactNumber', contactNumber)
            .ne('_id', widget.customerProfile.id));
        if (existingProfile != null) {
          _showErrorDialog(
              'The Contact Number is Used. Please Use Another Contact Number.');
          await db.close();
          return;
        }

        final updatedProfile = CustomerProfile(
          id: widget.customerProfile.id,
          customerName: customerName,
          contactNumber: contactNumber,
        );

        await collection.update(
          mongo.where.id(widget.customerProfile.id),
          updatedProfile.toJson(),
        );

        await db.close();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CustomerProfilesScreen(
              email: widget.email,
              user: widget.user,
              shopName: widget.shopName,
              department: widget.department,
            ),
          ),
        );
        _showSuccessDialog('Customer Profile has been Updated Successfully.');
      } catch (e) {
        _showErrorDialog('Failed to update customer profile. Error: $e');
      }
    }
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Edit Customer Profile Details',
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
                builder: (context) => CustomerProfilesScreen(
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
                    _customerNameController,
                    'Customer Name',
                    'Enter Customer Name',
                    Icon(Icons.person, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _contactNumberController,
                    'Contact Number',
                    'Enter Contact Number',
                    Icon(Icons.phone, color: Colors.black),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateCustomerProfile,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Update Customer Profile Information',
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
      TextEditingController controller, String label, String hint, Icon icon,
      {TextInputType keyboardType = TextInputType.text}) {
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
        prefixIcon: icon,
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }
}
