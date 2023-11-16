import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ReportOrderPage extends StatefulWidget {
  const ReportOrderPage({Key? key}) : super(key: key);

  @override
  _ReportOrderPageState createState() => _ReportOrderPageState();
}

class _ReportOrderPageState extends State<ReportOrderPage> {
  late CollectionReference slipOrdersRef;
  List<OrderGroup> orderGroups = [];

  @override
  void initState() {
    super.initState();
    slipOrdersRef = FirebaseFirestore.instance.collection('slip_order');
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานคำสั่งซื้อ'),
      ),
      body: ListView.separated(
        separatorBuilder: (context, index) => const Divider(),
        itemCount: orderGroups.length,
        itemBuilder: (context, index) {
          final orderGroup = orderGroups[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(orderGroup.dateHeader),
              ),
              ...orderGroup.slipOrders.map((slipOrder) => Card(
                    child: ListTile(
                      title:
                          Text('${slipOrder.firstname} ${slipOrder.lastname}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text('เบอร์โทร: ${slipOrder.phoneNumber}'),
                          Text('สถานะ: ${slipOrder.status}'),
                          const SizedBox(height: 4),
                          OutlinedButton(
                            onPressed: () {
                              _showDetailsDialog(slipOrder);
                            },
                            child: const Text('ดูเพิ่มเติม'),
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showDetailsDialog(SlipOrder order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ชื่อผู้ซื้อ: ${order.firstname} ${order.lastname}'),
                const SizedBox(height: 8),
                Text('เบอร์โทร: ${order.phoneNumber}'),
                const SizedBox(height: 8),
                Text('ที่อยู่: ${order.userAddress}'),
                const SizedBox(height: 8),
                Text('Slip Date Time: ${order.slipDateTime.toString()}'),
                const SizedBox(height: 8),
                Text('ธนาคาร: ${order.bankName}'),
                const SizedBox(height: 8),
                Text('ชื่อบัญชี: ${order.bankAccountName}'),
                const SizedBox(height: 8),
                Text('เลขบัญชี: ${order.accountNumber}'),
                const SizedBox(height: 8),
                Text('สถานะ: ${order.status}'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _fetchData() async {
    try {
      final snapshot =
          await slipOrdersRef.orderBy('slipDateTime', descending: true).get();
      final slipOrders =
          snapshot.docs.map((doc) => SlipOrder.fromDocument(doc)).toList();
      final orderGroups = _groupOrdersByDate(slipOrders);
      setState(() {
        this.orderGroups = orderGroups;
      });
    } catch (e) {
      print('Error fetching slip orders: $e');
    }
  }

  List<OrderGroup> _groupOrdersByDate(List<SlipOrder> slipOrders) {
    final groups = <OrderGroup>[];
    DateTime? currentDate;
    List<SlipOrder>? currentOrders;
    for (final order in slipOrders) {
      final orderDate = order.slipDateTime.date;
      if (currentDate == null || orderDate != currentDate) {
        if (currentDate != null && currentOrders != null) {
          final dateHeader = currentDate.format('MMMM dd, yyyy');
          groups.add(
              OrderGroup(dateHeader: dateHeader, slipOrders: currentOrders));
        }
        currentDate = orderDate;
        currentOrders = [];
      }
      currentOrders!.add(order);
    }
    if (currentDate != null && currentOrders != null) {
      final dateHeader = currentDate.format('MMMM dd, yyyy');
      groups.add(OrderGroup(dateHeader: dateHeader, slipOrders: currentOrders));
    }
    return groups;
  }
}

class SlipOrder {
  final String id;
  final String firstname;
  final String lastname;
  final String phoneNumber;
  final String userAddress;
  final DateTime slipDateTime;
  final String bankName;
  final String bankAccountName;
  final String accountNumber;
  final String status;

  SlipOrder({
    required this.id,
    required this.firstname,
    required this.lastname,
    required this.phoneNumber,
    required this.userAddress,
    required this.slipDateTime,
    required this.bankName,
    required this.bankAccountName,
    required this.accountNumber,
    required this.status,
  });

  factory SlipOrder.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SlipOrder(
      id: doc.id,
      firstname: data['firstname'] ?? '',
      lastname: data['lastname'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      userAddress: data['userAddress'] ?? '',
      slipDateTime: DateTime.parse(data['slipDateTime'] ?? ''),
      bankName: data['bankName'] ?? '',
      bankAccountName: data['bankAccountName'] ?? '',
      accountNumber: data['accountNumber'] ?? '',
      status: data['status'] ?? '',
    );
  }
}

class OrderGroup {
  final String dateHeader;
  final List<SlipOrder> slipOrders;

  OrderGroup({
    required this.dateHeader,
    required this.slipOrders,
  });
}

extension DateTimeUtils on DateTime {
  DateTime get date => DateTime(year, month, day);

  String format(String pattern) {
    final formatter = DateFormat(pattern);
    return formatter.format(this);
  }
}
