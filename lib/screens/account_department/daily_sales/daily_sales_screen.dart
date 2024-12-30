import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/sales_model.dart';
import '../../home_screen.dart';

class DailySalesScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const DailySalesScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _DailySalesScreenState createState() => _DailySalesScreenState();
}

class _DailySalesScreenState extends State<DailySalesScreen> {
  List<Sales> sales = [];
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
      fetchSales();
    });
  }

  Future<void> fetchSales() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('sales');
      final salesList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          sales = salesList
              .map((json) => Sales.fromJson(json as Map<String, dynamic>))
              .where((sale) =>
                  searchText == null ||
                  sale.customerName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  sale.contactNumber
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  sale.productName
                      .toLowerCase()
                      .contains(searchText!.toLowerCase()) ||
                  sale.salesDateTime.toString().contains(searchText!) ||
                  sale.paymentMethodName.toString().contains(searchText!) ||
                  sale.productQuantity.toString().contains(searchText!) ||
                  sale.pricePerProduct.toString().contains(searchText!) ||
                  sale.totalPrice.toString().contains(searchText!) ||
                  sale.totalPriceOfAllProducts.toString().contains(searchText!))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching sales: $e');
    }
  }

  Map<String, List<Sales>> groupSalesByDate(List<Sales> sales) {
    Map<String, List<Sales>> groupedSales = {};

    for (var sale in sales) {
      String saleDate = formatSalesDateTime(sale.salesDateTime);

      if (!groupedSales.containsKey(saleDate)) {
        groupedSales[saleDate] = [];
      }

      groupedSales[saleDate]!.add(sale);
    }

    return groupedSales;
  }

  void _toggleSearch() {
    setState(() {
      isSearching = !isSearching;
      searchText = null;
    });
  }

  String formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }

  String formatSalesDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  double calculateTodayTotal() {
    final today = DateTime.now();
    return sales
        .where((sale) =>
            sale.salesDateTime.year == today.year &&
            sale.salesDateTime.month == today.month &&
            sale.salesDateTime.day == today.day)
        .fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  double calculatePreviousMonthTotal() {
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1);
    return sales
        .where((sale) =>
            sale.salesDateTime.year == previousMonth.year &&
            sale.salesDateTime.month == previousMonth.month)
        .fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  double calculatePreviousYearTotal() {
    final now = DateTime.now();
    return sales
        .where((sale) => sale.salesDateTime.year == now.year - 1)
        .fold(0.0, (sum, sale) => sum + sale.totalPrice);
  }

  @override
  Widget build(BuildContext context) {
    Map<String, List<Sales>> groupedSales = groupSalesByDate(sales);

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
                    fetchSales();
                  });
                },
              )
            : Text(
                'Daily Sales Management',
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
                _buildTotalsRow(), // Display total sales in a separate table
                if (groupedSales.isEmpty)
                  _buildEmptyTable()
                else
                  for (var saleDate in groupedSales.keys)
                    _buildSalesDateSection(saleDate, groupedSales[saleDate]!),
                if (sales.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Daily Sales List available.',
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

  Widget _buildTotalsRow() {
    double totalSalesToday = calculateTodayTotal();
    double totalSalesPreviousMonth = calculatePreviousMonthTotal();
    double totalSalesPreviousYear = calculatePreviousYearTotal();

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
      margin: EdgeInsets.only(
        bottom: 20,
      ),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Table(
          border: TableBorder.all(
            color: Color(0xFF006400),
            width: 5.0,
          ),
          columnWidths: {
            0: FractionColumnWidth(0.5),
            1: FractionColumnWidth(0.5),
          },
          children: [
            _buildTotalSalesRow(
                'Today’s Total Sales:', totalSalesToday, Colors.green),
            _buildTotalSalesRow('Previous Month Total Sales:',
                totalSalesPreviousMonth, Colors.red),
            _buildTotalSalesRow('Previous Year Total Sales:',
                totalSalesPreviousYear, Colors.blue),
          ],
        ),
      ),
    );
  }

  TableRow _buildTotalSalesRow(String label, double amount, Color color) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      children: [
        Container(
          height: 60,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
        Container(
          height: 60,
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '\$${amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesDateSection(String saleDate, List<Sales> sales) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableWithHeader(
            'Sales Date: $saleDate',
            const Color.fromARGB(255, 3, 66, 117),
            const [FractionColumnWidth(1)]),
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
              columnWidths: const {
                0: FractionColumnWidth(0.05),
                1: FractionColumnWidth(0.1),
                2: FractionColumnWidth(0.13),
                3: FractionColumnWidth(0.09),
                4: FractionColumnWidth(0.09),
                5: FractionColumnWidth(0.09),
                6: FractionColumnWidth(0.1),
                7: FractionColumnWidth(0.15),
                8: FractionColumnWidth(0.1),
                9: FractionColumnWidth(0.1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Customer Name'),
                    _buildTableHeaderCell('Contact Number'),
                    _buildTableHeaderCell('Product Name'),
                    _buildTableHeaderCell('Product Quantity'),
                    _buildTableHeaderCell('Price Per Product'),
                    _buildTableHeaderCell('Total Price'),
                    _buildTableHeaderCell('Total Price of All Products'),
                    _buildTableHeaderCell('Payment Method'),
                    _buildTableHeaderCell('Sales Date & Time'),
                  ],
                ),
                ..._buildSalesRows(sales),
              ],
            ),
          ),
        ),
        _buildTotalSalesForDateSection(sales, saleDate),
      ],
    );
  }

  List<TableRow> _buildSalesRows(List<Sales> salesList) {
    final groupedSales = <String, List<Sales>>{};

    for (var sale in salesList) {
      final key =
          '${sale.customerName}_${sale.contactNumber}_${sale.totalPriceOfAllProducts}_${sale.paymentMethodName}_${sale.salesDateTime}';
      if (groupedSales.containsKey(key)) {
        groupedSales[key]!.add(sale);
      } else {
        groupedSales[key] = [sale];
      }
    }

    List<TableRow> rows = [];
    int index = 1;

    groupedSales.forEach((key, salesGroup) {
      for (int i = 0; i < salesGroup.length; i++) {
        Sales sale = salesGroup[i];
        rows.add(TableRow(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              left: BorderSide(color: Colors.green, width: 2),
              right: BorderSide(color: Colors.green, width: 2),
              bottom: BorderSide(
                  color: Colors.green,
                  width: i == salesGroup.length - 1 ? 2 : 0),
            ),
          ),
          children: [
            _buildTableCell(i == 0
                ? '$index'
                : ''), // SL NO only for the first row of the group
            _buildTableCell(i == 0
                ? sale.customerName
                : ''), // Customer Name only for the first row of the group
            _buildTableCell(i == 0
                ? sale.contactNumber
                : ''), // Contact Number only for the first row of the group
            _buildTableCell(sale.productName), // Product Name for each row
            _buildTableCell(sale.productQuantity
                .toString()), // Product Quantity for each row
            _buildTableCell(sale.pricePerProduct
                .toString()), // Price Per Product for each row
            _buildTableCell(
                sale.totalPrice.toString()), // Total Price for each row
            _buildTableCell(i == 0
                ? sale.totalPriceOfAllProducts.toString()
                : ''), // Total Price of All Products only for the first row of the group
            _buildTableCell(i == 0
                ? sale.paymentMethodName
                : ''), // Payment Method Name only for the first row of the group
            _buildTableCell(i == 0
                ? formatDateTime(sale.salesDateTime)
                : ''), // Sale Date & Time only for the first row of the group
          ],
        ));
      }
      index++;
    });

    return rows;
  }

  Widget _buildTableCell(String text) {
    return Container(
      height: 55, // Consistent height
      alignment: Alignment.center,
      padding:
          EdgeInsets.symmetric(horizontal: 4), // Padding for better readability
      child: Text(
        text.isNotEmpty ? text : '', // Ensure there's always some content
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 18,
          fontFamily: 'RobotoCondensed',
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildTotalSalesForDateSection(List<Sales> sales, String saleDate) {
    double totalSalesForDate =
        sales.fold(0.0, (sum, sale) => sum + sale.totalPrice);

    return Container(
      margin: EdgeInsets.only(top: 10),
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
            0: FractionColumnWidth(0.5),
            1: FractionColumnWidth(0.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.white),
              children: [
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Total Sales for $saleDate:',
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '\$${totalSalesForDate.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
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
    );
  }

  Widget _buildTableWithHeader(String text, Color color,
      [List<TableColumnWidth>? columnWidths]) {
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
          border: TableBorder.all(color: Color(0xFF006400), width: 5.0),
          columnWidths: columnWidths != null
              ? Map.fromIterable(
                  List.generate(columnWidths.length, (index) => index),
                  value: (i) => columnWidths[i])
              : const <int, TableColumnWidth>{0: FractionColumnWidth(1)},
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
                      text,
                      style: TextStyle(
                        fontSize: 22,
                        fontFamily: 'RobotoCondensed',
                        fontWeight: FontWeight.bold,
                        color: color,
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

  Widget _buildTableHeaderCell(String text) {
    return Container(
      height: 60,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
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

  Widget _buildEmptyTable() {
    String saleDate = formatSalesDateTime(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTableWithHeader(
            'Sales Date:',
            const Color.fromARGB(255, 2, 27, 151),
            const [FractionColumnWidth(1)]),
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
              columnWidths: const {
                0: FractionColumnWidth(0.05),
                1: FractionColumnWidth(0.1),
                2: FractionColumnWidth(0.13),
                3: FractionColumnWidth(0.09),
                4: FractionColumnWidth(0.09),
                5: FractionColumnWidth(0.09),
                6: FractionColumnWidth(0.1),
                7: FractionColumnWidth(0.15),
                8: FractionColumnWidth(0.1),
                9: FractionColumnWidth(0.1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Customer Name'),
                    _buildTableHeaderCell('Contact Number'),
                    _buildTableHeaderCell('Product Name'),
                    _buildTableHeaderCell('Product Quantity'),
                    _buildTableHeaderCell('Price Per Product'),
                    _buildTableHeaderCell('Total Price'),
                    _buildTableHeaderCell('Total Price of All Products'),
                    _buildTableHeaderCell('Payment Method'),
                    _buildTableHeaderCell('Sales Date & Time'),
                  ],
                ),
                ..._buildSalesRows(
                    []), // Use an empty list if there are no sales
              ],
            ),
          ),
        ),
        _buildTotalSalesForDateSection([], saleDate),
      ],
    );
  }
}
