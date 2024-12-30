import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/customer_profiles_model.dart';
import '../../home_screen.dart';
import 'add_customer_profile_screen.dart';
import 'edit_customer_profile_screen.dart';
import 'Customer_purchase_history_screen.dart';
import 'dart:async';

class CustomerProfilesScreen extends StatefulWidget {
  final String email;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const CustomerProfilesScreen({
    Key? key,
    required this.email,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _CustomerProfilesScreenState createState() => _CustomerProfilesScreenState();
}

class _CustomerProfilesScreenState extends State<CustomerProfilesScreen> {
  List<CustomerProfile> _customerProfiles = [];
  Timer? _timer;
  String? _searchText;
  bool isSearching = false;
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
      _fetchCustomerProfiles();
    });
  }

  Future<void> _fetchCustomerProfiles() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$_dbName');
      await db.open();

      final collection = db.collection('customerProfiles');
      final customerProfilesList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          _customerProfiles = customerProfilesList
              .map((json) => CustomerProfile.fromJson(json))
              .where((profile) =>
                  _searchText == null ||
                  profile.customerName
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()) ||
                  profile.contactNumber
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching Customer Profiles: $e');
    }
  }

  Future<void> _deleteCustomerProfile(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$_dbName');
      await db.open();

      final collection = db.collection('customerProfiles');
      await collection.remove(mongo.where.id(id));

      await db.close();

      _fetchCustomerProfiles();
    } catch (e) {
      print('Error deleting Customer Profile: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Customer Profile',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this Customer Profile?',
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
              _deleteCustomerProfile(id);
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
                    _fetchCustomerProfiles();
                  });
                },
              )
            : Text(
                'Customer Profiles',
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
                          0: FractionColumnWidth(0.07),
                          1: FractionColumnWidth(0.25),
                          2: FractionColumnWidth(0.25),
                          3: FractionColumnWidth(0.23),
                          4: FractionColumnWidth(0.1),
                          5: FractionColumnWidth(0.1),
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
                                      color: const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    'Customer Name',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'RobotoCondensed',
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    'Contact Number',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'RobotoCondensed',
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                height: 60,
                                child: Center(
                                  child: Text(
                                    'Purchase History',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontFamily: 'RobotoCondensed',
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(255, 151, 12, 2),
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
                                      color: const Color.fromARGB(255, 151, 12, 2),
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
                                      color: const Color.fromARGB(255, 151, 12, 2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          for (int i = 0; i < _customerProfiles.length; i++)
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
                                      _customerProfiles[i].customerName,
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
                                      _customerProfiles[i].contactNumber,
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
                                      icon: Icon(Icons.history,
                                          color: Colors.green),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                CustomerPurchaseHistoryScreen(
                                              email: widget.email,
                                              customerProfile: _customerProfiles[i],
                                              shopName: widget.shopName,
                                              department: widget.department,
                                              customerName: _customerProfiles[i].customerName,
                                              contactNumber: _customerProfiles[i].contactNumber,
                                            ),
                                          ),
                                        );
                                      },
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
                                        final updatedProfile =
                                            await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                EditCustomerProfileScreen(
                                              email: widget.email,
                                              user: widget.user,
                                              shopName: widget.shopName,
                                              department: widget.department,
                                              customerProfile:
                                                  _customerProfiles[i],
                                            ),
                                          ),
                                        );
                                        if (updatedProfile != null) {
                                          _fetchCustomerProfiles();
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
                                            _customerProfiles[i].id);
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
                if (_customerProfiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Customer Profiles Available.',
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
          final newProfile = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddCustomerProfileScreen(
                email: widget.email,
                department: widget.department,
                user: widget.user,
                shopName: widget.shopName,
              ),
            ),
          );
          if (newProfile != null) {
            _fetchCustomerProfiles();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
