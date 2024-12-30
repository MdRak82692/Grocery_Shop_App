import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/customer_profiles_model.dart';

class CustomerPurchaseHistoryScreen extends StatefulWidget {
  final String email;
  final CustomerProfile customerProfile;
  final String shopName;
  final String department;
  final String customerName;
  final String contactNumber;

  const CustomerPurchaseHistoryScreen({
    Key? key,
    required this.email,
    required this.customerProfile,
    required this.shopName,
    required this.department,
    required this.customerName,
    required this.contactNumber,
  }) : super(key: key);

  @override
  _CustomerPurchaseHistoryScreenState createState() =>
      _CustomerPurchaseHistoryScreenState();
}

class _CustomerPurchaseHistoryScreenState
    extends State<CustomerPurchaseHistoryScreen> {
  List<Map<String, dynamic>> purchaseHistory = [];
  double totalPurchaseAmount = 0.0; // Store the total purchase amount
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
      fetchPurchaseHistory();
    });
  }

  Future<void> fetchPurchaseHistory() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('sales');
      final purchaseHistoryList = await collection
          .find(mongo.where
              .eq('customerName', widget.customerName)
              .eq('contactNumber', widget.contactNumber))
          .toList();

      await db.close();

      double totalAmount = 0.0;

      for (var item in purchaseHistoryList) {
        totalAmount += item['totalPrice'];
      }

      if (mounted) {
        setState(() {
          purchaseHistory = purchaseHistoryList
              .where((history) =>
                  searchText == null ||
                  history['productName']
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  history['productQuantity']
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  history['pricePerProduct']
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  history['orderDateTime']
                      .toString()
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
          totalPurchaseAmount = totalAmount; // Update total amount
        });
      }
    } catch (e) {
      print('Error fetching purchase history: $e');
    }
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
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
                    searchText = value;
                    fetchPurchaseHistory();
                  });
                },
              )
            : Text(
                'Customer Purchase History',
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
              Navigator.pop(context);
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
                _buildTotalPurchaseAmountTable(),
                _buildPurchaseHistoryTable(),
                if (purchaseHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Purchase History available.',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPurchaseAmountTable() {
    return Container(
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
          columnWidths: const <int, TableColumnWidth>{
            0: FractionColumnWidth(1),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 112, 255, 87),
              ),
              children: [
                Container(
                  height: 60,
                  child: Center(
                    child: Text(
                      'Total Purchase Amount: ${totalPurchaseAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 151, 2, 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseHistoryTable() {
    return Container(
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
          columnWidths: const <int, TableColumnWidth>{
            0: FractionColumnWidth(0.07),
            1: FractionColumnWidth(0.18),
            2: FractionColumnWidth(0.18),
            3: FractionColumnWidth(0.18),
            4: FractionColumnWidth(0.18),
            5: FractionColumnWidth(0.21),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.blue),
              children: [
                _buildTableHeaderCell('SL NO'),
                _buildTableHeaderCell('Product Name'),
                _buildTableHeaderCell('Product Quantity'),
                _buildTableHeaderCell('Price Per Product'),
                _buildTableHeaderCell('Total Price'),
                _buildTableHeaderCell('Sales Date & Time'),
              ],
            ),
            for (int i = 0; i < purchaseHistory.length; i++)
              _buildPurchaseHistoryRow(i, purchaseHistory[i]),
          ],
        ),
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

  TableRow _buildPurchaseHistoryRow(int index, Map<String, dynamic> purchase) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        _buildTableCell('${index + 1}'),
        _buildTableCell(purchase['productName']),
        _buildTableCell(purchase['productQuantity'].toString()),
        _buildTableCell(purchase['pricePerProduct'].toString()),
        _buildTableCell(purchase['totalPrice'].toString()),
        _buildTableCell(purchase['salesDateTime'].toString()),
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
}
