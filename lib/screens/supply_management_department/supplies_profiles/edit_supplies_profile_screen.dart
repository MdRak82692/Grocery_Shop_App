import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'supplies_profile_list_screen.dart';
import '../../../models/supplies_profile_model.dart';

class EditSuppliesProfileScreen extends StatefulWidget {
  final String email;
  final SuppliesProfile suppliesProfile;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const EditSuppliesProfileScreen({
    Key? key,
    required this.email,
    required this.suppliesProfile,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _EditSuppliesProfileScreenState createState() =>
      _EditSuppliesProfileScreenState();
}

class _EditSuppliesProfileScreenState extends State<EditSuppliesProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _suppliesNameController;
  late TextEditingController _contactNumberController;
  late TextEditingController _supplyCompanyNameController;
  String? _selectedProduct;
  List<String> _products = [];

  @override
  void initState() {
    super.initState();
    _suppliesNameController =
        TextEditingController(text: widget.suppliesProfile.suppliesName);
    _contactNumberController =
        TextEditingController(text: widget.suppliesProfile.contactNumber);
    _supplyCompanyNameController =
        TextEditingController(text: widget.suppliesProfile.supplyCompanyName);
    _selectedProduct = widget.suppliesProfile.productName;
    _fetchProducts();
  }

  @override
  void dispose() {
    _suppliesNameController.dispose();
    _contactNumberController.dispose();
    _supplyCompanyNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchProducts() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('product');
      final productList = await collection.find().toList();

      await db.close();

      setState(() {
        _products = productList
            .map((product) => product['productName'] as String)
            .toList();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _updateSuppliesProfile() async {
    if (_formKey.currentState!.validate()) {
      final suppliesName = _suppliesNameController.text;
      final contactNumber = _contactNumberController.text;
      final supplyCompanyName = _supplyCompanyNameController.text;

      try {
        final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
        final db = mongo.Db('mongodb://localhost:27017/$dbName');
        await db.open();

        final collection = db.collection('suppliesProfiles');

        // Check if the new contact number already exists in another profile
        final existingProfile = await collection.findOne(mongo.where
            .eq('contactNumber', contactNumber)
            .ne('_id', widget.suppliesProfile.id));
        if (existingProfile != null) {
          _showErrorDialog(
              'The Contact Number already exists. Please enter a different Contact Number.');
          await db.close();
          return;
        }

        final updatedProfile = SuppliesProfile(
          id: widget.suppliesProfile.id,
          suppliesName: suppliesName,
          contactNumber: contactNumber,
          productName: _selectedProduct!,
          supplyCompanyName: supplyCompanyName,
        );

        await collection.update(
          mongo.where.id(widget.suppliesProfile.id),
          updatedProfile.toJson(),
        );

        await db.close();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuppliesProfileListScreen(
              email: widget.email,
              user: widget.user,
              shopName: widget.shopName,
              department: widget.department,
            ),
          ),
        );
        _showSuccessDialog('Suppliers Profile has been Updated Successfully.');
      } catch (e) {
        _showErrorDialog('Failed to update suppliers profile. Error: $e');
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
          'Edit Suppliers Profile Details',
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
                builder: (context) => SuppliesProfileListScreen(
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
                    _suppliesNameController,
                    'Suppliers Name',
                    'Enter Suppliers Name',
                    Icon(Icons.business, color: Colors.black),
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
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Product Name',
                      hintText: 'Select Product Name',
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
                      prefixIcon: Icon(Icons.category, color: Colors.black),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'RobotoCondensed',
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    value: _selectedProduct,
                    items: _products
                        .map((product) => DropdownMenuItem<String>(
                              value: product,
                              child: Text(product),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a Product Name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _supplyCompanyNameController,
                    'Supply Company Name',
                    'Enter Supply Company Name',
                    Icon(Icons.location_city, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updateSuppliesProfile,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Update Suppliers Profile Information',
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
