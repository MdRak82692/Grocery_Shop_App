import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/order_details_model.dart';
import 'add_order_details_screen.dart';
import 'edit_order_details_screen.dart';
import '../../home_screen.dart';
import 'dart:async';

class OrderDetailsListScreen extends StatefulWidget {
  final String email;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const OrderDetailsListScreen({
    Key? key,
    required this.email,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _OrderDetailsListScreenState createState() => _OrderDetailsListScreenState();
}

class _OrderDetailsListScreenState extends State<OrderDetailsListScreen> {
  List<OrderDetails> _orderDetails = [];
  Set<String> _completedOrCancelledOrderIds = {}; // Set to store orderIds with "Complete" or "Cancelled" status
  String? _searchText;
  bool isSearching = false;
  Timer? _timer;
  late String _dbName;

  @override
  void initState() {
    super.initState();
    _dbName = widget.email.replaceAll('@', '_').replaceAll('.', '_');
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _timer = Timer.periodic(Duration(microseconds: 1), (timer) {
      _fetchOrderDetails();
    });
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$_dbName');
      await db.open();

      final orderDetailsCollection = db.collection('orderDetails');
      final purchaseOrdersCollection = db.collection('purchaseOrders');

      final orderDetailsList = await orderDetailsCollection.find().toList();
      _orderDetails =
          orderDetailsList.map((json) => OrderDetails.fromJson(json)).toList();

      // Fetch orders with "Complete" or "Cancelled" status
      final completedOrCancelledOrders = await purchaseOrdersCollection.find(
        mongo.where.oneFrom('status', ['Complete', 'Cancelled']),
      ).toList();

      _completedOrCancelledOrderIds.clear();
      for (var order in completedOrCancelledOrders) {
        _completedOrCancelledOrderIds.add(order['orderId'].toString());
      }

      await db.close();

      if (mounted) {
        setState(() {
          _orderDetails = orderDetailsList
              .map((json) => OrderDetails.fromJson(json))
              .where((orderDetails) =>
                  _searchText == null ||
                  orderDetails.orderId
                      .toString()
                      .contains(_searchText!.toLowerCase()) ||
                  orderDetails.productName
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()) ||
                  orderDetails.categoryName
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()) ||
                  orderDetails.productQuantity
                      .toString()
                      .contains(_searchText!.toLowerCase()) ||
                  orderDetails.pricePerProduct
                      .toString()
                      .contains(_searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching Order Details: $e');
    }
  }

  Future<void> _deleteOrderDetails(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$_dbName');
      await db.open();

      final collection = db.collection('orderDetails');
      await collection.remove(mongo.where.id(id));

      await db.close();

      _fetchOrderDetails();
    } catch (e) {
      print('Error deleting Order Details: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Order Details',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this Order Details?',
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
              _deleteOrderDetails(id);
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
      _searchText = null;
    });
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
                    _searchText = value;
                    _fetchOrderDetails();
                  });
                },
              )
            : Text(
                'Order Details',
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
              mainAxisAlignment: MainAxisAlignment.center,
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
                        0: FractionColumnWidth(0.1),
                         1: FractionColumnWidth(0.1),
                         2: FractionColumnWidth(0.2),
                         3: FractionColumnWidth(0.15),
                         4: FractionColumnWidth(0.15),
                         5: FractionColumnWidth(0.15),
                         6: FractionColumnWidth(0.075),
                         7: FractionColumnWidth(0.075),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blue),
                          children: [
                            _buildTableHeaderCell('SL NO'),
                            _buildTableHeaderCell('Order ID'),
                            _buildTableHeaderCell('Product Name'),
                            _buildTableHeaderCell('Category Name'),
                            _buildTableHeaderCell('Product Quantity'),
                            _buildTableHeaderCell('Price Per Product'),
                            _buildTableHeaderCell('Edit'),
                            _buildTableHeaderCell('Delete'),
                          ],
                        ),
                        ..._orderDetails.asMap().entries.map((entry) {
                          int index = entry.key;
                          OrderDetails orderDetails = entry.value;
                          bool isCompletedOrCancelled = _completedOrCancelledOrderIds.contains(orderDetails.orderId.toString());

                          return TableRow(
                            decoration: BoxDecoration(color: Colors.white),
                            children: [
                              _buildTableCell('${index + 1}'),
                              _buildTableCell(orderDetails.orderId.toString()),
                              _buildTableCell(orderDetails.productName),
                              _buildTableCell(orderDetails.categoryName),
                              _buildTableCell(
                                  orderDetails.productQuantity.toString()),
                              _buildTableCell(
                                  orderDetails.pricePerProduct.toStringAsFixed(2)),
                              Container(
                                height: 55,
                                child: Center(
                                  child: !isCompletedOrCancelled
                                      ? IconButton(
                                          icon: Icon(Icons.edit,
                                              color: Colors.orange),
                                          onPressed: () async {
                                            final updatedOrderDetails =
                                                await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    EditOrderDetailsScreen(
                                                  email: widget.email,
                                                  orderDetails: orderDetails,
                                                  department: widget.department,
                                                  user: widget.user,
                                                  shopName: widget.shopName,
                                                ),
                                              ),
                                            );
                                            if (updatedOrderDetails != null) {
                                              _fetchOrderDetails();
                                            }
                                          },
                                        )
                                      : SizedBox.shrink(),
                                ),
                              ),
                              Container(
                                height: 55,
                                child: Center(
                                  child: !isCompletedOrCancelled
                                      ? IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            _showDeleteConfirmationDialog(
                                                orderDetails.id);
                                          },
                                        )
                                      : SizedBox.shrink(),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
                if (_orderDetails.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Order Details Available.',
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
          final newOrderDetails = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddOrderDetailsScreen(
                email: widget.email,
                department: widget.department,
                user: widget.user,
                shopName: widget.shopName,
              ),
            ),
          );
          if (newOrderDetails != null) {
            _fetchOrderDetails();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildTableHeaderCell(String text) {
    return Container(
      height: 60,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 151, 12, 2),
          ),
        ),
      ),
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
}
