import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderStatus extends StatelessWidget {
  const OrderStatus({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Navigate to the login screen if user is not logged in
      return const Text('Please log in to view your orders.');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('สถานะคำสั่งซื้อ'),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('slip_order')
            .where('userId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data!.docs;
          if (documents.isEmpty) {
            return const Center(child: Text('You have no orders.'));
          }

          // Sort the orders by date descending
          documents.sort((d1, d2) {
            final slipDateTime1 = (d1.data()
                as Map<String, dynamic>?)?['slipDateTime'] as String?;
            final t1 = slipDateTime1 != null
                ? Timestamp.fromDate(DateTime.parse(slipDateTime1))
                : null;
            final slipDateTime2 = (d2.data()
                as Map<String, dynamic>?)?['slipDateTime'] as String?;
            final t2 = slipDateTime2 != null
                ? Timestamp.fromDate(DateTime.parse(slipDateTime2))
                : null;
            if (t1 == null || t2 == null) {
              return 0;
            }
            return -t1.compareTo(t2);
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final data = documents[index].data() as Map<String, dynamic>;
              String? statusText;
              if (data.containsKey('status') && data['status'] != null) {
                if (data['status'] == 'Preparing') {
                  statusText = 'Preparing the product';
                } else if (data['status'] == 'Pending') {
                  statusText = 'The product has been confirmed';
                } else if (data['status'] == 'Shipping') {
                  statusText = 'The product is being shipped';
                } else if (data['status'] == 'Received') {
                  statusText = 'The product has been received';
                }
              }

              final slipDateTime = (data['slipDateTime'] != null)
                  ? DateTime.parse(data['slipDateTime'])
                  : null;

              return InkWell(
                onTap: () async {
                  final productId = data['products'][0]['productId'];
                  final productDoc = await FirebaseFirestore.instance
                      .collection('products')
                      .doc(productId)
                      .get();
                  final productData = productDoc.data();
                  _showOrderDetails(context, data, productData);
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.6,
                              child: Text(
                                'รหัสสินค้า: ${documents[index].id}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            statusText != null
                                ? Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color:
                                                getStatusColor(data['status']),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            getThaiStatus(data['status']),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        if (data['status'] ==
                                            'Shipping') // Only show the Confirm Order button if status is 'Shipping'
                                          ElevatedButton(
                                            onPressed: () async {
                                              // Update the status to 'Received'
                                              await FirebaseFirestore.instance
                                                  .collection('slip_order')
                                                  .doc(documents[index].id)
                                                  .update({
                                                'status': 'Received',
                                              });
                                            },
                                            child:
                                                const Text('ได้รับสินค้าแล้ว'),
                                          ),
                                      ],
                                    ),
                                  )
                                : const SizedBox(),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'ราคารวม: \฿${(data['total'] as double?)?.toStringAsFixed(2) ?? ''}'),
                        const SizedBox(height: 8),
                        Text(
                          'วันที่สั่งซื้อสินค้า: ${slipDateTime != null ? DateFormat.yMd().add_jm().format(slipDateTime) : ''}',
                        ),
                        const SizedBox(height: 8),
                        if (data['transferReceiptUrl'] != null) ...[
                          const SizedBox(height: 8),
                          Image.network(
                            data['transferReceiptUrl'] as String,
                            height: 200,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color getStatusColor(String? status) {
    switch (status) {
      case 'Pending':
        return Colors.amber;
      case 'Preparing':
        return Colors.blue;
      case 'Shipping':
        return Colors.green;
      case 'Received':
        return Colors.teal;
      case 'Cancelled':
        return Color.fromARGB(255, 150, 0, 0);
      default:
        return Colors.grey;
    }
  }

  String getThaiStatus(String? status) {
    switch (status) {
      case 'Pending':
        return 'รอดำเนินการ';
      case 'Preparing':
        return 'กำลังเตรียมสินค้า';
      case 'Shipping':
        return 'กำลังจัดส่ง';
      case 'Received':
        return 'ได้รับสินค้า';
      case 'Cancelled':
        return 'ยกเลิก';
      default:
        return 'ไม่ทราบสถานะ';
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> orderData,
      [Map<String, dynamic>? productData]) async {
    final products = List<Map<String, dynamic>>.from(orderData['products']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('รายระเอียดคำสั่งซื้อ'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ราคารวม: \฿${(orderData['total'] as double?)?.toStringAsFixed(2) ?? ''}',
                ),
                const SizedBox(height: 8),
                Text(
                  'วันที่สั่งซื้อ: ${(orderData['slipDateTime'] as String?) ?? 'N/A'}',
                ),
                const SizedBox(height: 8),
                if (orderData['status'] != null)
                  Text('สถานะสินค้า: ${getThaiStatus(orderData['status'])}'),
                const SizedBox(height: 8),
                if (orderData['transferReceiptUrl'] != null)
                  Image.network(
                    orderData['transferReceiptUrl'] as String,
                    height: 200,
                  ),
                const SizedBox(height: 16),
                Text('ข้อมูลลูกค้า:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                    'ชื่อ: ${(orderData['firstname'] ?? '')} ${(orderData['lastname'] ?? '')}'),
                const SizedBox(height: 8),
                Text('เบอร์โทร: ${(orderData['phoneNumber'] ?? '')}'),
                const SizedBox(height: 8),
                Text('ที่อยู่: ${(orderData['userAddress'] ?? '')}'),
                const SizedBox(height: 16),
                Text('ข้อมูลสินค้า:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(products.length, (index) {
                    final product = products[index];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('สินค้าที่ ${index + 1}:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.secondary)),
                        const SizedBox(height: 8),
                        Text('ชื่อสินค้า: ${product['name'] ?? 'N/A'}'),
                        Text('จำนวน: ${product['quantity'] ?? 'N/A'}'),
                        const SizedBox(height: 16),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
