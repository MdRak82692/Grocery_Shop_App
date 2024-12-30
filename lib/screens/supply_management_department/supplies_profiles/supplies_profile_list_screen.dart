import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/supplies_profile_model.dart';
import '../../home_screen.dart';
import 'add_supplies_profile_screen.dart';
import 'edit_supplies_profile_screen.dart';
import 'supplier_purchase_history_screen.dart';
import 'dart:async';

class SuppliesProfileListScreen extends StatefulWidget {
  final String email;
  final String department;
  final Map<String, String> user;
  final String shopName;

  const SuppliesProfileListScreen({
    Key? key,
    required this.email,
    required this.department,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _SuppliesProfileListScreenState createState() =>
      _SuppliesProfileListScreenState();
}

class _SuppliesProfileListScreenState extends State<SuppliesProfileListScreen> {
  List<SuppliesProfile> _suppliesProfiles = [];
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
      _fetchSuppliesProfiles();
    });
  }

  Future<void> _fetchSuppliesProfiles() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$_dbName');
      await db.open();

      final collection = db.collection('suppliesProfiles');
      final suppliesProfilesList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          _suppliesProfiles = suppliesProfilesList
              .map((json) => SuppliesProfile.fromJson(json))
              .where((profile) =>
                  _searchText == null ||
                  profile.suppliesName
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()) ||
                  profile.contactNumber
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()) ||
                  profile.productName
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()) ||
                  profile.supplyCompanyName
                      .toLowerCase()
                      .contains(_searchText!.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching Supplies Profiles: $e');
    }
  }

  Future<void> _deleteSuppliesProfile(mongo.ObjectId id) async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$_dbName');
      await db.open();

      final collection = db.collection('suppliesProfiles');
      await collection.remove(mongo.where.id(id));

      await db.close();

      _fetchSuppliesProfiles();
    } catch (e) {
      print('Error deleting Supplies Profile: $e');
    }
  }

  void _showDeleteConfirmationDialog(mongo.ObjectId id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Delete Supplies Profile',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this Supplies Profile?',
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
              _deleteSuppliesProfile(id);
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
                    _fetchSuppliesProfiles();
                  });
                },
              )
            : Text(
                'Suppliers Profiles',
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
                          1: FractionColumnWidth(0.13),
                          2: FractionColumnWidth(0.15),
                          3: FractionColumnWidth(0.14),
                          4: FractionColumnWidth(0.20),
                          5: FractionColumnWidth(0.15),
                          6: FractionColumnWidth(0.08),
                          7: FractionColumnWidth(0.08), 
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
                                    'Supplier Name',
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
                                    'Product Name',
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
                                    'Supply Company Name',
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
                          for (int i = 0; i < _suppliesProfiles.length; i++)
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
                                      _suppliesProfiles[i].suppliesName,
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
                                      _suppliesProfiles[i].contactNumber,
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
                                      _suppliesProfiles[i].productName,
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
                                      _suppliesProfiles[i].supplyCompanyName,
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
                                                SupplierPurchaseHistoryScreen(
                                              email: widget.email,
                                              suppliesProfile: _suppliesProfiles[i],
                                              shopName: widget.shopName,
                                              department: widget.department,
                                              supplierName: _suppliesProfiles[i].suppliesName,
                                              productName: _suppliesProfiles[i].productName,
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
                                                EditSuppliesProfileScreen(
                                              email: widget.email,
                                              user: widget.user,
                                              shopName: widget.shopName,
                                              department: widget.department,
                                              suppliesProfile:
                                                  _suppliesProfiles[i],
                                            ),
                                          ),
                                        );
                                        if (updatedProfile != null) {
                                          _fetchSuppliesProfiles();
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
                                            _suppliesProfiles[i].id);
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
                if (_suppliesProfiles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Suppliers Profiles Available.',
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
              builder: (context) => AddSuppliesProfileScreen(
                email: widget.email,
                department: widget.department,
                user: widget.user,
                shopName: widget.shopName,
              ),
            ),
          );
          if (newProfile != null) {
            _fetchSuppliesProfiles();
          }
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.red,
      ),
    );
  }
}
