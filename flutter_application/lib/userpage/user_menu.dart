import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/auth_page.dart';
import 'package:flutter_application/userpage/cart.dart';
import 'package:flutter_application/userpage/setting.dart';
import 'package:flutter_application/userpage/order_status.dart';

final FirebaseAuth auth = FirebaseAuth.instance;

class ProductDescriptionPopup extends StatefulWidget {
  final String name;
  final String description;
  final String imageUrl;

  const ProductDescriptionPopup({
    required this.name,
    required this.description,
    required this.imageUrl,
    Key? key,
  }) : super(key: key);

  @override
  _ProductDescriptionPopupState createState() =>
      _ProductDescriptionPopupState();
}

class _ProductDescriptionPopupState extends State<ProductDescriptionPopup> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.network(
            widget.imageUrl,
            width: 200,
            height: 200,
            fit: BoxFit.cover,
          ),
          const SizedBox(height: 8),
          Text(widget.description),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('ปิด'),
        )
      ],
    );
  }
}

class UserMenu extends StatelessWidget {
  const UserMenu({
    Key? key,
    required this.pageIndex,
    required this.cartProducts,
    required this.productQuantities,
  }) : super(key: key);

  final int pageIndex;
  final List<String> cartProducts;
  final List<int> productQuantities;

  Future<void> _addToCart(String productId, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => AuthPage()));
    } else {
      final productDocRef =
          FirebaseFirestore.instance.collection('products').doc(productId);
      final productDoc = await productDocRef.get();
      if (productDoc.exists) {
        final productData = productDoc.data()!;
        var inStockData = productData['inStock'];

        // If inStock is an int, then treat it as quantity of available stock
        // Otherwise, assume it's a map and extract the 'count' property
        int inStock = (inStockData is int) ? inStockData : inStockData['count'];

        if (inStock > 0) {
          try {
            final cartRef =
                FirebaseFirestore.instance.collection('carts').doc(user.uid);
            final cart = await cartRef.get();
            if (cart.exists) {
              await cartRef.update({
                'products': FieldValue.arrayUnion([productId])
              });
            } else {
              await cartRef.set({
                'products': [productId]
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: Colors.grey,
              content: Text(
                'สินค้าถูกเพิ่มในตะกร้า',
                style: TextStyle(color: Colors.white),
              ),
            ));
          } catch (e) {
            print('Error adding product to cart: $e');
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: Colors.grey,
            content: Text(
              'สินค้าหมดแล้ว',
              style: TextStyle(color: Colors.white),
            ),
          ));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.grey,
          content: Text(
            'ไม่พบสินค้า',
            style: TextStyle(color: Colors.white),
          ),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการสินค้า'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    child: Icon(
                      Icons.person,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 8),
                  StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }

                      final user = snapshot.data;

                      if (user == null) {
                        return const Text('Unknown user');
                      }

                      return Text(
                        user.email!,
                        style: const TextStyle(fontSize: 16),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              title: const Text('ตะกร้าสินค้า'),
              leading: const Icon(Icons.shopping_cart),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CartPage()),
                );
              },
            ),
            ListTile(
              title: const Text('สถานะคำสั่งซื้อ'),
              leading: const Icon(Icons.shopping_basket),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OrderStatus()),
                );
              },
            ),
            ListTile(
              title: const Text('ตั้งค่าบัญชี'),
              leading: const Icon(Icons.settings),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsPage()),
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
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                      (route) => false);
                } catch (e) {
                  print('Error logging out: $e');
                }
              },
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final user = FirebaseAuth.instance.currentUser;

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2 / 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemBuilder: (context, index) {
              final data = snapshot.data!.docs[index].data();
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ProductDescriptionPopup(
                        name: data['name'],
                        description: data['description'],
                        imageUrl: data['images'][0],
                      );
                    },
                  );
                },
                child: Card(
                  child: Column(
                    children: [
                      Expanded(
                        child: Image.network(
                          data['images'][0],
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            data['name'],
                            style: Theme.of(context).textTheme.subtitle1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '\฿${data['price']}',
                            style: Theme.of(context).textTheme.bodyText2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .doc(snapshot.data!.docs[index].id)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData ||
                              !snapshot.data!.exists ||
                              snapshot.data!.data() == null) {
                            return const SizedBox.shrink();
                          }

                          final productData =
                              snapshot.data!.data()! as Map<String, dynamic>;

                          int count = 0;
                          final inStockData = productData['inStock'];
                          if (inStockData != null &&
                              inStockData is Map<String, dynamic>) {
                            count = inStockData['count'] as int;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              'In Stock: $count',
                              style: Theme.of(context).textTheme.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Only add product to cart if user is logged in
                          if (user != null) {
                            await _addToCart(
                                snapshot.data!.docs[index].id, context);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AuthPage(),
                              ),
                            );
                          }
                        },
                        child: const Text('เพิ่มสินค้า'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
