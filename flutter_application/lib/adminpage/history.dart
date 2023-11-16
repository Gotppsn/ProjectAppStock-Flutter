import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HistoryListItem extends StatefulWidget {
  final Map<String, dynamic> data;

  HistoryListItem(this.data, {Key? key}) : super(key: key);

  @override
  _HistoryListItemState createState() => _HistoryListItemState();
}

class _HistoryListItemState extends State<HistoryListItem> {
  bool showDetails = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text('สินค้า: ${widget.data['name']}'),
          subtitle: Text('แก้ไขโดย: ${widget.data['updatedBy']}'),
          trailing: Text(widget.data['updatedAt'].toDate().toString()),
          onTap: () => setState(() {
            showDetails = !showDetails;
          }),
        ),
        if (showDetails)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รหัสสินค้า: ${widget.data['productId']}'),
                Text(
                    'คำอธิบาย: ${widget.data['changeDetails']['description']}'),
                Text('ราคา: ${widget.data['changeDetails']['price']}'),
                Text(
                    'สินค้าในคลัง: ${widget.data['changeDetails']['inStock']}'),
              ],
            ),
          ),
      ],
    );
  }
}

class History extends StatefulWidget {
  const History({Key? key}) : super(key: key);

  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {
  CollectionReference _historyCollection =
      FirebaseFirestore.instance.collection('product_history');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการแก้ไข'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              showConfirmationDialog(context);
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _historyCollection.snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          List sortedData = snapshot.data!.docs.reversed.toList()
            ..sort((a, b) => b['updatedAt'].compareTo(a['updatedAt']));

          return ListView.builder(
            itemCount: sortedData.length,
            itemBuilder: (BuildContext context, int index) => Card(
              child: HistoryListItem(
                  sortedData[index].data() as Map<String, dynamic>),
            ),
          );
        },
      ),
    );
  }

  Future<void> showConfirmationDialog(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("ยืนยันลบข้อมูลทั้งหมด"),
            content: const Text("คุณแน่ใจจะลบข้อมูลทั้งหมดหรือไม่"),
            actions: [
              TextButton(
                child: const Text("ยกเลิก"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("ลบทั้งหมด"),
                onPressed: () async {
                  await _historyCollection.get().then((snapshot) {
                    for (DocumentSnapshot ds in snapshot.docs) {
                      ds.reference.delete();
                    }
                  });
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
