import 'package:flutter/material.dart';

class OrderDetailPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const OrderDetailPage({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายระเอียดคำสั่งซื้อ'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ชื่อผู้ซื้อ: ${data['firstname']} ${data['lastname']}',
                style: Theme.of(context).textTheme.headline6,
              ),
              Text('เบอร์โทร: ${data['phoneNumber']}'),
              Text('สถานะ: ${data['status']}'),
              Text('ราคารวม: \฿${data['total']}'),
              Text('วันที่สั่งซื้อ: ${data['slipDateTime']}'),
              Text('ชื่อธนาคาร: ${data['bankName']}'),
              Text('ชื่อบัญชี: ${data['bankAccountName']}'),
              Text('เลขบัญชี: ${data['accountNumber']}'),
              Text('ที่อยู่: ${data['userAddress']}'),
              const SizedBox(height: 16.0),
              Text(
                'รายการสินค้า:',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 8.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: (data['products'] as List<dynamic>)
                    .map(
                      (productData) => Text(
                        '- ${productData['name']} x ${productData['quantity']}',
                      ),
                    )
                    .toList(),
              ),
              if (data['transferReceiptUrl'] != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16.0),
                    Text(
                      'Transfer Receipt:',
                      style: Theme.of(context).textTheme.subtitle1,
                    ),
                    const SizedBox(height: 8.0),
                    Image.network(
                      data['transferReceiptUrl'],
                      fit: BoxFit.cover,
                      height: 200.0,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
