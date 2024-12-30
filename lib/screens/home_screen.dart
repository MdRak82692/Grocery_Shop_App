import 'package:flutter/material.dart';
import '../icons.dart';
import 'account_department/daily_sales/daily_sales_screen.dart';
import 'account_department/employee_salary/employee_salary_screen.dart';
import 'account_department/payments/payments_screen.dart';
import 'departments/department_login_screen.dart';
import 'departments/department_password_change_screen.dart';
import 'human_resources_department/employee_attendance/employee_attendance_screen.dart';
import 'human_resources_department/employee_leave/employee_leave_screen.dart';
import 'human_resources_department/employee_management/employee_management_screen.dart';
import 'product_management_department/existing_products/existing_products_screen.dart';
import 'product_management_department/inventory_log/inventory_log_screen.dart';
import 'product_management_department/order_details/order_details_list_screen.dart';
import 'sales_department/customer_profiles/customer_profiles_screen.dart';
import 'sales_department/sales_management/sales_management_screen.dart';
import 'users/password_change_screen.dart';

import 'supply_management_department/category/category_screen.dart';
import 'account_department/payment_method/payment_method_screen.dart';
import 'product_management_department/product_list/product_list_screen.dart';
import 'supply_management_department/supplies_profiles/supplies_profile_list_screen.dart';
import 'supply_management_department/purchase_orders/purchase_orders_screen.dart';

class HomeScreen extends StatefulWidget {
  final String department;
  final String email;
  final Map<String, String> user;
  final String shopName;

  const HomeScreen({
    Key? key,
    required this.department,
    required this.email,
    required this.user,
    required this.shopName,
  }) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _categoryscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _paymentmethodscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _productlistscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _employeemanagementscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeManagementScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _employeeattendancescreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeAttendanceScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _employeeleavescreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeLeaveScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _suppliesprofilelistscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SuppliesProfileListScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _orderdetailscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailsListScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _purchaseorderscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PurchaseOrdersScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _employeesalaryscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeSalaryScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _existingproductscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExistingProductsScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _customerprofilesscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerProfilesScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _salesmanagementscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SalesManagementScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _dailysalesscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => DailySalesScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _paymentsscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentsScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  Future<void> _inventorylogscreen() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => InventoryLogScreen(
            email: widget.email,
            department: widget.department,
            user: {},
            shopName: widget.shopName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the number of columns based on screen width
    double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth ~/ 200;
    crossAxisCount = crossAxisCount > 4 ? 4 : crossAxisCount;
    crossAxisCount = crossAxisCount < 1 ? 1 : crossAxisCount;

    return Scaffold(
      backgroundColor: Colors.grey[200], // Set background color
      appBar: AppBar(
        title: Text(
          '${widget.shopName} Grocery Shop Management',
          style: TextStyle(
            fontSize: 26,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 11, 145, 255),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Colors.black,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => DepartmentLoginScreen(
                      email: widget.email, user: {}, shopName: widget.shopName),
                ),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: Container(
        height: MediaQuery.of(context)
            .size
            .height, // Ensure the container takes full height
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: crossAxisCount, // Dynamically determined count
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            children: _getGridItems(context),
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: IntrinsicWidth(
        // Automatically adjusts width based on content
        child: Container(
          height: double
              .infinity, // Set the height of the drawer to fill the screen
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
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: SingleChildScrollView(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10),
                        Text(
                          'Welcome ${widget.department} Profile',
                          style: TextStyle(
                            color: Colors.yellow,
                            fontSize: 30, // Adjusted font size
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Email: ${widget.email}',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 30, // Adjusted font size
                            fontFamily: 'RobotoCondensed',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ..._buildDrawerItems(context),
              ListTile(
                leading: Icon(Icons.password_rounded,
                    color: Color.fromARGB(255, 182, 14, 2)),
                title: Text(
                  'User Password Change',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasswordChangeScreen(
                        email: widget.email,
                        user: {},
                        shopName: widget.shopName,
                        department: widget.department,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.password_rounded,
                    color: Color.fromARGB(255, 182, 14, 2)),
                title: Text(
                  'Department Password Change',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DepartmentPasswordChangeScreen(
                        email: widget.email,
                        user: {},
                        shopName: widget.shopName,
                        department: widget.department,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.logout, color: Color.fromARGB(255, 182, 14, 2)),
                title: Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'RobotoCondensed',
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DepartmentLoginScreen(
                          email: widget.email,
                          user: {},
                          shopName: widget.shopName),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDrawerItems(BuildContext context) {
    List<Widget> items = [];

    if (widget.department == 'Supply Management Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.category, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Category',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _categoryscreen,
      ));
    }
    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.payment, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Payment Methods',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _paymentmethodscreen,
      ));
    }

    if (widget.department == 'Product Management Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.production_quantity_limits,
            color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Product List',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _productlistscreen,
      ));
    }

    if (widget.department == 'Supply Management Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading:
            Icon(Icons.local_shipping, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Suppliers Profiles',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _suppliesprofilelistscreen,
      ));
    }

    if (widget.department == 'Product Management Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.inventory, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Existing Products',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _existingproductscreen,
      ));

      items.add(ListTile(
        leading: Icon(Icons.list, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Order Details',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _orderdetailscreen,
      ));
    }

    if (widget.department == 'Supply Management Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading:
            Icon(Icons.shopping_cart, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Purchase Orders',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _purchaseorderscreen,
      ));
    }
    if (widget.department == 'Sales Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.person, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Customer Profiles',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _customerprofilesscreen,
      ));
      items.add(ListTile(
        leading: Icon(Icons.sell, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Sales Management',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _salesmanagementscreen,
      ));
    }

    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading:
            Icon(Icons.attach_money, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Daily Sales',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _dailysalesscreen,
      ));
      items.add(ListTile(
        leading: Icon(Icons.payments, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Payments',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _paymentsscreen,
      ));
    }

    if (widget.department == 'Product Management Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.article, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Inventory Log',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _inventorylogscreen,
      ));
    }

    if (widget.department == 'Human Resources (HR) Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(Icons.people, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Employee Management',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _employeemanagementscreen,
      ));
    }

    if (widget.department == 'Human Resources (HR) Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(MyApp.attendance, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Employee Attendance',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _employeeattendancescreen,
      ));
    }

    if (widget.department == 'Human Resources (HR) Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(MyApp.leave, color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Employee Leave',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _employeeleavescreen,
      ));
    }

    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(ListTile(
        leading: Icon(MyApp.payroll_salary_icon,
            color: Color.fromARGB(255, 182, 14, 2)),
        title: Text(
          'Employee Salary',
          style: TextStyle(
            fontSize: 18,
            fontFamily: 'RobotoCondensed',
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        onTap: _employeesalaryscreen,
      ));
    }

    return items;
  }

  List<Widget> _getGridItems(BuildContext context) {
    List<Widget> items = [];

    if (widget.department == 'Supply Management Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.category, 'Category',
          () => _categoryscreen(), Colors.red));
    }

    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.payment, 'Payment Methods',
          () => _paymentmethodscreen(), Colors.purple));
    }

    if (widget.department == 'Product Management Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.production_quantity_limits,
          'Product List', () => _productlistscreen(), Colors.green));
    }

    if (widget.department == 'Supply Management Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(
          context,
          Icons.local_shipping,
          'Suppliers Profiles',
          () => _suppliesprofilelistscreen(),
          Colors.red));
    }

    if (widget.department == 'Product Management Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.inventory, 'Existing Products',
          () => _existingproductscreen(), Colors.green));
      items.add(_buildGridItem(context, Icons.list, 'Order Details',
          () => _orderdetailscreen(), Colors.green));
    }

    if (widget.department == 'Supply Management Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.shopping_cart, 'Purchase Orders',
          () => _purchaseorderscreen(), Colors.red));
    }

    if (widget.department == 'Sales Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.person, 'Customer Profiles',
          () => _customerprofilesscreen(), Colors.yellow));
    }

    if (widget.department == 'Sales Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.sell, 'Sales Management',
          () => _salesmanagementscreen(), Colors.yellow));
    }

    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.attach_money, 'Daily Sales',
          () => _dailysalesscreen(), Colors.purple));
    }

    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.payments, 'Payments',
          () => _paymentsscreen(), Colors.purple));
    }

    if (widget.department == 'Product Management Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.article, 'Inventory Log',
          () => _inventorylogscreen(), Colors.green));
    }

    if (widget.department == 'Human Resources (HR) Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, Icons.people, 'Employee Management',
          () => _employeemanagementscreen(), Colors.orange));
    }

    if (widget.department == 'Human Resources (HR) Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, MyApp.attendance, 'Employee Attendance',
          () => _employeeattendancescreen(), Colors.orange));
    }

    if (widget.department == 'Human Resources (HR) Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, MyApp.leave, 'Employee Leave',
          () => _employeeleavescreen(), Colors.orange));
    }

    if (widget.department == 'Account Department' ||
        widget.department == 'General Department') {
      items.add(_buildGridItem(context, MyApp.payroll_salary_icon,
          'Employee Salary', () => _employeesalaryscreen(), Colors.purple));
    }

    return items;
  }

  Widget _buildGridItem(BuildContext context, IconData icon, String label,
      Function onTapFunction, Color color) {
    // Adjust icon and text size based on screen width
    double screenWidth = MediaQuery.of(context).size.width;
    double iconSize = screenWidth * 0.04; // 5% of screen width
    double fontSize = screenWidth * 0.02; // 2% of screen width

    return GestureDetector(
      onTap: () {
        onTapFunction();
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width / 7 - 20,
          height: MediaQuery.of(context).size.width / 7 - 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color: Colors.blue, size: iconSize), // Icon size adjusted
              SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize, // Font size adjusted
                  fontFamily:
                      'RobotoCondensed', // Font family set to 'RobotoCondensed'
                  fontWeight: FontWeight.bold, // Font weight set to 'Bold'
                  color: Colors.black, // Text color changed to black
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
