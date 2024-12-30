import 'package:flutter/material.dart';
import '../../../screens/home_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import '../../../models/product_model.dart';

class ProductListScreen extends StatefulWidget {
  final String email;
  final String shopName;
  final String department;
  final Map<String, String> user;

  const ProductListScreen({
    Key? key,
    required this.email,
    required this.shopName,
    required this.department,
    required this.user,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Product> products = [];
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
      fetchProducts();
    });
  }

  Future<void> fetchProducts() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('product');
      final productList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          products = productList
              .map((json) => Product.fromJson(json))
              .where((product) =>
                  searchText == null ||
                  product.productName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  product.categoryName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching Products: $e');
    }
  }

  Future<void> deleteProduct(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('product');
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchProducts();
    } catch (e) {
      print('Error deleting Product: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Product',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this Product?',
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
              deleteProduct(id);
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
                    fetchProducts();
                  });
                },
              )
            : Text(
                'Product List',
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
                          0: FractionColumnWidth(0.1),
                          1: FractionColumnWidth(0.26),
                          2: FractionColumnWidth(0.26),
                          3: FractionColumnWidth(0.23),
                          4: FractionColumnWidth(0.075),
                          5: FractionColumnWidth(0.075),
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
                                    'Price Per Product',
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
                                    'Edit',
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
                                    'Delete',
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
                          for (int i = 0; i < products.length; i++)
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
                                      products[i].productName,
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
                                      products[i].categoryName,
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
                                      '${products[i].pricePerProduct.toStringAsFixed(2)}',
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
                                    child: IconButton(
                                      icon: Icon(Icons.edit,
                                          color: Colors.orange),
                                      onPressed: () async {
                                        final updatedProduct =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditProductScreen(
                                              product: products[i],
                                              email: widget.email,
                                              user: widget.user,
                                              shopName: widget.shopName,
                                              department: widget.department,
                                            ),
                                          ),
                                        );
                                        if (updatedProduct != null) {
                                          fetchProducts();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 55,
                                  child: Center(
                                    child: IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(
                                            products[i].id);
                                      },
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
                if (products.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Product List Available.',
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
          final newProduct = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddProductScreen(
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                      department: widget.department,
                    )),
          );
          if (newProduct != null) {
            fetchProducts();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
