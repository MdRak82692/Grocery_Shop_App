import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../screens/home_screen.dart';
import 'add_purchase_order_screen.dart';
import 'edit_purchase_order_screen.dart';
import '../../../models/purchase_order_model.dart';

class PurchaseOrdersScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const PurchaseOrdersScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _PurchaseOrdersScreenState createState() => _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends State<PurchaseOrdersScreen> {
  List<PurchaseOrder> purchaseOrders = [];
  Timer? _timer;
  String? searchText;
  bool isSearching = false;
  late String dbName;

  @override
  void initState() {
    super.initState();
    dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(microseconds: 1), (timer) {
      fetchPurchaseOrders();
    });
  }

  Future<void> fetchPurchaseOrders() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('purchaseOrders');
      final orderList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          purchaseOrders = orderList
              .map((json) => PurchaseOrder.fromMap(json))
              .where((order) =>
                  searchText == null ||
                  order.orderId.toString().contains(searchText!) ||
                  order.productName.toLowerCase().contains(searchText!.toLowerCase()) || // Added productName search
                  order.suppliesName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  order.paymentMethodName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  order.status
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  order.orderDateTime
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching purchase orders: $e');
    }
  }

  Future<void> deletePurchaseOrder(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('purchaseOrders');
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchPurchaseOrders();
    } catch (e) {
      print('Error deleting purchase order: $e');
    }
  }

  Future<void> sendWhatsAppMessage(PurchaseOrder order) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final userCollection = db.collection('user');
      final user = await userCollection.findOne(mongo.where.eq('email', widget.email));
      final userContactNumber = user != null ? user['contactnumber']?.trim() : null;

      final suppliesCollection = db.collection('suppliesProfiles');
      final supplies = await suppliesCollection
          .findOne(mongo.where.eq('suppliesName', order.suppliesName));
      final supplierContactNumber = supplies != null ? supplies['contactNumber']?.trim() : null;

      final orderDetailsCollection = db.collection('orderDetails');
      final orderDetails = await orderDetailsCollection
          .find(mongo.where.eq('orderId', order.orderId))
          .toList();

      final trimmedOrderDetails = orderDetails.map((e) {
        return {
          ...e,
          'productQuantity': e['productQuantity'].toString().trim(),
          'pricePerProduct': e['pricePerProduct'].toString().trim(),
        };
      }).toList();

      await db.close();

      if (userContactNumber != null && supplierContactNumber != null && trimmedOrderDetails.isNotEmpty) {
        final message =
            'Order ID: ${order.orderId}\nProduct Name: ${order.productName}\nProduct Quantity: ${trimmedOrderDetails.map((e) => e['productQuantity']).join(', ')}\nPrice per Product: ${trimmedOrderDetails.map((e) => e['pricePerProduct']).join(', ')}\nTotal Price: ${order.totalPrice}\nPayment Method: ${order.paymentMethodName}';

        final Uri whatsappUrl = Uri.parse('https://wa.me/$supplierContactNumber?text=${Uri.encodeComponent(message)}');

        if (await canLaunchUrl(whatsappUrl)) {
          await launchUrl(whatsappUrl);

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Message Sent', style: TextStyle(
              fontSize: 26,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),),
                content: Text('The message has been sent to WhatsApp. Go to WhatsApp and click the Send.', style: TextStyle(
              fontSize: 18,
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK', style: TextStyle(
                  fontSize: 18,
                  fontFamily: 'RobotoCondensed',
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          print('Could not launch WhatsApp');
        }
      } else {
        print('Contact numbers or order details not found');
      }
    } catch (e) {
      print('Error preparing WhatsApp message: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId? id) {
    if (id == null) return; 
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Purchase Order',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this purchase order?',
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
              'No',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              deletePurchaseOrder(id);
              Navigator.of(context).pop();
            },
            child: Text(
              'Yes',
              style: TextStyle(
                fontSize: 18,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
    });
  }

  String formatOrderDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  Map<String, List<PurchaseOrder>> _groupByStatus() {
    final Map<String, List<PurchaseOrder>> grouped = {};
    for (var order in purchaseOrders) {
      if (!grouped.containsKey(order.status)) {
        grouped[order.status] = [];
      }
      grouped[order.status]!.add(order);
    }
    return grouped;
  }

  bool _isOrderInCompleteOrCancelled(String orderId) {
    return purchaseOrders.any((order) =>
        order.orderId.toString() == orderId &&
        (order.status == 'Complete' || order.status == 'Cancelled'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: isSearching
            ? TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search',
                  hintStyle: TextStyle(
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    fontSize: 26,
                  ),
                  border: InputBorder.none,
                ),
                style: TextStyle(
                  fontFamily: 'RobotoCondensed',
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontSize: 26,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                    fetchPurchaseOrders();
                  });
                },
              )
            : Text(
                'Purchase Orders Management',
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
            isSearching ? Icons.close : Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            if (isSearching) {
              _toggleSearch();
            } else {
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
            }
          },
        ),
        actions: [
          if (!isSearching)
            IconButton(
              icon: Icon(Icons.search, color: Colors.black),
              onPressed: _toggleSearch,
            ),
        ],
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
            child: Column(
              children: [
                if (purchaseOrders.isEmpty)
                  Column(
                    children: [
                      SizedBox(height: 20),
                      Container(
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Table(
                            border: TableBorder.all(
                              color: Color(0xFF006400),
                              width: 5.0,
                            ),
                            columnWidths: {
                              0: FractionColumnWidth(1),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 255, 135, 87),
                                ),
                                children: [
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Status: ',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 2, 27, 151),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: Table(
                            border: TableBorder.all(
                              color: Color(0xFF006400),
                              width: 5.0,
                            ),
                            columnWidths: {
                              0: FractionColumnWidth(0.07),
                              1: FractionColumnWidth(0.07),
                              2: FractionColumnWidth(0.12),
                              3: FractionColumnWidth(0.12),
                              4: FractionColumnWidth(0.12),
                              5: FractionColumnWidth(0.15),
                              6: FractionColumnWidth(0.15),
                              7: FractionColumnWidth(0.09),
                              8: FractionColumnWidth(0.05),
                              9: FractionColumnWidth(0.06),
                            },
                            children: [
                              TableRow(
                                decoration: BoxDecoration(color: Colors.blue),
                                children: [
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'SL NO',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Order ID',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Product Name',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Supplier Name',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Total Price',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Payment Method',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Order Date & Time',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'WhatsApp',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Edit',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    child: Center(
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontFamily: 'RobotoCondensed',
                                          fontWeight: FontWeight.bold,
                                          color: const Color.fromARGB(
                                              255, 151, 12, 2),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  for (var status in _groupByStatus().keys)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 20),
                        Container(
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Table(
                              border: TableBorder.all(
                                color: Color(0xFF006400),
                                width: 5.0,
                              ),
                              columnWidths: {
                                0: FractionColumnWidth(1),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(255, 255, 135, 87),
                                  ),
                                  children: [
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Status: $status Order',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(255, 2, 27, 151),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
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
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Table(
                              border: TableBorder.all(
                                color: Color(0xFF006400),
                                width: 5.0,
                              ),
                              columnWidths: {
                                0: FractionColumnWidth(0.07),
                                1: FractionColumnWidth(0.07),
                                2: FractionColumnWidth(0.12),
                                3: FractionColumnWidth(0.12),
                                4: FractionColumnWidth(0.12),
                                5: FractionColumnWidth(0.15),
                                6: FractionColumnWidth(0.15),
                                7: FractionColumnWidth(0.09),
                                8: FractionColumnWidth(0.05),
                                9: FractionColumnWidth(0.06), 
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(color: Colors.blue),
                                  children: [
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'SL NO',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Order ID',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Product Name',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Supplier Name',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Total Price',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Payment Method',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Order Date & Time',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'WhatsApp',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Edit',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 60,
                                      child: Center(
                                        child: Text(
                                          'Delete',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontFamily: 'RobotoCondensed',
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 151, 12, 2),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                for (int i = 0; i < _groupByStatus()[status]!.length; i++)
                                  _buildPurchaseOrderRow(i + 1, _groupByStatus()[status]![i], status),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                if (purchaseOrders.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Purchase Order List available.',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newOrder = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPurchaseOrderScreen(
                department: widget.department,
                email: widget.email,
                user: widget.user,
                shopName: widget.shopName,
              ),
            ),
          );
          if (newOrder != null) {
            fetchPurchaseOrders();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  TableRow _buildPurchaseOrderRow(int slNo, PurchaseOrder purchaseOrder, String status) {
    final showIcons = status == 'Pending' && !_isOrderInCompleteOrCancelled(purchaseOrder.orderId.toString());

    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        _buildTableCell('$slNo'), // Use slNo instead of index + 1
        _buildTableCell(purchaseOrder.orderId.toString()),
        _buildTableCell(purchaseOrder.productName), // Added productName cell
        _buildTableCell(purchaseOrder.suppliesName),
        _buildTableCell(purchaseOrder.totalPrice.toString()),
        _buildTableCell(purchaseOrder.paymentMethodName),
        _buildTableCell(formatOrderDate(purchaseOrder.orderDateTime)),
        _buildTableCellWithIcon(
          showIcons
              ? IconButton(
                  icon: FaIcon(FontAwesomeIcons.whatsapp, color: Colors.green),
                  onPressed: () {
                    sendWhatsAppMessage(purchaseOrder);
                  },
                )
              : SizedBox.shrink(),
        ),
        _buildTableCellWithIcon(
          showIcons
              ? IconButton(
                  icon: Icon(Icons.edit, color: Colors.orange),
                  onPressed: () async {
                    final updatedOrder = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditPurchaseOrderScreen(
                          purchaseOrder: purchaseOrder,
                          department: widget.department,
                          email: widget.email,
                          user: widget.user,
                          shopName: widget.shopName,
                        ),
                      ),
                    );
                    if (updatedOrder != null) {
                      fetchPurchaseOrders();
                    }
                  },
                )
              : SizedBox.shrink(),
        ),
        _buildTableCellWithIcon(
          showIcons
              ? IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    _showDeleteConfirmationDialog(purchaseOrder.id);
                  },
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildTableCell(String text) {
    return Container(
      height: 55,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCellWithIcon(Widget icon) {
    return Container(
      height: 55,
      child: Center(child: icon),
    );
  }
}
