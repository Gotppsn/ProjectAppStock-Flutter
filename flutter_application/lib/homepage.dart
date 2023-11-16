import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/auth_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('สินค้า'),
        actions: [
          IconButton(
            onPressed: () async {
              final User? user = auth.currentUser;

              if (user == null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AuthPage()),
                );
              } else {
                await auth.signOut();
              }
            },
            icon: StreamBuilder<User?>(
              stream: auth.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                if (snapshot.hasData && snapshot.data != null) {
                  return const Icon(Icons.logout);
                } else {
                  return const Icon(Icons.login);
                }
              },
            ),
          ),
          IconButton(
            onPressed: () {
              // Navigate to cart screen
            },
            icon: const Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

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
              print('product index: $index');
              final data = snapshot.data!.docs[index].data();
              return GestureDetector(
                onTap: () {
                  // Navigate to product detail screen
                },
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Image.network(
                          data['images'][0],
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['name'],
                        style: Theme.of(context).textTheme.subtitle1,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\฿${data['price']}',
                        style: Theme.of(context).textTheme.bodyText2,
                      ),
                      const SizedBox(height: 4),
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('products')
                            .doc(snapshot.data!.docs[index].id)
                            .collection('inStock')
                            .doc('count')
                            .snapshots(),
                        builder: (context, snapshot) {
                          print('inStock snapshot: ${snapshot.data}');
                          if (!snapshot.hasData ||
                              !snapshot.data!.exists ||
                              snapshot.data!.data() == null) {
                            return const SizedBox.shrink();
                          }

                          final inStockCount = int.tryParse(
                                  snapshot.data!.get('count').toString()) ??
                              0;

                          print('inStockCount: $inStockCount');
                          return Text(
                            'In Stock: $inStockCount',
                            style: Theme.of(context).textTheme.caption,
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () async {
                          final User? user = auth.currentUser;

                          if (user == null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AuthPage()),
                            );
                          } else {
                            // Navigate to cart screen
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
