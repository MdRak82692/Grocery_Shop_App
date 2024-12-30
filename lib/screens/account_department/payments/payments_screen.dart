import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../../../models/payment_model.dart';
import '../../home_screen.dart';

class PaymentsScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const PaymentsScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _PaymentsScreenState createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends State<PaymentsScreen> {
  List<Payment> payments = [];
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
      fetchPayments();
    });
  }

  Future<void> fetchPayments() async {
    try {
      final db = mongo.Db('mongodb://localhost:27017/$dbName');
      await db.open();

      final collection = db.collection('payment');
      final paymentList = await collection.find().toList();

      await db.close();

      if (mounted) {
        setState(() {
          payments = paymentList
              .map((json) => Payment.fromJson(json as Map<String, dynamic>))
              .where((payment) =>
                  searchText == null ||
                  payment.name.toLowerCase().contains(searchText!.toLowerCase()) ||
                  payment.paymentType.toLowerCase().contains(searchText!.toLowerCase()) ||
                  payment.totalPrice.toString().contains(searchText!) ||
                  payment.paymentDateTime.toString().contains(searchText!))
              .toList();
        });
      }
    } catch (e) {
      print('Error fetching payments: $e');
    }
  }

  Map<String, Map<String, List<Payment>>> groupPaymentsByTypeAndDate(List<Payment> payments) {
    Map<String, Map<String, List<Payment>>> groupedPayments = {};

    for (var payment in payments) {
      String paymentType = payment.paymentType;
      String paymentDate = formatPaymentDateTime(payment.paymentDateTime);

      if (!groupedPayments.containsKey(paymentType)) {
        groupedPayments[paymentType] = {};
      }

      if (!groupedPayments[paymentType]!.containsKey(paymentDate)) {
        groupedPayments[paymentType]![paymentDate] = [];
      }

      groupedPayments[paymentType]![paymentDate]!.add(payment);
    }

    return groupedPayments;
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

  String formatPaymentDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Color getPaymentTypeColor(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'customer':
        return Colors.green;
      case 'supplier':
        return Colors.red;
      case 'employee salary':
        return Colors.blue;
      default:
        return const Color.fromARGB(255, 2, 27, 151);
    }
  }

  double calculateTodayTotal(String paymentType) {
    final today = DateTime.now();
    return payments
        .where((payment) =>
            payment.paymentType.toLowerCase() == paymentType.toLowerCase() &&
            payment.paymentDateTime.year == today.year &&
            payment.paymentDateTime.month == today.month &&
            payment.paymentDateTime.day == today.day)
        .fold(0.0, (sum, payment) => sum + payment.totalPrice);
  }

  double calculateTotal(String paymentType) {
    return payments
        .where((payment) => payment.paymentType.toLowerCase() == paymentType.toLowerCase())
        .fold(0.0, (sum, payment) => sum + payment.totalPrice);
  }

  double calculateBalance() {
    double totalCustomerPayment = calculateTotal('customer');
    double totalSupplierPayment = calculateTotal('supplier');
    double totalEmployeeSalaryPayment = calculateTotal('employee salary');
    return totalCustomerPayment - totalSupplierPayment - totalEmployeeSalaryPayment;
  }

  @override
  Widget build(BuildContext context) {
    Map<String, Map<String, List<Payment>>> groupedPayments =
        groupPaymentsByTypeAndDate(payments);

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
                    fetchPayments();
                  });
                },
              )
            : Text(
                'Payments Management',
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
                _buildTotalsRow(),
                if (groupedPayments.isEmpty)
                  _buildEmptyTable()
                else
                  for (var paymentType in groupedPayments.keys)
                    _buildPaymentTypeTable(
                        paymentType, groupedPayments[paymentType]!),
                if (payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Text(
                      'No Payment List available.',
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
    double totalCustomerPayment = calculateTotal('customer');
    double totalSupplierPayment = calculateTotal('supplier');
    double totalEmployeeSalaryPayment = calculateTotal('employee salary');
    double balance = calculateBalance();

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
      margin: EdgeInsets.only(bottom: 20),
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
            _buildTotalCustomerPaymentRow(totalCustomerPayment),
            _buildTotalSupplierPaymentRow(totalSupplierPayment),
            _buildTotalEmployeeSalaryPaymentRow(totalEmployeeSalaryPayment),
            _buildBalanceRow(balance),
          ],
        ),
      ),
    );
  }

  TableRow _buildTotalCustomerPaymentRow(double amount) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      children: [
        Container(
          height: 60,
          padding: EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total Customer Payment:',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),
        Container(
          height: 60,
          padding: EdgeInsets.only(right: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$amount',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildTotalSupplierPaymentRow(double amount) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      children: [
        Container(
          height: 60,
          padding: EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total Supplier Payment:',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
        Container(
          height: 60,
          padding: EdgeInsets.only(right: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$amount',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildTotalEmployeeSalaryPaymentRow(double amount) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      children: [
        Container(
          height: 60,
          padding: EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Total Employee Salary Payment:',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
        Container(
          height: 60,
          padding: EdgeInsets.only(right: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$amount',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
        ),
      ],
    );
  }

  TableRow _buildBalanceRow(double balance) {
    return TableRow(
      decoration: BoxDecoration(
        color: Colors.white,
      ),
      children: [
        Container(
          height: 60,
          padding: EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Balance:',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: balance < 0 ? Colors.red : Colors.green,
              ),
            ),
          ),
        ),
        Container(
          height: 60,
          padding: EdgeInsets.only(right: 10),
          child: Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$balance',
              style: TextStyle(
                fontSize: 22,
                fontFamily: 'RobotoCondensed',
                fontWeight: FontWeight.bold,
                color: balance < 0 ? Colors.red : Colors.green,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                          'Payment Type: ',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
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
                0: FractionColumnWidth(1),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 168, 255, 75),
                  ),
                  children: [
                    Container(
                      height: 60,
                      child: Center(
                        child: Text(
                          'Payment Date: ',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 3, 66, 117),
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
                width: 5.0),
              columnWidths: const <int, TableColumnWidth>{
                0: FractionColumnWidth(0.10),
                1: FractionColumnWidth(0.30),
                2: FractionColumnWidth(0.30),
                3: FractionColumnWidth(0.30),
              },
              children: [
                TableRow(
                  decoration: BoxDecoration(color: Colors.blue),
                  children: [
                    _buildTableHeaderCell('SL NO'),
                    _buildTableHeaderCell('Name'),
                    _buildTableHeaderCell('Total Price'),
                    _buildTableHeaderCell('Payment Date & Time'),
                  ],
                ),
              ],
            ),
          ),
        ),
        _buildTotalPaymentRow('default', []),
      ],
    );
  }

  Widget _buildPaymentTypeTable(
      String paymentType, Map<String, List<Payment>> dateGroupedPayments) {
    Color paymentTypeColor = getPaymentTypeColor(paymentType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Payment Type Header
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
                          'Payment Type: $paymentType',
                          style: TextStyle(
                            fontSize: 22,
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                            color: paymentTypeColor,
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
        
        for (var paymentDate in dateGroupedPayments.keys) ...[
          // Payment Date Header
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
                      color: const Color.fromARGB(255, 168, 255, 75),
                    ),
                    children: [
                      Container(
                        height: 60,
                        child: Center(
                          child: Text(
                            'Payment Date: $paymentDate',
                            style: TextStyle(
                              fontSize: 22,
                              fontFamily: 'RobotoCondensed',
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 3, 66, 117),
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
          
          // Payment Data Table
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
                  0: FractionColumnWidth(0.10),
                  1: FractionColumnWidth(0.30),
                  2: FractionColumnWidth(0.30),
                  3: FractionColumnWidth(0.30),
                },
                children: [
                  TableRow(
                    decoration: BoxDecoration(color: Colors.blue),
                    children: [
                      _buildTableHeaderCell('SL NO'),
                      _buildTableHeaderCell(getNameColumnLabel(paymentType)),
                      _buildTableHeaderCell('Total Price'),
                      _buildTableHeaderCell('Payment Date & Time'),
                    ],
                  ),
                  for (int i = 0; i < dateGroupedPayments[paymentDate]!.length; i++)
                    _buildPaymentRow(i + 1, dateGroupedPayments[paymentDate]![i]),
                ],
              ),
            ),
          ),
          // Total Payment for the Date
          _buildTotalPaymentRow(paymentType, dateGroupedPayments[paymentDate]!),
        ],
      ],
    );
  }

  String getNameColumnLabel(String paymentType) {
    switch (paymentType.toLowerCase()) {
      case 'customer':
        return 'Customer Name';
      case 'supplier':
        return 'Supplier Name';
      case 'employee salary':
        return 'Employee Name';
      default:
        return 'Name';
    }
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

  TableRow _buildPaymentRow(int index, Payment payment) {
    return TableRow(
      decoration: BoxDecoration(color: Colors.white),
      children: [
        _buildTableCell('$index'),
        _buildTableCell(payment.name),
        _buildTableCell(payment.totalPrice.toString()),
        _buildTableCell(formatDateTime(payment.paymentDateTime)),
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

  Widget _buildTotalPaymentRow(
      String paymentType, List<Payment> payments) {
    double todayTotalPayment = payments.fold(0.0, (sum, payment) => sum + payment.totalPrice);

    Color color;

    switch (paymentType.toLowerCase()) {
      case 'customer':
        color = Colors.green;
        break;
      case 'supplier':
        color = Colors.red;
        break;
      case 'employee salary':
        color = Colors.blue;
        break;
      default:
        color = Colors.black;
    }

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
      margin: EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Table(
          border: TableBorder.all(
            color: Color(0xFF006400),
            width: 5.0),
          columnWidths: {
            0: FractionColumnWidth(0.5),
            1: FractionColumnWidth(0.5),
          },
          children: [
            TableRow(
              decoration: BoxDecoration(
                color: Colors.white,
              ),
              children: [
                Container(
                  height: 60,
                  padding: EdgeInsets.only(left: 16), // Add padding to the left
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Today’s Total $paymentType Payment:',
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
                  padding: EdgeInsets.only(right: 16), // Add padding to the right
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '\$${todayTotalPayment.toStringAsFixed(2)}',
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
}
