import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/auth_page.dart';
import 'package:flutter_application/userpage/setting.dart';
import 'package:flutter_application/userpage/confirm_order.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Initialize product quantities as an empty list
  List<int> productQuantities = [];

  Future<void> _addToCart(
      String productId, BuildContext context, int quantity) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to the login screen if user is not logged in
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => const AuthPage()));
      return;
    }

    try {
      final cartRef =
          FirebaseFirestore.instance.collection('carts').doc(user.uid);
      final cart = await cartRef.get();
      List<String> products = List<String>.from(cart.data()?['products'] ?? []);
      List<int> quantities = List<int>.from(cart.data()?['quantities'] ?? []);
      final index = products.indexOf(productId);
      if (index != -1) {
        // If product is already in cart, update its quantity instead of adding it.
        quantities[index] += quantity;
        // Update the corresponding quantity in productQuantities too
        productQuantities[index] += quantity;
      } else {
        // Otherwise add the new item.
        products.add(productId);
        quantities.add(quantity);
        // Add a new quantity to productQuantities if it's a new item.
        productQuantities.add(quantity);
      }
      // Update the cart in Firestore.
      await cartRef.set({
        'products': products,
        'quantities': quantities,
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Product added to cart'),
      ));
    } catch (e) {
      print('Error adding product to cart: $e');
    }
  }

  void clearCart() async {
    final User? user = FirebaseAuth.instance.currentUser;

    // Delete all documents in the `carts` collection for the current user
    if (user != null) {
      final docRef =
          FirebaseFirestore.instance.collection('carts').doc(user.uid);
      final querySnapshot = await docRef.collection('items').get();

      final numDeleted = querySnapshot.docs.length;
      for (final doc in querySnapshot.docs) {
        await doc.reference.delete(); // Delete all cart item documents
      }
      await docRef.delete(); // Delete the cart document

      // Clear the `productQuantities` list
      setState(() {
        productQuantities.clear();
      });

      // Debug logging
      print('Deleted $numDeleted cart items and 1 cart for user ${user.uid}');
    }
  }

  Future<void> _removeFromCart(String productId) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    try {
      final cartRef =
          FirebaseFirestore.instance.collection('carts').doc(user.uid);
      final cart = await cartRef.get();
      List<String> products = List<String>.from(cart.data()?['products'] ?? []);
      List<int> quantities = List<int>.from(cart.data()?['quantities'] ?? []);
      final index = products.indexOf(productId);
      if (index >= 0 && index < products.length) {
        // If product is in cart, remove it from the list of products and quantities.
        products.removeAt(index);
        if (index < quantities.length) {
          quantities.removeAt(index);
        }
        // Remove the quantity from `productQuantities` as well.
        if (index < productQuantities.length) {
          productQuantities.removeAt(index);
        }

        // Update the cart in Firestore.
        await cartRef.set({
          'products': products,
          'quantities': quantities,
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Product removed from cart'),
        ));
        setState(() {});
      } else {
        throw Exception('Product $productId not found in cart');
      }
    } catch (e) {
      print('Error removing product from cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to the login screen if user is not logged in
      return const AuthPage();
    }

    // Debug logging
    print('Building CartPage for user ${user.uid}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('carts')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final products =
              List<String>.from(Set<String>.from(data['products'] ?? []));
          if (productQuantities.isEmpty) {
            // Initialize product quantities if it's an empty list
            productQuantities =
                List<int>.filled(products.length, 1, growable: true);
          }

          // Debug logging
          print('User ${user.uid} has ${products.length} cart items');

          if (products.isEmpty) {
            return Center(child: Text('ไม่พบสินค้าในตะกร้่า'));
          }

          double total = 0;
          final productPrices = <double>[];
          for (final productId in products) {
            final snapshot = FirebaseFirestore.instance
                .collection('products')
                .doc(productId)
                .snapshots();
            productPrices.add(0);
            snapshot.listen((doc) {
              final data = doc.data() ?? <String, dynamic>{};
              productPrices[products.indexOf(productId)] = data['price'] *
                  productQuantities[products.indexOf(productId)];
              total = productPrices.reduce((a, b) => a + b);
            });
          }

          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final userData = snapshot.data!.data() ?? <String, dynamic>{};
              final name = userData['firstName'] ?? '';
              final address = userData['address'] ?? '';
              final phone = userData['phone'] ?? '';

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final productId = products[index];
                        return StreamBuilder<
                            DocumentSnapshot<Map<String, dynamic>>>(
                          stream: FirebaseFirestore.instance
                              .collection('products')
                              .doc(productId)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }

                            final data =
                                snapshot.data!.data() ?? <String, dynamic>{};

                            return Card(
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      data['images'][0],
                                      height: 56.0,
                                      width: 56.0,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 8.0),
                                  Expanded(
                                    // Replace Flexible with Expanded
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Row(
                                          children: [
                                            Text(
                                                '\฿${(productPrices[products.indexOf(productId)] / productQuantities[products.indexOf(productId)]).toStringAsFixed(2)}'),
                                            const SizedBox(width: 8.0),
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              onPressed: () {
                                                setState(() {
                                                  if (productQuantities[index] >
                                                      1) {
                                                    productQuantities[index]--;
                                                    _addToCart(
                                                        productId, context, -1);
                                                  }
                                                });
                                              },
                                            ),
                                            Text(
                                              '${productQuantities[index]}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              onPressed: () {
                                                setState(() {
                                                  productQuantities[index]++;
                                                  _addToCart(
                                                      productId, context, 1);
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeFromCart(productId),
                                    icon: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'รวม:',
                          style: Theme.of(context).textTheme.subtitle1,
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ราคาสินค้า:'),
                            Text('\฿${total.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ค่าจัดส่ง:'),
                            const Text('\฿ 250.00'),
                          ],
                        ),
                        const SizedBox(height: 8.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ราคารวม:'),
                            Text('\฿${(total + 80).toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StatusPage(
                                  total: total + 80,
                                  productQuantities: productQuantities,
                                  cartProducts: products,
                                ),
                              ),
                            ).then((_) {
                              // Clear the cart contents after an order has been confirmed
                              clearCart();
                            });
                          },
                          child: const Text('ยืนยันรายการ'),
                        ),
                        const SizedBox(height: 16.0),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SettingsPage()));
                          },
                          child: const Text('แก้ไขที่อยู่จัดส่ง'),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'ชื่อผู้รับ: $name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'ที่อยู่: $address',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          'เบอร์โทร: $phone',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
