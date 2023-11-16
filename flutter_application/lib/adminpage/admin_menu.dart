import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application/adminpage/products.dart';
import 'package:flutter_application/adminpage/edit_products.dart';
import 'package:flutter_application/adminpage/history.dart';
import 'package:flutter_application/homepage.dart';
import 'package:flutter_application/adminpage/order.dart';
import 'package:flutter_application/adminpage/user_edit.dart';
import 'package:flutter_application/adminpage/reportsell.dart';
import 'package:flutter_application/adminpage/reportstock.dart';
import 'package:flutter_application/adminpage/reportorder.dart';

class AdminMenu extends StatefulWidget {
  AdminMenu({Key? key}) : super(key: key);

  @override
  _AdminMenuState createState() => _AdminMenuState();
}

class _AdminMenuState extends State<AdminMenu> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersListener;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersListener;

  @override
  void initState() {
    // Subscribe to changes in the users collection
    _usersListener = firestore.collection('users').snapshots().listen(
      (snapshot) {
        // Handle changes to the collection
      },
      onError: (error) {
        print('Listen for users collection failed: $error');
      },
    );

    // Subscribe to changes in the orders collection
    _ordersListener = firestore.collection('orders').snapshots().listen(
      (snapshot) {
        // Handle changes to the collection
      },
      onError: (error) {
        print('Listen for orders collection failed: $error');
      },
    );

    super.initState();
  }

  @override
  void dispose() {
    // Cancel the listeners when the widget is disposed
    _usersListener?.cancel();
    _ordersListener?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ระบบแอดมิน'),
      ),
      drawer: Drawer(
        child: ListView(
          padding:
              EdgeInsets.zero, // To remove the top space for the status bar
          children: <Widget>[
            // Define the drawer header
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Define the drawer items
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('รายงานภาพรวม'),
              onTap: () {
                Navigator.pop(context);

                // Navigate to the Dashboard screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const Dashboard()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('จัดการสินค้า'),
              onTap: () {
                Navigator.pop(context);

                // Navigate to the Product Management screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ProductManagement()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.shopping_cart),
              title: const Text('จัดการคำสั่งซื้อ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => OrderManagementPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('จัดการผู้ใช้'),
              onTap: () {
                Navigator.pop(context);

                // Navigate to the User Management screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => UserEditPage()),
                );
              },
            ),

            Divider(),
            ListTile(
              title: const Text('ออกจากระบบ'),
              leading: const Icon(Icons.logout),
              onTap: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Cancel the listeners when the user logs out
                  _usersListener?.cancel();
                  _ordersListener?.cancel();
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                      (route) => false);
                } catch (e) {
                  print('Error logging out: $e');
                }
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Text(
          'ยินดีต้อนรับเข้าสู่ระบบแอดมิน',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แดชบอร์ด'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DashboardMenu(
                  name: 'ประวัติแก้ไข',
                  color: Colors.blue,
                  icon: Icons.history,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => History()),
                    );
                  },
                ),
                _DashboardMenu(
                  name: 'รายงานการขาย',
                  color: Colors.red,
                  icon: Icons.sell,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReportSell()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _DashboardMenu(
                  name: 'คำสั่งซื้อ',
                  color: Colors.green,
                  icon: Icons.shopping_cart,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReportOrderPage()),
                    );
                  },
                ),
                _DashboardMenu(
                  name: 'สินค้าในคลัง',
                  color: Colors.orange,
                  icon: Icons.inventory,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => ReportStockScreen()),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMenu extends StatelessWidget {
  final String name;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardMenu({
    Key? key,
    required this.name,
    required this.color,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8.0),
          Text(
            name,
            style: const TextStyle(fontSize: 18, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class ProductManagement extends StatefulWidget {
  const ProductManagement({super.key});

  @override
  _ProductManagementState createState() => _ProductManagementState();
}

class _ProductManagementState extends State<ProductManagement> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  List<QueryDocumentSnapshot> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() {
    _firestore.collection('products').get().then((snapshot) {
      setState(() {
        _products = snapshot.docs;
      });
    }).catchError((error) {
      print(error.toString());
    });
  }

  void _searchProducts(String query) {
    _firestore
        .collection('products')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .get()
        .then((snapshot) {
      setState(() {
        _products = snapshot.docs;
      });
    }).catchError((error) {
      print(error.toString());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการสินค้า'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้าหาสินค้า',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (query) {
                if (query.isEmpty) {
                  _loadProducts();
                } else {
                  _searchProducts(query);
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _products.length,
              itemBuilder: (BuildContext context, int index) {
                final product =
                    _products[index].data() as Map<String, dynamic>?;

                if (product == null) {
                  return const SizedBox.shrink();
                }

                return Card(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProductScreen(productId: _products[index].id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: product['images'].isNotEmpty
                                  ? Image.network(
                                      product['images'][0],
                                      height: 120.0,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/image_placeholder.png',
                                      height: 120.0,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['name'],
                                  style: const TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'ราคา: \฿${product['price']}',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  'สินค้าคงตลัง: ${product['inStock']}',
                                  style: const TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddProductScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
