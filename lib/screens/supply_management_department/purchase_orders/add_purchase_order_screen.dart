import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/standalone.dart' as tz;
import 'purchase_orders_screen.dart';

class AddPurchaseOrderScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const AddPurchaseOrderScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _AddPurchaseOrderScreenState createState() => _AddPurchaseOrderScreenState();
}

class _AddPurchaseOrderScreenState extends State<AddPurchaseOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _totalPriceController = TextEditingController();
  String? _selectedOrderId;
  String? _selectedSuppliesName;
  String? _selectedPaymentMethod;
  String? _selectedStatus;
  String? _productName; 

  List<String> _orderIds = [];
  List<String> _filteredSuppliesNames = [];
  List<String> _paymentMethods = [];
  List<String> _statusOptions = [];

  bool _isSuppliesNameEditable = true;
  bool _isPaymentMethodEditable = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderDetails();
    _fetchPaymentMethods();
    tz.initializeTimeZones();
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    super.dispose();
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final orderDetailsCollection = db.collection('orderDetails');
      final orderDetails = await orderDetailsCollection.find().toList();
      final orderIdsFromOrderDetails =
          orderDetails.map((order) => order['orderId'].toString()).toList();

      final purchaseOrdersCollection = db.collection('purchaseOrders');
      final purchaseOrders = await purchaseOrdersCollection.find().toList();

      // Create a map of orderId to status
      final orderStatuses = {
        for (var order in purchaseOrders)
          order['orderId'].toString(): order['status']
      };

      await db.close();

      setState(() {
        _orderIds = orderIdsFromOrderDetails.where((orderId) {
          // Filter out orders with status 'Complete' or 'Cancelled'
          final status = orderStatuses[orderId];
          return status != 'Complete' && status != 'Cancelled';
        }).toList();
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch order details. Error: $e');
    }
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

        _productName = productNameFromOrderDetails; // Set product name

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

  Future<void> _fetchOrderStatusAndUpdateDropdown(String orderId) async {
    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();
      final collection = db.collection('purchaseOrders');

      // Fetch the order based on orderId
      final selectedOrder = await collection
          .findOne(mongo.where.eq('orderId', int.parse(orderId)));

      await db.close();

      setState(() {
        _statusOptions.clear();
        _selectedStatus = null;

        if (selectedOrder != null) {
          final status = selectedOrder['status'];

          if (status == 'Pending') {
            // Set the suppliesName and paymentMethodName from the order data
            _selectedSuppliesName = selectedOrder['suppliesName']?.trim();
            _selectedPaymentMethod = selectedOrder['paymentMethodName']?.trim();

            // Ensure the selected supplies name is in the filtered list
            if (_selectedSuppliesName != null &&
                !_filteredSuppliesNames.contains(_selectedSuppliesName)) {
              _filteredSuppliesNames.add(_selectedSuppliesName!);
            }

            // Prevent the user from changing the suppliesName and paymentMethodName
            _isSuppliesNameEditable = false;
            _isPaymentMethodEditable = false;

            // Provide options for status change
            _statusOptions = ['Complete', 'Cancelled'];
          } else if (status == null || status.isEmpty) {
            _statusOptions = ['Pending'];
          }
        } else {
          // If the order ID does not exist in the collection
          _statusOptions = ['Pending'];
        }
      });
    } catch (e) {
      _showErrorDialog('Failed to fetch purchase orders. Error: $e');
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

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Future<void> _addPurchaseOrder() async {
    if (_selectedOrderId == null ||
        _totalPriceController.text.isEmpty ||
        _selectedSuppliesName == null ||
        _selectedPaymentMethod == null ||
        _selectedStatus == null) {
      _showErrorDialog('Please fill in all fields.');
      return;
    }

    final totalPrice = double.tryParse(_totalPriceController.text);
    if (totalPrice == null) {
      _showErrorDialog('Please enter a valid total price.');
      return;
    }

    try {
      final dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();
      final collection = db.collection('purchaseOrders');

      // Insert the purchase order
      await collection.insertOne({
        'orderId': int.parse(_selectedOrderId!),
        'suppliesName': _selectedSuppliesName,
        'productName': _productName, // Insert product name
        'totalPrice': totalPrice,
        'paymentMethodName': _selectedPaymentMethod,
        'status': _selectedStatus,
        'orderDateTime': formatOrderDate(DateTime.now()),
      });

      // If the status is "Complete", insert data into inventoryLog and paymentLog collections
      if (_selectedStatus == 'Complete') {
        await _insertInventoryLog(db);
        await _insertPaymentLog(db, totalPrice);
      }

      await db.close();

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
      _showSuccessDialog('Purchase Order has been Insert Successfully.');
    } catch (e) {
      _showErrorDialog('Failed to add purchase order. Error: $e');
    }
  }

  Future<void> _insertInventoryLog(mongo.Db db) async {
    final orderDetailsCollection = db.collection('orderDetails');
    final orderDetails = await orderDetailsCollection
        .findOne(mongo.where.eq('orderId', int.parse(_selectedOrderId!)));

    if (orderDetails != null) {
      final inventoryLogCollection = db.collection('inventoryLog');

      // Convert the current time to Bangladesh time zone
      final now = tz.TZDateTime.now(tz.getLocation('Asia/Dhaka'));

      await inventoryLogCollection.insertOne({
        'productName': orderDetails['productName'],
        'productQuantity': orderDetails['productQuantity'],
        'transactionType': 'Purchase',
        'logDateTime': formatOrderDate(now),
      });
    }
  }

  Future<void> _insertPaymentLog(mongo.Db db, double totalPrice) async {
    final paymentLogCollection = db.collection('payment');

    // Convert the current time to Bangladesh time zone
    final now = tz.TZDateTime.now(tz.getLocation('Asia/Dhaka'));

    await paymentLogCollection.insertOne({
      'paymentType': 'Supplier',
      'name': _selectedSuppliesName,
      'totalPrice': totalPrice,
      'paymentMethodName': _selectedPaymentMethod,
      'paymentDateTime': formatOrderDate(now),
    });
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
          'Enter Purchase Order Details',
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
                  _buildProductNameField(), // New Product Name field
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
                  if (_statusOptions.isNotEmpty) ...[
                    SizedBox(height: 20),
                    _buildStatusDropdown(),
                  ],
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _addPurchaseOrder,
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                      child: Text(
                        'Add Purchase Order Information',
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
      TextEditingController controller, String label, String hint, Icon icon) {
    return TextFormField(
      controller: controller,
      keyboardType: label == 'Total Price' || label == 'Order ID'
          ? TextInputType.number
          : TextInputType.text,
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

  Widget _buildOrderIdDropdown() {
    return DropdownButtonFormField<String>(
      value: _orderIds.contains(_selectedOrderId) ? _selectedOrderId : null,
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
        setState(() {
          _selectedOrderId = newValue!;
          _calculateTotalPrice(_selectedOrderId!);
          _fetchOrderStatusAndUpdateDropdown(_selectedOrderId!);
          _fetchAndFilterSuppliesNames(_selectedOrderId!);
        });
      },
      items: _orderIds.map<DropdownMenuItem<String>>((String value) {
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

  Widget _buildProductNameField() { // New Product Name field
    return TextFormField(
      controller: TextEditingController(text: _productName),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Product Name',
        hintText: 'Product Name',
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
      style: TextStyle(
        fontSize: 18,
        fontFamily: 'RobotoCondensed',
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSuppliesDropdown() {
    return DropdownButtonFormField<String>(
      value: _filteredSuppliesNames.contains(_selectedSuppliesName)
          ? _selectedSuppliesName
          : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        labelText: 'Suppliers Name',
        hintText: 'Select the Suppliers Name',
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
          color: Colors.black),
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
      items: _statusOptions.map<DropdownMenuItem<String>>((String value) {
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
