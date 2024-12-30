import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'inventory_log_screen.dart';

class AddInventoryLogScreen extends StatefulWidget {
  final String email;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const AddInventoryLogScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _AddInventoryLogScreenState createState() => _AddInventoryLogScreenState();
}

class _AddInventoryLogScreenState extends State<AddInventoryLogScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedProductName;
  String? _selectedTransactionType;
  List<String> _productNames = [];
  List<String> _transactionTypes = ['Loss', 'Return', 'Adjustment', 'Wastage', 'Donation', 'Defective', 'Other'];
  TextEditingController _quantityController = TextEditingController();
  TextEditingController _otherTransactionTypeController = TextEditingController();

  int _availableQuantity = 0; // To store the available quantity
  String _quantityStatus = ""; // To store the status message

  @override
  void initState() {
    super.initState();
    _fetchProductNames();
  }

  Future<void> _fetchProductNames() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('product');
      final productList = await collection.find().toList();

      await db.close();

      setState(() {
        _productNames = productList.map((e) => e['productName'].toString()).toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch product names. Error: $e');
    }
  }

  Future<void> _fetchAvailableQuantity() async {
    if (_selectedProductName == null) return;

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final inventoryCollection = db.collection('inventoryLog');
      final logs = await inventoryCollection.find({'productName': _selectedProductName}).toList();

      await db.close();

      int availableQuantity = 0;
      for (var log in logs) {
        if (log['transactionType'] == 'Purchase') {
          availableQuantity += (log['productQuantity'] as num).toInt();
        } else {
          availableQuantity -= (log['productQuantity'] as num).toInt();
        }
      }

      setState(() {
        _availableQuantity = availableQuantity;
        _quantityStatus = _availableQuantity == 0 ? "Stock Out" : "";
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch available quantity. Error: $e');
    }
  }

  Future<void> _addInventoryLog() async {
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    final transactionType = _selectedTransactionType == 'Other'
        ? _otherTransactionTypeController.text
        : _selectedTransactionType;

    if (_selectedProductName == null || quantity <= 0 || transactionType == null) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    if (quantity > _availableQuantity) {
      setState(() {
        _quantityStatus = "Over Stock";
      });
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('inventoryLog');

      // Insert new inventory log data
      await collection.insertOne({
        'productName': _selectedProductName,
        'productQuantity': quantity,
        'transactionType': transactionType,
        'logDateTime': formatOrderDate(DateTime.now()),
      });

      await db.close();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => InventoryLogScreen(
            department: widget.department,
            email: widget.email,
            user: widget.user,
            shopName: widget.shopName,
          ),
        ),
      );
      _showSuccessDialog('Inventory Log has been added successfully.');
    } catch (e) {
      _showErrorDialog('Failed to add inventory log. Error: $e');
    }
  }

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
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
          'Add Inventory Log',
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
                builder: (context) => InventoryLogScreen(
                  department: widget.department,
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
                  _buildProductDropdown(),
                  SizedBox(height: 20),
                  _buildTextField(
                    _quantityController,
                    'Product Quantity',
                    'Enter product quantity',
                    Icon(Icons.format_list_numbered, color: Colors.black),
                  ),
                  SizedBox(width: 5),
                  if (_quantityStatus.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 40.0),
                      child: Text(
                        _quantityStatus,
                        style: TextStyle(
                          color: _quantityStatus == "Over Stock"
                              ? Colors.blue
                              : Colors.black,
                          fontSize: 16,
                          fontFamily: 'RobotoCondensed',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTransactionTypeDropdown(),
                  SizedBox(height: 20),
                  if (_selectedTransactionType == 'Other')
                    _buildTextField(
                      _otherTransactionTypeController,
                      'Specify Transaction Type',
                      'Enter transaction type',
                      Icon(Icons.text_fields, color: Colors.black),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addInventoryLog,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Add Inventory Log',
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

  Widget _buildProductDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedProductName,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Product Name',
        hintText: 'Select product name',
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
        prefixIcon: Icon(Icons.shopping_cart, color: Colors.black),
      ),
      items: _productNames.map((name) {
        return DropdownMenuItem<String>(
          value: name,
          child: Text(
            name,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedProductName = newValue;
          _fetchAvailableQuantity(); // Fetch the available quantity when a product is selected
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a product name';
        }
        return null;
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, String hint, Icon icon) {
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
      onChanged: (value) {
        final quantity = int.tryParse(value) ?? 0;
        setState(() {
          if (_availableQuantity == 0) {
            _quantityStatus = "Stock Out";
          } else if (quantity > _availableQuantity) {
            _quantityStatus = "Over Stock";
          } else {
            _quantityStatus = "";
          }
        });
      },
    );
  }

  Widget _buildTransactionTypeDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTransactionType,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Transaction Type',
        hintText: 'Select the transaction type',
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
      items: _transactionTypes.map((type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(
            type,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          _selectedTransactionType = newValue;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a transaction type';
        }
        return null;
      },
    );
  }
}
