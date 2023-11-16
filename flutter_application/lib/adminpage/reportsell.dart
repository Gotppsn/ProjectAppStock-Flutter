import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportSell extends StatefulWidget {
  const ReportSell({Key? key}) : super(key: key);

  @override
  _ReportSellState createState() => _ReportSellState();
}

class _ReportSellState extends State<ReportSell> {
  String _selectedPeriod = 'Daily';
  String _displayedPeriod = '';
  List<DocumentSnapshot>? _slipOrders;
  double _totalOrders = 0.0;
  String _productName = '';
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _fetchSlipOrders() async {
    DateTime now = DateTime.now();
    DateTime startDate;
    if (_selectedPeriod == 'Daily') {
      startDate = DateTime(now.year, now.month, now.day);
      _displayedPeriod = DateFormat('d MMMM y').format(startDate);
    } else if (_selectedPeriod == 'Weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
      _displayedPeriod =
          '${DateFormat('d MMMM y').format(startDate)} - ${DateFormat('d MMMM y').format(now)}';
    } else if (_selectedPeriod == 'Monthly') {
      startDate = DateTime(now.year, now.month, 1);
      _displayedPeriod = DateFormat('MMMM y').format(startDate);
    } else if (_selectedPeriod == 'Yearly') {
      startDate = DateTime(now.year, 1, 1);
      _displayedPeriod = now.year.toString();
    } else {
      return;
    }

    final endDateTime = now;
    final startDateTime = _startDate == null
        ? startDate
        : DateTime(_startDate!.year, _startDate!.month, _startDate!.day);

    final snap =
        await FirebaseFirestore.instance.collection('slip_order').get();
    List<DocumentSnapshot> slipOrders = snap.docs
        .where((doc) => doc['slipDateTime'] != null)
        .where(
            (doc) => DateTime.parse(doc['slipDateTime']).isAfter(startDateTime))
        .where(
            (doc) => DateTime.parse(doc['slipDateTime']).isBefore(endDateTime))
        .toList();

    // Filter by product name if specified
    if (_productName.isNotEmpty) {
      slipOrders = slipOrders.where((doc) {
        final List<dynamic> products = doc['products'];
        return products.any((product) =>
            (product['name'] as String).toLowerCase().contains(_productName));
      }).toList();
    }

    double totalOrders = 0.0;

    for (DocumentSnapshot slipOrder in slipOrders) {
      final total = slipOrder['total'] is int
          ? slipOrder['total'].toDouble()
          : slipOrder['total'];
      totalOrders += total;
    }

    setState(() {
      _slipOrders = slipOrders;
      _totalOrders = totalOrders;
    });
  }

  @override
  void initState() {
    _fetchSlipOrders();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showOrderDetails(DocumentSnapshot slipOrder) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('รายระเอียดคำสั่งซื้อ'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ชื่อ: ${slipOrder['firstname']} ${slipOrder['lastname']}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'เบอร์โทร: ${slipOrder['phoneNumber']}',
                ),
                const SizedBox(height: 16),
                Text(
                  'ที่อยู่: ${slipOrder['userAddress']}',
                ),
                const SizedBox(height: 16),
                Text(
                  'ธนาคาร: ${slipOrder['bankName']}',
                ),
                const SizedBox(height: 16),
                Text(
                  'ชื่อบัญชี: ${slipOrder['bankAccountName']}',
                ),
                const SizedBox(height: 16),
                Text(
                  'เลขบัญชี: ${slipOrder['accountNumber']}',
                ),
                const SizedBox(height: 16),
                Text(
                  'วันที่สั่งซื้อสินค้า: ${DateFormat('d MMMM y, hh:mm a').format(DateTime.parse(slipOrder['slipDateTime']))}',
                ),
                const SizedBox(height: 16),
                Text(
                  'ยอดรวม: \฿${slipOrder['total'].toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'สินค้า:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                for (final product in slipOrder['products'])
                  Text(
                    '${product['name']} x ${product['quantity']}',
                  ),
                const SizedBox(height: 16),
                if (slipOrder['transferReceiptUrl'] != null)
                  Image.network(
                    slipOrder['transferReceiptUrl'],
                    height: 200,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายงาน ($_selectedPeriod)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'ชื่อสินค้า',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _productName = value.toLowerCase();
                      });
                      _fetchSlipOrders();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'เริ่มวันที่',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2010),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        setState(() {
                          _startDate =
                              DateTime(date.year, date.month, date.day);
                        });
                        _fetchSlipOrders();
                      }
                    },
                    readOnly: true,
                    controller: _startDate == null
                        ? null
                        : TextEditingController(
                            text: DateFormat('d MMM y').format(_startDate!),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'จบวันที่',
                      border: OutlineInputBorder(),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2010),
                        lastDate: DateTime(2100),
                      );

                      if (date != null) {
                        setState(() {
                          _endDate = DateTime(date.year, date.month, date.day);
                        });
                        _fetchSlipOrders();
                      }
                    },
                    readOnly: true,
                    controller: _endDate == null
                        ? null
                        : TextEditingController(
                            text: DateFormat('d MMM y').format(_endDate!),
                          ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedPeriod,
              onChanged: (newValue) {
                setState(() {
                  _selectedPeriod = newValue!;
                  _fetchSlipOrders();
                });
              },
              items: ['Daily', 'Weekly', 'Monthly', 'Yearly']
                  .map<DropdownMenuItem<String>>((value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text(
              'รายงานการขายสำหรับ $_displayedPeriod',
              style: Theme.of(context).textTheme.headline6,
            ),
            const SizedBox(height: 16),
            Text(
              'ยอดขายทั้งหมด: \฿${_totalOrders.toStringAsFixed(2)}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _slipOrders == null
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: [
                          const DataColumn(
                            label: Text('วันที่'),
                          ),
                          const DataColumn(
                            label: Text('ชื่อผู้ซื้อ'),
                          ),
                          const DataColumn(
                            label: Text('ราคา'),
                          ),
                        ],
                        rows: _slipOrders!.map((slipOrder) {
                          final slipDateTime =
                              DateTime.parse(slipOrder['slipDateTime']);
                          final username =
                              '${slipOrder['firstname']} ${slipOrder['lastname']}';
                          final total = slipOrder['total'] is int
                              ? slipOrder['total'].toDouble()
                              : slipOrder['total'];
                          final slipDate =
                              DateFormat('d MMM y').format(slipDateTime);
                          return DataRow(
                            cells: [
                              DataCell(Text(slipDate)),
                              DataCell(
                                TextButton(
                                  onPressed: () {
                                    _showOrderDetails(slipOrder);
                                  },
                                  child: Text(username),
                                ),
                              ),
                              DataCell(Text('\฿${total.toStringAsFixed(2)}')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
