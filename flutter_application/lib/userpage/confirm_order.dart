import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application/auth_page.dart';
import 'package:flutter_application/userpage/user_menu.dart';
import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ignore: must_be_immutable
class StatusPage extends StatefulWidget {
  final double total;
  List<String> cartProducts;
  List<int> productQuantities;

  StatusPage({
    Key? key,
    required this.total,
    required this.cartProducts,
    required this.productQuantities,
  }) : super(key: key);

  @override
  _StatusPageState createState() => _StatusPageState();
}

class _StatusPageState extends State<StatusPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime? _slipDateTime;
  PickedFile? _pickedFile;
  late User? _user;

  late TextEditingController _bankNameController;
  late TextEditingController _accountNameController;
  late TextEditingController _accountNumberController;

  @override
  void initState() {
    super.initState();

    _user = FirebaseAuth.instance.currentUser;

    _bankNameController = TextEditingController();
    _accountNameController = TextEditingController();
    _accountNumberController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ยืนยันคำสั่งซื้อ ชำระเงิน'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'ราคาชำระ: \฿${widget.total.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headline6,
              ),
              const SizedBox(height: 16.0),
              Text(
                'ธนาคารปลายทางที่ชำระ: SCB ไทยพาณิชย์',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Text(
                'เลขบัญชี: 4403705031',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              Text(
                'ชื่อบัญชี: บริษัท ส.การยาง',
                style: Theme.of(context).textTheme.subtitle1,
              ),
              const SizedBox(height: 16.0),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text(
                      'กรอกรายระเอียดการชำระ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16.0),
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(_user!.uid)
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            // Retrieve user data and assign default values
                            final Map<String, dynamic> userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            String bankName = userData['bankName'] ?? '';
                            String accountName =
                                userData['bankAccountName'] ?? '';
                            String accountNumber =
                                userData['accountNumber'] ?? '';

                            // Update the form fields asynchronously
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _bankNameController.text = bankName;
                              _accountNameController.text = accountName;
                              _accountNumberController.text = accountNumber;
                            });

                            // Return the form fields
                            return Column(
                              children: [
                                TextFormField(
                                  controller: _bankNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'ธนาคารของคุณ',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'โปรดกรอกธนาคารของคุณ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _accountNameController,
                                  onChanged: (value) {},
                                  decoration: const InputDecoration(
                                    labelText: 'ชื่อบัญชีของคุณ',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'โปรดกรอกชื่อบัญชีของคุณ';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16.0),
                                TextFormField(
                                  controller: _accountNumberController,
                                  onChanged: (value) {},
                                  decoration: const InputDecoration(
                                    labelText: 'เลขบัญชีของคุณ',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'โปรกรอกเลขบัญชีของคุณ';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            );
                          } else {
                            return const Text('No user data found');
                          }
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    DateTimeField(
                      decoration: const InputDecoration(
                        labelText: 'วันที่และเวลา ที่ชำระเงิน',
                        border: OutlineInputBorder(),
                      ),
                      format: DateFormat.yMd().add_jm(),
                      onChanged: (dateTime) {
                        setState(() {
                          _slipDateTime = dateTime;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'โปรดกรอก วันที่และเวลา ที่ชำระเงิน';
                        }
                        return null;
                      },
                      onShowPicker: (context, currentValue) async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: currentValue ?? DateTime.now(),
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                          builder: (BuildContext context, Widget? child) {
                            return Theme(
                              data: ThemeData.dark(),
                              child: child ?? const SizedBox.shrink(),
                            );
                          },
                        );

                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.fromDateTime(
                                currentValue ?? DateTime.now()),
                          );

                          if (time != null) {
                            return DateTimeField.combine(date, time);
                          } else {
                            return currentValue;
                          }
                        } else {
                          return currentValue;
                        }
                      },
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: () async {
                        final pickedFile = await ImagePicker().pickImage(
                          source: ImageSource.gallery,
                        );

                        setState(() {
                          _pickedFile = pickedFile == null
                              ? null
                              : PickedFile(pickedFile.path);
                        });
                      },
                      child: const Text('เลือกรูปภาพสลิปการโอนเงิน'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'รายการเอียดคำสั่งซื้อ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  // Display product names and quantities
                  for (int i = 0; i < widget.cartProducts.length; i++)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('products')
                          .doc(widget.cartProducts[i])
                          .get(),
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final productData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            final productName = productData['name'];
                            final productQuantity = widget.productQuantities[i];
                            return Text('$productName x $productQuantity');
                          } else {
                            return const Text('Product not found');
                          }
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),

                  // Display user name, phone number, and address
                  const SizedBox(height: 16.0),
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_user!.uid)
                        .get(),
                    builder: (BuildContext context,
                        AsyncSnapshot<DocumentSnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final userData =
                              snapshot.data!.data()! as Map<String, dynamic>;
                          final firstname = userData['firstName'] as String;
                          final lastname = userData['lastName'] as String;
                          final phoneNumber = userData['phone'] as String;
                          final address = userData['address'] as String;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ชื่อ: $firstname  $lastname'),
                              const SizedBox(height: 8.0),
                              Text('เบอร์โทร: $phoneNumber'),
                              const SizedBox(height: 8.0),
                              Text('ที่อยู่: $address'),
                            ],
                          );
                        } else {
                          return const Text('User data not found');
                        }
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                  const SizedBox(height: 16.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ใบเสร็จการโอนเงิน',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8.0),
                      if (_pickedFile != null)
                        SizedBox(
                          width: double.infinity,
                          height: 200,
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: Image.file(
                              File(_pickedFile!.path),
                            ),
                          ),
                        )
                      else
                        const Text('ยังไม่ใส่รูปใบเสร็จ'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _confirmOrder(context, widget.total);
                  }
                },
                child: const Text('ยืนยันรายการ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmOrder(context, double total) async {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthPage()),
      );
    } else {
      try {
        final batch = FirebaseFirestore.instance.batch();

// Get the product info for each item in the cart
        final productDocs = await FirebaseFirestore.instance
            .collection('products')
            .where(FieldPath.documentId, whereIn: widget.cartProducts)
            .get();

        final products = productDocs.docs
            .map((doc) => {'id': doc.id, ...doc.data()})
            .toList();

        // Add each product to the slip order
        final productData = <dynamic>[];
        for (int i = 0; i < widget.cartProducts.length; i++) {
          final productId = widget.cartProducts[i];
          final product = products.firstWhere((p) => p['id'] == productId);
          final productQuantity = widget.productQuantities[i];
          productData.add({
            'name': product['name'],
            'quantity': productQuantity,
          });
        }

        for (int i = 0; i < widget.cartProducts.length; i++) {
          final productId = widget.cartProducts[i];
          final productQuantity = widget.productQuantities[i];
          final productDoc =
              FirebaseFirestore.instance.collection('products').doc(productId);

          // Get the product data first
          final productDocSnapshot = await productDoc.get();
          final productData = productDocSnapshot.data();

          if (productData == null) {
            throw Exception('Product not found');
          }

          Map<String, dynamic>? inStock;
          if (productData['inStock'] is int) {
            inStock = {'count': productData['inStock']};
          } else {
            inStock = productData['inStock'] as Map<String, dynamic>?;
          }
          final currentQuantity =
              inStock != null ? inStock['count'] as int? : null;

          if (currentQuantity == null || currentQuantity < productQuantity) {
            throw Exception(
                'Not enough stock for product $productId, only $currentQuantity left in stock.');
          }

          final newInStockCount = (inStock?['count'] as int) - productQuantity;
          if (newInStockCount < 0) {
            throw Exception(
                'Not enough stock for product $productId, only ${inStock?['count']} left in stock.');
          }

          batch.update(productDoc, {
            'quantity': currentQuantity - productQuantity,
            'inStock': {
              'count': newInStockCount,
            },
          });

          print('Decreasing stock count for $productId by $productQuantity');
          print('Current quantity is $currentQuantity');
          print('New quantity is ${currentQuantity - productQuantity}');
        }

// Commit the batch operation to update the database
        await batch.commit();

        String? imageUrl;
        if (_pickedFile != null) {
          final fileName =
              'transfer_receipt_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final ref = firebase_storage.FirebaseStorage.instance
              .ref('slip_order/$fileName');
          final task = ref.putFile(File(_pickedFile!.path));
          final snapshot = await task.whenComplete(() {});
          imageUrl = await snapshot.ref.getDownloadURL();
        }

        // Save slip order details to Cloud Firestore
        final slipOrderDocRef =
            FirebaseFirestore.instance.collection('slip_order').doc();

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data()!;

        await slipOrderDocRef.set({
          'userId': user.uid,
          'firstname': userData['firstName'],
          'lastname': userData['lastName'],
          'phoneNumber': userData['phone'],
          'status': 'Pending',
          'total': total,
          'slipDateTime': _slipDateTime!.toIso8601String(),
          'bankName': userData['bankName'],
          'bankAccountName': userData['bankAccountName'],
          'accountNumber': userData['accountNumber'],
          'transferReceiptUrl': imageUrl,
          'userAddress': userData['address'],
          'products': productData,
        });

        // Clear the user's cart
        if (user.uid.isNotEmpty && widget.cartProducts.isNotEmpty) {
          final cartDocs = await FirebaseFirestore.instance
              .collection('carts')
              .where('userId', isEqualTo: user.uid)
              .where('productId', whereIn: widget.cartProducts)
              .get();

          int itemsDeleted = 0;
          if (cartDocs.docs.isNotEmpty) {
            final batch = FirebaseFirestore.instance.batch();
            for (final cartDoc in cartDocs.docs) {
              batch.delete(cartDoc.reference);
              print('Deleting cart ${cartDoc.id}');
              itemsDeleted++;
            }

            final productIds = widget.cartProducts.toSet().toList();
            for (final productId in productIds) {
              final productRef = FirebaseFirestore.instance
                  .collection('products')
                  .doc(productId);
              final productData = await productRef.get();
              final inStockRef = productRef;
              final inStockData = await inStockRef.get();
              final productQuantity = widget.productQuantities
                  .where(
                      (quantity) => widget.cartProducts.indexOf(productId) >= 0)
                  .fold<int>(0, (sum, item) => sum + item);

              if (!productData.exists || !inStockData.exists) {
                throw 'Product not found';
              }

              // Update the product data with the new quantity and inStock count
              batch.update(productRef, {
                'quantity': productData.data()!['quantity']! - productQuantity,
                'inStock.count':
                    inStockData.data()!['count']! - productQuantity,
              });

              print(
                  'Decreasing product $productId quantity by $productQuantity');
            }

            await batch.commit();

            // Clear cart products and product quantities
            setState(() {
              widget.cartProducts.clear();
              widget.productQuantities.clear();
            });
          } else {
            print('No carts found for user ${user.uid}');
          }

          print(
              'Deleted $itemsDeleted cart items and ${cartDocs.docs.length} cart for user ${user.uid}');
        } else {
          print('Empty cart for user ${user.uid}');
        }

        // Navigate to CartPage with cleared cart
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserMenu(
              pageIndex: 1,
              cartProducts: [],
              productQuantities: [],
            ),
          ),
        );
      } catch (e) {
        print('Error confirming order: $e');
      }
    }
  }
}
