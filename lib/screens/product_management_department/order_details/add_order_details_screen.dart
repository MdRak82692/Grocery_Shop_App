import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/order_details_model.dart';
import 'order_details_list_screen.dart';

class AddOrderDetailsScreen extends StatefulWidget {
  final String email;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const AddOrderDetailsScreen({
    Key? key,
    required this.email,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _AddOrderDetailsScreenState createState() => _AddOrderDetailsScreenState();
}

class _AddOrderDetailsScreenState extends State<AddOrderDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _orderIdController = TextEditingController();
  final TextEditingController _productQuantityController =
      TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _pricePerProductController =
      TextEditingController();

  String? _selectedProduct;
  String? _categoryName;
  double? _pricePerProduct;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _productQuantityController.dispose();
    _categoryNameController.dispose();
    _pricePerProductController.dispose();
    super.dispose();
  }

  void _showSuccessDialog(String message) {
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

  Future<void> _fetchProducts() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('product');
      final productList = await collection.find().toList();

      await db.close();

      setState(() {
        _products = productList.map((product) {
          return {
            'productName': product['productName'] as String,
            'categoryName': product['categoryName'] as String,
            'pricePerProduct': product['pricePerProduct'].toDouble(),
          };
        }).toList();
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  Future<void> _addOrderDetails() async {
    final int orderId = int.tryParse(_orderIdController.text) ?? 0;
    final int productQuantity =
        int.tryParse(_productQuantityController.text) ?? 0;

    if (orderId <= 0 ||
        _selectedProduct == null ||
        productQuantity <= 0 ||
        _categoryName == null ||
        _pricePerProduct == null) {
      _showErrorDialog('Please fill out all fields.');
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('orderDetails');

      // Check if the order ID already exists
      final existingOrder =
          await collection.findOne(mongo.where.eq('orderId', orderId));
      if (existingOrder != null) {
        _showErrorDialog('The Order ID is Exist. Please Use New Order ID.');
        await db.close();
        return;
      }

      // Insert the new order details
      final newOrderDetails = OrderDetails(
        id: mongo.ObjectId(),
        orderId: orderId,
        productName: _selectedProduct!,
        categoryName: _categoryName!,
        productQuantity: productQuantity,
        pricePerProduct: _pricePerProduct!,
      );

      await collection.insertOne(newOrderDetails.toJson());

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsListScreen(
            email: widget.email,
            user: widget.user,
            shopName: widget.shopName,
            department: widget.department,
          ),
        ),
      );
      _showSuccessDialog('Order Details has been added successfully.');
    } catch (e) {
      _showErrorDialog('Failed to add order details. Error: $e');
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
          'Enter Order Details',
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
                builder: (context) => OrderDetailsListScreen(
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
                    controller: _orderIdController,
                    label: 'Order ID',
                    hint: 'Enter Order ID',
                    icon: Icon(Icons.confirmation_number, color: Colors.black),
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
                      prefixIcon:
                          Icon(Icons.shopping_cart, color: Colors.black),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'RobotoCondensed',
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    value: _selectedProduct,
                    items: _products.map((product) {
                      return DropdownMenuItem<String>(
                        value: product['productName'] as String,
                        child: Text(product['productName'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                        final selectedProduct = _products.firstWhere(
                            (product) => product['productName'] == value);
                        _categoryName =
                            selectedProduct['categoryName'] as String;
                        _pricePerProduct =
                            selectedProduct['pricePerProduct'] as double;

                        // Update the text controllers with the new values
                        _categoryNameController.text = _categoryName!;
                        _pricePerProductController.text =
                            _pricePerProduct!.toStringAsFixed(2);
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
                    controller: _categoryNameController,
                    label: 'Category Name',
                    hint: 'Select Category Name',
                    icon: Icon(Icons.category, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _productQuantityController,
                    label: 'Product Quantity',
                    hint: 'Enter Product Quantity',
                    icon: Icon(Icons.format_list_numbered, color: Colors.black),
                    keyboardType: TextInputType.number,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _pricePerProductController,
                    label: 'Price Per Product',
                    hint: '0.00',
                    icon: Icon(Icons.attach_money, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addOrderDetails,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Add Order Details Information',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required Icon icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
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
