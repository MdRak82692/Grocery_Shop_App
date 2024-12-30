import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';

import '../../home_screen.dart';

class ExistingProductsScreen extends StatefulWidget {
  final String email;
  final String shopName;
  final String department;
  final Map<String, String> user;

  const ExistingProductsScreen({
    Key? key,
    required this.email,
    required this.shopName,
    required this.department,
    required this.user,
  }) : super(key: key);

  @override
  _ExistingProductsScreenState createState() => _ExistingProductsScreenState();
}

class _ExistingProductsScreenState extends State<ExistingProductsScreen> {
  List<Map<String, dynamic>> existingProducts = [];
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
      fetchExistingProducts();
    });
  }

 Future<void> fetchExistingProducts() async {
  try {
    final db = mongo.Db('mongodb://localhost:27017/$dbName');
    await db.open();

    final productCollection = db.collection('product');
    final inventoryLogCollection = db.collection('inventoryLog');

    final products = await productCollection.find().toList();
    final inventoryLogs = await inventoryLogCollection.find().toList();

    await db.close();

    if (mounted) {
      setState(() {
        existingProducts = products.map((product) {
          final productName = product['productName'];
          final categoryName = product['categoryName'];

          // Calculate available product quantity
          int availableQuantity = 0;
          for (var log in inventoryLogs) {
            if (log['productName'] == productName) {
              if (log['transactionType'] == 'Purchase') {
                availableQuantity += (log['productQuantity'] as num).toInt();
              } else {
                availableQuantity -= (log['productQuantity'] as num).toInt();
              }
            }
          }

          return {
            'productName': productName,
            'categoryName': categoryName,
            'availableQuantity': availableQuantity,
          };
        }).where((product) =>
            searchText == null ||
            product['productName']
                .toString()
                .toLowerCase()
                .contains(searchText!.toLowerCase()) ||
            product['categoryName']
                .toString()
                .toLowerCase()
                .contains(searchText!.toLowerCase()) ||
            product['availableQuantity']
                .toString()
                .contains(searchText!))
        .toList();
        });
      }
    } catch (e) {
      print('Error fetching existing products: $e');
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
                    fetchExistingProducts();
                  });
                },
              )
            : Text(
                'Existing Products',
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
                    child: Container(
                      child: Table(
                        border: TableBorder.all(
                          color: Color(0xFF006400),
                          width: 5.0,
                        ),
                        columnWidths: {
                          0: FractionColumnWidth(0.13),
                          1: FractionColumnWidth(0.29),
                          2: FractionColumnWidth(0.29),
                          3: FractionColumnWidth(0.29),
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
                                      color:
                                          const Color.fromARGB(255, 151, 12, 2),
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
                                      color:
                                          const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    'Category Name',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'RobotoCondensed',
                                      fontWeight: FontWeight.bold,
                                      color:
                                          const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    'Available Quantity',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'RobotoCondensed',
                                      fontWeight: FontWeight.bold,
                                      color:
                                          const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          for (int i = 0; i < existingProducts.length; i++)
                            TableRow(
                              decoration: BoxDecoration(color: Colors.white),
                              children: [
                                Container(
                                  height: 55,
                                  child: Center(
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'RobotoCondensed',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 55,
                                  child: Center(
                                    child: Text(
                                      existingProducts[i]['productName'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'RobotoCondensed',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 55,
                                  child: Center(
                                    child: Text(
                                      existingProducts[i]['categoryName'],
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'RobotoCondensed',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 55,
                                  child: Center(
                                    child: Text(
                                      '${existingProducts[i]['availableQuantity']}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontFamily: 'RobotoCondensed',
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
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
                ),
                if (existingProducts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Product Name & Quantity List available.',
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
    );
  }
}
