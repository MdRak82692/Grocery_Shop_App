import 'package:flutter/material.dart';
import '../../../screens/home_screen.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'dart:async';
import 'add_payment_method_screen.dart';
import 'edit_payment_method_screen.dart';
import '../../../models/payment_methods_model.dart';

class PaymentMethodScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const PaymentMethodScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _PaymentMethodScreenState createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  List<PaymentMethod> paymentMethods = []; // Corrected variable name and type
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
      fetchPaymentMethods();
    });
  }

  Future<void> fetchPaymentMethods() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('paymentMethod');
      final paymentMethodList =
          await collection.find().toList(); // Corrected variable name

      await db.close();

      if (mounted) {
        setState(() {
          paymentMethods = paymentMethodList
              .map((json) => PaymentMethod.fromJson(json)) // Corrected parsing
              .where((paymentMethod) =>
                  searchText == null ||
                  paymentMethod.paymentMethodName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching Payment Methods: $e');
    }
  }

  Future<void> deletePaymentMethod(mongo.ObjectId id) async {
    // Corrected method name
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection =
          db.collection('paymentMethod'); // Corrected collection name
      await collection.remove(mongo.where.id(id));

      await db.close();

      fetchPaymentMethods();
    } catch (e) {
      print('Error deleting Payment Methods: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Payment Method',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this Payment Method?',
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
              deletePaymentMethod(id); // Corrected method name
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
                    fetchPaymentMethods();
                  });
                },
              )
            : Text(
                'Payment Methods',
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
                          1: FractionColumnWidth(0.5),
                          2: FractionColumnWidth(0.2),
                          3: FractionColumnWidth(0.2),
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
                                    'Payment Method Name', // Corrected text
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
                          for (int i = 0;
                              i < paymentMethods.length;
                              i++) // Corrected variable name
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
                                      paymentMethods[i]
                                          .paymentMethodName, // Corrected variable name
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
                                        final updatedPaymentMethod = // Corrected variable name
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditPaymentMethodScreen(
                                              paymentMethod: paymentMethods[
                                                  i], // Corrected variable name
                                              department: widget.department,
                                              email: widget.email,
                                              user: widget.user,
                                              shopName: widget.shopName,
                                            ),
                                          ),
                                        );
                                        if (updatedPaymentMethod != null) {
                                          fetchPaymentMethods();
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
                                            paymentMethods[i]
                                                .id); // Corrected variable name
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
                if (paymentMethods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Payment Method List available.',
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
          final newPaymentMethod = await Navigator.push(
            // Corrected variable name
            context,
            MaterialPageRoute(
                builder: (context) => AddPaymentMethodScreen(
                      department: widget.department,
                      email: widget.email,
                      user: widget.user,
                      shopName: widget.shopName,
                    )),
          );
          if (newPaymentMethod != null) {
            fetchPaymentMethods();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
