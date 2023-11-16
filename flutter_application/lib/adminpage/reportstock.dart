import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReportStockScreen extends StatelessWidget {
  const ReportStockScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานสินค้าในคลัง'),
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: FirebaseFirestore.instance.collection('products').get(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error fetching products'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final products = snapshot.data!.docs.map((doc) {
            final data = doc.data();
            final id = doc.id;
            return {...data, 'id': id};
          }).toList();

          final lowStockProducts = products.where((product) {
            final productData = product as Map<String, dynamic>;
            Map<String, dynamic>? inStock;
            if (productData['inStock'] is int) {
              inStock = {'count': productData['inStock']};
            } else {
              inStock = productData['inStock'] as Map<String, dynamic>?;
            }
            final currentQuantity =
                inStock != null ? inStock['count'] as int? : null;
            return currentQuantity != null && currentQuantity < 10;
          }).toList();

          final inStockProducts = products.where((product) {
            final productData = product as Map<String, dynamic>;
            Map<String, dynamic>? inStock;
            if (productData['inStock'] is int) {
              inStock = {'count': productData['inStock']};
            } else {
              inStock = productData['inStock'] as Map<String, dynamic>?;
            }
            final currentQuantity =
                inStock != null ? inStock['count'] as int? : null;
            return currentQuantity != null && currentQuantity >= 10;
          }).toList();

          final outOfStockProducts = products.where((product) {
            final productData = product as Map<String, dynamic>;
            Map<String, dynamic>? inStock;
            if (productData['inStock'] is int) {
              inStock = {'count': productData['inStock']};
            } else {
              inStock = productData['inStock'] as Map<String, dynamic>?;
            }
            final currentQuantity =
                inStock != null ? inStock['count'] as int? : null;
            return currentQuantity == 0;
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'สินค้าใกล้หมดแล้ว (ต่ำกว่า 10)',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent, // added color
                    letterSpacing: 1.2, // added spacing
                  ),
                ),
                SizedBox(height: 8.0),
                if (lowStockProducts.isNotEmpty)
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: lowStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = lowStockProducts[index];
                      final productData = product as Map<String, dynamic>;
                      Map<String, dynamic>? inStock;
                      if (productData['inStock'] is int) {
                        inStock = {'count': productData['inStock']};
                      } else {
                        inStock =
                            productData['inStock'] as Map<String, dynamic>?;
                      }
                      final currentQuantity =
                          inStock != null ? inStock['count'] as int? : null;
                      return ListTile(
                        title: Text(
                          productData['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // added bold
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'สินค้าในตลัง: ${currentQuantity.toString()}',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Text(
                    'No low stock products found',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic, // added italic
                    ),
                  ),
                SizedBox(height: 16.0),
                Text(
                  'สินค้าในตลัง',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.greenAccent[700], // added color
                    letterSpacing: 1.2, // added spacing
                  ),
                ),
                SizedBox(height: 8.0),
                if (inStockProducts.isNotEmpty)
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: inStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = inStockProducts[index];
                      final productData = product as Map<String, dynamic>;
                      Map<String, dynamic>? inStock;
                      if (productData['inStock'] is int) {
                        inStock = {'count': productData['inStock']};
                      } else {
                        inStock =
                            productData['inStock'] as Map<String, dynamic>?;
                      }
                      final currentQuantity =
                          inStock != null ? inStock['count'] as int? : null;
                      return ListTile(
                        title: Text(
                          productData['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // added bold
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'สินค้าในตลัง: ${currentQuantity.toString()}',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Text(
                    'No in stock products found',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic, // added italic
                    ),
                  ),
                SizedBox(height: 16.0),
                Text(
                  'สินค้าในคลังหมด',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.redAccent, // added color
                    letterSpacing: 1.2, // added spacing
                  ),
                ),
                SizedBox(height: 8.0),
                if (outOfStockProducts.isNotEmpty)
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: outOfStockProducts.length,
                    itemBuilder: (context, index) {
                      final product = outOfStockProducts[index];
                      final productData = product as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          productData['name'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // added bold
                            color: Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'Out of Stock',
                          style: TextStyle(
                            color: Colors.grey[700],
                          ),
                        ),
                      );
                    },
                  )
                else
                  Text(
                    'สินค้าหมดแล้ว',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontStyle: FontStyle.italic, // added italic
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
