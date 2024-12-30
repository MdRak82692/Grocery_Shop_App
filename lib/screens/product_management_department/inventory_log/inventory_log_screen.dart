import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'add_inventory_log_screen.dart';
import 'edit_inventory_log_screen.dart';
import '../../home_screen.dart';
import '../../../models/inventory_log_model.dart';

class InventoryLogScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const InventoryLogScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _InventoryLogScreenState createState() => _InventoryLogScreenState();
}

class _InventoryLogScreenState extends State<InventoryLogScreen> {
  List<InventoryLog> inventoryLogs = [];
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
      fetchInventoryLogs();
    });
  }

  Future<void> fetchInventoryLogs() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('inventoryLog');
      final inventoryLogList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          inventoryLogs = inventoryLogList
              .map((json) => InventoryLog.fromJson(json))
              .where((inventoryLog) =>
                  searchText == null ||
                  inventoryLog.productName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  inventoryLog.transactionType
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  inventoryLog.productQuantity.toString().contains(searchText!) || 
                  inventoryLog.logDateTime.toString().contains(searchText!))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching inventory logs: $e');
    }
  }

  Future<void> deleteInventoryLog(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('inventoryLog');
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchInventoryLogs();
    } catch (e) {
      print('Error deleting inventory log: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Inventory Log',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this inventory log record?',
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
              deleteInventoryLog(id);
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

  Map<String, List<InventoryLog>> groupInventoryLogsByTransactionType(
      List<InventoryLog> inventoryLogs) {
    Map<String, List<InventoryLog>> groupedInventoryLogs = {};
    for (var inventoryLog in inventoryLogs) {
      if (groupedInventoryLogs.containsKey(inventoryLog.transactionType)) {
        groupedInventoryLogs[inventoryLog.transactionType]!
            .add(inventoryLog);
      } else {
        groupedInventoryLogs[inventoryLog.transactionType] = [inventoryLog];
      }
    }
    return groupedInventoryLogs;
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
    });
  }

  String formatLogDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<InventoryLog>> groupedInventoryLogs =
        groupInventoryLogsByTransactionType(inventoryLogs);

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
                    fetchInventoryLogs();
                  });
                },
              )
            : Text(
                'Inventory Log Management',
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
                if (groupedInventoryLogs.isEmpty)
                  _buildEmptyTable()
                else
                  for (var transactionType in groupedInventoryLogs.keys)
                    _buildTransactionTypeTable(
                        transactionType, groupedInventoryLogs[transactionType]!),
                if (inventoryLogs.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Inventory Log List available.',
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
          final newInventoryLog = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddInventoryLogScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newInventoryLog != null) {
            fetchInventoryLogs();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildEmptyTable() {
    return Column(
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
                          'Transaction Type: ',
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
              columnWidths: const <int, TableColumnWidth>{
                0: FractionColumnWidth(0.07),
                1: FractionColumnWidth(0.29),
                2: FractionColumnWidth(0.20),
                3: FractionColumnWidth(0.30),
                4: FractionColumnWidth(0.07),
                5: FractionColumnWidth(0.07),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Product Name'),
                    _buildTableHeaderCell('Quantity'),
                    _buildTableHeaderCell('Log Date & Time'),
                    _buildTableHeaderCell('Edit'),
                    _buildTableHeaderCell('Delete'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeTable(
      String transactionType, List<InventoryLog> inventoryLogs) {
    Color transactionTypeColor;
    if (transactionType.toLowerCase() == 'purchase') {
      transactionTypeColor = const Color.fromARGB(255, 2, 145, 6);
    } else {
      transactionTypeColor = const Color.fromARGB(255, 183, 5, 8);
    }

    return Column(
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
              columnWidths: const <int, TableColumnWidth>{
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
                          'Transaction Type: $transactionType',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                            color: transactionTypeColor,
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
              columnWidths: const <int, TableColumnWidth>{
                0: FractionColumnWidth(0.07),
                1: FractionColumnWidth(0.29),
                2: FractionColumnWidth(0.20),
                3: FractionColumnWidth(0.30),
                4: FractionColumnWidth(0.07),
                5: FractionColumnWidth(0.07),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Product Name'),
                    _buildTableHeaderCell('Quantity'),
                    _buildTableHeaderCell('Log Date & Time'),
                    _buildTableHeaderCell('Edit'),
                    _buildTableHeaderCell('Delete'),
                  ],
                ),
                for (int i = 0; i < inventoryLogs.length; i++)
                  _buildInventoryLogRow(i, inventoryLogs[i]),
              ],
            ),
          ),
        ),
      ],
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

  TableRow _buildInventoryLogRow(int index, InventoryLog inventoryLog) {
  bool showEditDeleteIcons = !(inventoryLog.transactionType.toLowerCase() == 'purchase' || inventoryLog.transactionType.toLowerCase() == 'sales');

  return TableRow(
    decoration: BoxDecoration(color: Colors.white),
    children: [
      _buildTableCell('${index + 1}'),
      _buildTableCell(inventoryLog.productName),
      _buildTableCell(inventoryLog.productQuantity.toString()),
      _buildTableCell(formatLogDateTime(inventoryLog.logDateTime)),
      if (showEditDeleteIcons)
        _buildFixedCell(
          IconButton(
            icon: Icon(Icons.edit, color: Colors.blue),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditInventoryLogScreen(
                    department: widget.department,
                    email: widget.email,
                    user: widget.user,
                    shopName: widget.shopName,
                    productName: inventoryLog.productName,
                    productQuantity: inventoryLog.productQuantity,
                    transactionType: inventoryLog.transactionType,
                    id: inventoryLog.id, // Ensure the id is passed here
                  ),
                ),
              ).then((_) => fetchInventoryLogs());
            },
          ),
        ),
      if (showEditDeleteIcons)
        _buildFixedCell(
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _showDeleteConfirmationDialog(inventoryLog.id);
            },
          ),
        ),
      if (!showEditDeleteIcons) _buildTableCell(''), // Placeholder for Edit
      if (!showEditDeleteIcons) _buildTableCell(''), // Placeholder for Delete
    ],
  );
}

  Widget _buildFixedCell(Widget child) {
    return Container(
      height: 55,
      alignment: Alignment.center,
      child: child,
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
