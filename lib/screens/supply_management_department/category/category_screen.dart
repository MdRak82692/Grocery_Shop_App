import 'package:flutter/material.dart';
import 'package:grocery_shop_app/screens/home_screen.dart';
import '../../../models/category_model.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';
import 'add_category_screen.dart';
import 'edit_category_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const CategoryScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _CategoryScreenState createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> categories = [];
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
      fetchCategories();
    });
  }

  Future<void> fetchCategories() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('category');
      final categoryList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          categories = categoryList
              .map((json) => Category.fromJson(json))
              .where((category) =>
                  searchText == null ||
                  category.categoryName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> deleteCategory(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('category');
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchCategories();
    } catch (e) {
      print('Error deleting category: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Category',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this category?',
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
              deleteCategory(id);
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
      backgroundColor: Colors.grey[200], // Set background color
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
                    fetchCategories();
                  });
                },
              )
            : Text(
                'Categories',
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
            ], // Gradient background
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
                      ], // Gradient background
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        BorderRadius.circular(8), // Optional: round the corners
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(
                        5.0), // Adjust padding to match border width
                    child: Container(
                      child: Table(
                        border: TableBorder.all(
                          color: Color(0xFF006400),
                          width: 5.0,
                        ),
                        columnWidths: {
                          0: FractionColumnWidth(0.1),
                          1: FractionColumnWidth(0.5),
                          2: FractionColumnWidth(0.2),
                          3: FractionColumnWidth(0.2),
                        },
                        children: [
                          TableRow(
                            decoration: BoxDecoration(color: Colors.blue),
                            children: [
                              Container(
                                height:
                                    60, // Increased height for the header row
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
                                height:
                                    60, // Increased height for the header row
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
                                height:
                                    60, // Increased height for the header row
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
                                height:
                                    60, // Increased height for the header row
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
                          for (int i = 0; i < categories.length; i++)
                            TableRow(
                              decoration: BoxDecoration(color: Colors.white),
                              children: [
                                Container(
                                  height: 55, // Increased height for the rows
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
                                  height: 55, // Increased height for the rows
                                  child: Center(
                                    child: Text(
                                      categories[i].categoryName,
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
                                  height: 55, // Increased height for the rows
                                  child: Center(
                                    child: IconButton(
                                      icon: Icon(Icons.edit,
                                          color: Colors.orange),
                                      onPressed: () async {
                                        final updatedCategory =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditCategoryScreen(
                                              category: categories[i],
                                              department: widget.department,
                                              email: widget.email,
                                              user: widget.user,
                                              shopName: widget.shopName,
                                            ),
                                          ),
                                        );
                                        if (updatedCategory != null) {
                                          fetchCategories();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 55, // Increased height for the rows
                                  child: Center(
                                    child: IconButton(
                                      icon:
                                          Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        _showDeleteConfirmationDialog(
                                            categories[i].id);
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
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Category List Available.',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                SizedBox(height: 20),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newCategory = await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AddCategoryScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newCategory != null) {
            fetchCategories();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
