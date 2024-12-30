import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/sales_model.dart';
import '../../home_screen.dart';

class SalesManagementScreen extends StatefulWidget {
  final String email;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const SalesManagementScreen({
    Key? key,
    required this.email,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _SalesManagementScreenState createState() => _SalesManagementScreenState();
}

class _SalesManagementScreenState extends State<SalesManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _contactNumberController = TextEditingController();
  final TextEditingController _totalPriceOfAllProductsController = TextEditingController();

  String? _selectedPaymentMethodName;
  String? _contactNumberError;

  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _productWidgets = [];
  double _totalPriceOfAllProducts = 0.0;

  int _availableQuantity = 0;
  String _quantityStatus = "";

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _fetchPaymentMethods();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _contactNumberController.dispose();
    _totalPriceOfAllProductsController.dispose();
    super.dispose();
  }

  Future<void> _fetchCustomerData(String contactNumber) async {
    final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
    final db = mongo.Db('mongodb://localhost:27017/$dbName');
    await db.open();

    final collection = db.collection('customerProfiles');
    final customer = await collection.findOne({'contactNumber': contactNumber});

    await db.close();

    if (customer != null) {
      setState(() {
        _customerNameController.text = customer['customerName'];
        _contactNumberError = null;
      });
    } else {
      setState(() {
        _customerNameController.clear();
        _contactNumberError = 'For the Contact Number, There is no Customer Profile Exist. Please Create a Customer Profile for This Contact Number.';
      });
    }
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
            'pricePerProduct': (product['pricePerProduct'] as num).toDouble() * 1.2, // Apply the 1.2 multiplier
          };
        }).toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch products. Error: $e');
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('paymentMethod');
      final paymentMethodsList = await collection.find().toList();

      await db.close();

      setState(() {
        _paymentMethods = paymentMethodsList.map((method) {
          return {
            'paymentMethodName': method['paymentMethodName'] as String,
          };
        }).toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch payment methods. Error: $e');
    }
  }

  void _calculateTotalPriceOfAllProducts() {
    _totalPriceOfAllProducts = 0.0; 
    for (var product in _productWidgets) {
      final pricePerProduct = product['pricePerProduct'] as double;
      final quantity = product['productQuantity'] as int;
      final totalPrice = pricePerProduct * quantity;
      _totalPriceOfAllProducts += totalPrice;

      }
    _totalPriceOfAllProductsController.text = _totalPriceOfAllProducts.toStringAsFixed(2);
  }

  void _addProduct() {
    setState(() {
      _productWidgets.add({
        'productName': '',
        'pricePerProduct': 0.0,
        'totalPrice': 0.0,
      });
    });
  }

  void _removeProduct(Map<String, dynamic> product) {
    setState(() {
      _productWidgets.remove(product);
      _calculateTotalPriceOfAllProducts();
    });
  }

  Widget _buildProductEntryWidget(int index) {
    String? selectedProductName = _productWidgets[index]['productName'];
    double pricePerProduct = _productWidgets[index]['pricePerProduct'] ?? 0.0;
    int productQuantity = _productWidgets[index]['productQuantity'] ?? 0;

    // Initialize controllers with current values
    final productQuantityController = TextEditingController(text: productQuantity > 0 ? productQuantity.toString() : '');
    final pricePerProductController = TextEditingController(text: pricePerProduct.toStringAsFixed(2));
    final totalPriceController = TextEditingController(text: (_productWidgets[index]['totalPrice'] ?? 0.0).toStringAsFixed(2));

    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Column(
          children: [
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
                border: _buildBorder(),
                enabledBorder: _buildBorder(),
                focusedBorder: _buildBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                prefixIcon: Icon(Icons.shopping_cart, color: Colors.black),
              ),
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              value: _products.any((product) => product['productName'] == selectedProductName) 
                ? selectedProductName 
                : null,  // Set to null if no matching value is found
              items: _products.map((product) {
                return DropdownMenuItem<String>(
                  value: product['productName'] as String,
                  child: Text(product['productName'] as String),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedProductName = value;
                  final selectedProduct = _products.firstWhere((product) => product['productName'] == value);
                  pricePerProduct = selectedProduct['pricePerProduct'];
                  pricePerProductController.text = pricePerProduct.toStringAsFixed(2);

                  // Ensure the quantity is preserved
                  productQuantity = _productWidgets[index]['productQuantity'] ?? 0;
                  productQuantityController.text = productQuantity > 0 ? productQuantity.toString() : '';

                  // Update the product details in the list
                  _productWidgets[index] = {
                    'productName': selectedProductName,
                    'productQuantity': productQuantity,
                    'pricePerProduct': pricePerProduct,
                    'totalPrice': productQuantity * pricePerProduct,
                  };
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
              productQuantityController,
              'Product Quantity',
              'Enter Product Quantity',
              Icon(Icons.format_list_numbered, color: Colors.black),
              keyboardType: TextInputType.number,
              onFieldSubmitted: (value) async {
                productQuantity = int.tryParse(value) ?? 0;
                final availableQuantity = await _calculateAvailableQuantity(selectedProductName);

                if (availableQuantity == 0) {
                  setState(() {
                    _quantityStatus = "Stock Out";
                  });
                } else if (productQuantity > availableQuantity) {
                  setState(() {
                    _quantityStatus = "Over Stock";
                  });
                } else {
                  setState(() {
                    _quantityStatus = "";
                  });
                }

                setState(() {
                  final totalPrice = productQuantity * pricePerProduct;
                  totalPriceController.text = totalPrice.toStringAsFixed(2);

                  // Update the product details in the list
                  _productWidgets[index] = {
                    'productName': selectedProductName,
                    'productQuantity': productQuantity,
                    'pricePerProduct': pricePerProduct,
                    'totalPrice': totalPrice,
                  };

                  _calculateTotalPriceOfAllProducts();
                });
              },
              textEnabled: true,
            ),
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
            _buildTextField(
              pricePerProductController,
              'Price Per Product',
              'Price Per Product',
              Icon(Icons.attach_money, color: Colors.black),
              keyboardType: TextInputType.number,
              textEnabled: false,
            ),
            SizedBox(height: 20),
            _buildTextField(
              totalPriceController,
              'Total Price',
              'Total Price',
              Icon(Icons.attach_money, color: Colors.black),
              keyboardType: TextInputType.number,
              textEnabled: false,
            ),
            SizedBox(height: 20),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _removeProduct(_productWidgets[index]);
              },
            ),
            SizedBox(height: 20),
          ],
        );
      },
    );
  }

  Future<int> _calculateAvailableQuantity(String? productName) async {
    if (productName == null) return 0; // Return 0 if productName is null

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final inventoryCollection = db.collection('inventoryLog');
      final logs = await inventoryCollection.find({'productName': productName}).toList();

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

      return availableQuantity;
    } catch (e) {
      _showErrorDialog('Failed to fetch available quantity. Error: $e');
      return 0; // Return 0 in case of an error
    }
  }

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _addSales() async {
    final customerName = _customerNameController.text;
    final contactNumber = _contactNumberController.text;
    final paymentMethodName = _selectedPaymentMethodName;

    if (customerName.isEmpty || contactNumber.isEmpty || paymentMethodName == null || _productWidgets.isEmpty) {
      _showErrorDialog('Please fill out all required fields.');
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final salesCollection = db.collection('sales');
      final inventoryLogCollection = db.collection('inventoryLog');
      final paymentCollection = db.collection('payment');

      for (var product in _productWidgets) {
        final newSale = Sales(
          id: mongo.ObjectId(),
          customerName: customerName,
          contactNumber: contactNumber,
          productName: product['productName'],
          productQuantity: product['productQuantity'],
          pricePerProduct: product['pricePerProduct'],
          totalPrice: product['totalPrice'],
          paymentMethodName: paymentMethodName,
          totalPriceOfAllProducts: _totalPriceOfAllProducts,
          salesDateTime: DateTime.now(),
        );

        await salesCollection.insertOne(newSale.toJson());

        await inventoryLogCollection.insertOne({
          'productName': product['productName'],
          'productQuantity': product['productQuantity'],
          'transactionType': 'Sales',
          'logDateTime': formatOrderDate(DateTime.now()),
        });

        await paymentCollection.insertOne({
          'paymentType': 'Customer',
          'name': customerName,
          'totalPrice': product['totalPrice'],
          'paymentMethodName': paymentMethodName,
          'paymentDateTime': formatOrderDate(DateTime.now()),
        });
      }

      await db.close();

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

      _showSuccessDialog('Sales information has been inserted successfully.');
    } catch (e) {
      _showErrorDialog('Failed to add sales information. Error: $e');
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

  OutlineInputBorder _buildBorder() {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide(
        color: Colors.blue,
        width: 3.0,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    Icon icon, {
    TextInputType keyboardType = TextInputType.text,
    required bool textEnabled,
    Function(String)? onChanged,
    Function(String)? onFieldSubmitted,
    String? errorText,
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
        errorText: errorText,
        errorStyle: TextStyle(
          fontSize: 14,
          fontFamily: 'RobotoCondensed',
          fontWeight: FontWeight.bold,
          color: Colors.red,
        ),
        border: _buildBorder(),
        enabledBorder: _buildBorder(),
        focusedBorder: _buildBorder(),
        errorBorder: _buildBorder(),
        focusedErrorBorder: _buildBorder(),
        disabledBorder: _buildBorder(),
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
      enabled: textEnabled,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Enter Sales Details',
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
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 20),
                  _buildTextField(
                    _contactNumberController,
                    'Contact Number',
                    'Enter Contact Number',
                    Icon(Icons.phone, color: Colors.black),
                    keyboardType: TextInputType.phone,
                    onFieldSubmitted: (value) => _fetchCustomerData(value),
                    errorText: _contactNumberError,
                    textEnabled: true,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _customerNameController,
                    'Customer Name',
                    'Customer Name',
                    Icon(Icons.person, color: Colors.black),
                    textEnabled: false,
                  ),
                  SizedBox(height: 20),
                  ..._productWidgets.asMap().entries.map((entry) {
                    int index = entry.key;
                    return _buildProductEntryWidget(index);
                  }).toList(),
                  SizedBox(height: 20),
                  _buildTextField(
                    _totalPriceOfAllProductsController,
                    'Total Price of All Products',
                    'Total Price of All Products',
                    Icon(Icons.attach_money, color: Colors.black),
                    keyboardType: TextInputType.number,
                    textEnabled: false,
                  ),
                  SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Payment Method Name',
                      hintText: 'Select Payment Method Name',
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
                      border: _buildBorder(),
                      enabledBorder: _buildBorder(),
                      focusedBorder: _buildBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      prefixIcon: Icon(Icons.payment, color: Colors.black),
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontFamily: 'RobotoCondensed',
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    value: _selectedPaymentMethodName,
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem<String>(
                        value: method['paymentMethodName'] as String,
                        child: Text(method['paymentMethodName'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethodName = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a Payment Method Name';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addProduct,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Add Product',
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
                        Color.fromARGB(255, 48, 244, 4),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addSales,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Add Sales Information',
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
}
