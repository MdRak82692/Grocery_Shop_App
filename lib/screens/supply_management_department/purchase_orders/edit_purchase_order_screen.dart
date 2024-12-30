import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/purchase_order_model.dart';
import 'purchase_orders_screen.dart';

class EditPurchaseOrderScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;
  final PurchaseOrder purchaseOrder;

  const EditPurchaseOrderScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
    required this.purchaseOrder,
  }) : super(key: key);

  @override
  _EditPurchaseOrderScreenState createState() =>
      _EditPurchaseOrderScreenState();
}

class _EditPurchaseOrderScreenState extends State<EditPurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _orderIdController;
  late TextEditingController _totalPriceController;
  late TextEditingController _productNameController; // New field for product name
  late String _selectedSuppliesName;
  late String _selectedPaymentMethod;
  late String _selectedStatus;

  bool _isSuppliesNameEditable = true;
  bool _isPaymentMethodEditable = true;

  List<String> _filteredSuppliesNames = [];
  List<String> _paymentMethods = [];
  String? _selectedOrderId;

  @override
  void initState() {
    super.initState();
    _orderIdController =
        TextEditingController(text: widget.purchaseOrder.orderId.toString());
    _totalPriceController =
        TextEditingController(text: widget.purchaseOrder.totalPrice.toString());
    _productNameController =
        TextEditingController(text: widget.purchaseOrder.productName); // Initialize with product name
    _selectedSuppliesName = widget.purchaseOrder.suppliesName;
    _selectedPaymentMethod = widget.purchaseOrder.paymentMethodName;
    _selectedStatus = widget.purchaseOrder.status;

    // Fetch and filter the necessary data
    _fetchAndFilterSuppliesNames(widget.purchaseOrder.orderId.toString());
    _fetchPaymentMethods();
  }

  @override
  void dispose() {
    _orderIdController.dispose();
    _totalPriceController.dispose();
    _productNameController.dispose(); // Dispose the new controller
    super.dispose();
  }

  Future<void> _fetchAndFilterSuppliesNames(String orderId) async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final orderDetailsCollection = db.collection('orderDetails');
      final orderDetails = await orderDetailsCollection
          .findOne(mongo.where.eq('orderId', int.parse(orderId)));
      final String productNameFromOrderDetails =
          orderDetails?['productName'] ?? '';

      final suppliesProfilesCollection = db.collection('suppliesProfiles');
      final suppliesProfiles = await suppliesProfilesCollection.find().toList();

      setState(() {
        _filteredSuppliesNames = suppliesProfiles
            .where((supply) =>
                supply['productName'] == productNameFromOrderDetails)
            .map((supply) => supply['suppliesName'].toString())
            .toList();

        _productNameController.text = productNameFromOrderDetails; // Set the product name

        // Set the selected supplies name if only one match is found
        if (_filteredSuppliesNames.length == 1) {
          _selectedSuppliesName = _filteredSuppliesNames.first;
        }
      });

      await db.close();
    } catch (e) {
      _showErrorDialog('Failed to fetch supplies names. Error: $e');
    }
  }

  Future<void> _fetchPaymentMethods() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();
      final collection = db.collection('paymentMethod');
      final methods = await collection.find().toList();
      await db.close();

      setState(() {
        _paymentMethods = methods
            .map((method) => method['paymentMethodName'].toString())
            .toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch payment methods. Error: $e');
    }
  }

  Future<void> _calculateTotalPrice(String orderId) async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();
      final collection = db.collection('orderDetails');
      final order = await collection
          .findOne(mongo.where.eq('orderId', int.parse(orderId)));

      if (order != null) {
        final int productQuantity = order['productQuantity'];
        final double pricePerProduct = order['pricePerProduct'];

        final double totalPrice = productQuantity * pricePerProduct;

        setState(() {
          _totalPriceController.text = totalPrice.toStringAsFixed(2);
        });
      }

      await db.close();
    } catch (e) {
      _showErrorDialog('Failed to calculate total price. Error: $e');
    }
  }

  Future<void> _updatePurchaseOrder() async {
    // Ensure that _selectedOrderId is not null and totalPriceController is not empty
    if (_selectedOrderId == null || _totalPriceController.text.isEmpty) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    // Convert _selectedOrderId to an int safely
    final orderId = int.tryParse(_selectedOrderId!);
    final totalPrice = double.tryParse(_totalPriceController.text);

    if (orderId == null) {
      _showErrorDialog('Invalid Order ID.');
      return;
    }

    if (totalPrice == null || totalPrice <= 0) {
      _showErrorDialog('Invalid Total Price.');
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('purchaseOrders');

      // Update the purchase order in the database
      await collection.update(
        mongo.where.id(widget.purchaseOrder.id),
        mongo.modify
            .set('orderId', orderId)
            .set('suppliesName', _selectedSuppliesName)
            .set('productName', _productNameController.text) // Update product name
            .set('totalPrice', totalPrice) // Ensure correct total price is set
            .set('paymentMethodName', _selectedPaymentMethod)
            .set('status', _selectedStatus)
            .set('orderDateTime', formatOrderDate(DateTime.now())),
      );

      await db.close();

      // Navigate back to the Purchase Orders Screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PurchaseOrdersScreen(
            email: widget.email,
            user: widget.user,
            shopName: widget.shopName,
            department: widget.department,
          ),
        ),
      );

      _showSuccessDialog('Purchase Order has been updated successfully.');
    } catch (e) {
      _showErrorDialog('Failed to update purchase order. Error: $e');
    }
  }

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
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

  Widget _buildTextField(
      TextEditingController controller, String label, String hint, Icon icon) {
    return TextFormField(
      controller: controller,
      readOnly: label == 'Order ID' || label == 'Product Name', // Disable editing for Order ID and Product Name
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text(
          'Edit Purchase Order Details',
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
                builder: (context) => PurchaseOrdersScreen(
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
                  _buildOrderIdDropdown(),
                  SizedBox(height: 20),
                  _buildTextField(
                    _productNameController,
                    'Product Name',
                    'Product Name',
                    Icon(Icons.shopping_cart, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildSuppliesDropdown(),
                  SizedBox(height: 20),
                  _buildTextField(
                    _totalPriceController,
                    'Total Price',
                    'Enter total price',
                    Icon(Icons.attach_money, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  _buildPaymentMethodDropdown(),
                  SizedBox(height: 20),
                  _buildStatusDropdown(),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _updatePurchaseOrder,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Update Purchase Order Information',
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

  Widget _buildOrderIdDropdown() {
    return DropdownButtonFormField<String>(
      value: widget.purchaseOrder.orderId.toString(),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Order ID',
        hintText: 'Select the Order ID',
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
        prefixIcon: Icon(Icons.confirmation_number, color: Colors.black),
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedOrderId = newValue;
            _orderIdController.text = newValue;
            _fetchAndFilterSuppliesNames(newValue);
            _calculateTotalPrice(newValue);
          });
        }
      },
      items: [
        DropdownMenuItem<String>(
          value: widget.purchaseOrder.orderId.toString(),
          child: Text(
            widget.purchaseOrder.orderId.toString(),
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuppliesDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedSuppliesName,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Supplies Name',
        hintText: 'Select the Supplies Name',
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
        prefixIcon: Icon(Icons.business, color: Colors.black),
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      onChanged: _isSuppliesNameEditable
          ? (String? newValue) {
              setState(() {
                _selectedSuppliesName = newValue!;
              });
            }
          : null,
      items:
          _filteredSuppliesNames.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedPaymentMethod,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Payment Method',
        hintText: 'Select the Payment Method',
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
        prefixIcon: Icon(Icons.payment, color: Colors.black),
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      onChanged: _isPaymentMethodEditable
          ? (String? newValue) {
              setState(() {
                _selectedPaymentMethod = newValue!;
              });
            }
          : null,
      items: _paymentMethods.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Status',
        hintText: 'Select the Status',
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
        prefixIcon: Icon(Icons.assignment_turned_in, color: Colors.black),
      ),
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black),
      onChanged: (String? newValue) {
        setState(() {
          _selectedStatus = newValue!;
        });
      },
      items: <String>[
        'Pending',
      ].map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        );
      }).toList(),
    );
  }
}
