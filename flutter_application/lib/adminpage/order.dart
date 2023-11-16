import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'order_detail_page.dart';

class OrderManagementPage extends StatefulWidget {
  @override
  _OrderManagementPageState createState() => _OrderManagementPageState();
}

class _OrderManagementPageState extends State<OrderManagementPage> {
  String _statusFilter = '';
  List<String> _displayStatuses = [
    '',
    'รอดำเนินการ',
    'กำลังเตรียมสินค้า',
    'กำลังจัดส่ง',
    'ได้รับสินค้า',
    'ยกเลิก'
  ];
  List<String> _filterStatuses = [
    '',
    'Pending',
    'Preparing',
    'Shipping',
    'Received',
    'Cancelled'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('จัดการคำสั่งซื้อ'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButtonFormField<String>(
              value: _statusFilter,
              items: _displayStatuses
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: _filterStatuses[_displayStatuses.indexOf(value)],
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _statusFilter = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'ค้นหาสถานะ',
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _statusFilter.isEmpty
                  ? FirebaseFirestore.instance
                      .collection('slip_order')
                      .orderBy('slipDateTime', descending: true)
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('slip_order')
                      .where('status', isEqualTo: _statusFilter)
                      .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text('An error occurred. Please try again later.'),
                  );
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No orders found.'),
                  );
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (BuildContext context, int index) {
                    final DocumentSnapshot document =
                        snapshot.data!.docs[index];
                    final Map<String, dynamic> data =
                        document.data()! as Map<String, dynamic>;
                    return ListTile(
                      title: Text(
                        '${data['firstname']} ${data['lastname']} - ${data['slipDateTime']}',
                      ),
                      subtitle: Text(
                        'ราคารวม: \$${data['total']}, ${getStatusText(data['status'])}',
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          _showStatusUpdateDialog(context, document.id);
                        },
                        child: const Text('อัพเดทสถานะ'),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderDetailPage(data: data),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String getStatusText(String status) {
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

  void _showStatusUpdateDialog(BuildContext context, String orderId) {
    String newStatus = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('อัพเดทสถานะสินค้า'),
          content: DropdownButtonFormField(
            value: null,
            items: <String>[
              'Pending',
              'Preparing',
              'Shipping',
              'Received',
              'Cancelled'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(getStatusText(value)),
              );
            }).toList(),
            onChanged: (value) {
              newStatus = value.toString();
            },
            validator: (value) {
              if (value == null) {
                return 'Please select a status.';
              }
              return null;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () async {
                if (newStatus.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a status.'),
                    ),
                  );
                  return;
                }
                await FirebaseFirestore.instance
                    .collection('slip_order')
                    .doc(orderId)
                    .update({'status': newStatus});
                Navigator.of(context).pop();
              },
              child: const Text('อัพเดทสถานะ'),
            ),
          ],
        );
      },
    );
  }
}
