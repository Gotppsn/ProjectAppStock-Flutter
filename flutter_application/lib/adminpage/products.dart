import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _inStockController = TextEditingController();
  final List<File> _images = [];
  String? _productId;

  // Code to pick an image from the device gallery
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  // Code to remove an image from the _images list
  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  // Code to submit the form and save the product data to Firestore
  Future<void> _submit() async {
    try {
      if (_formKey.currentState!.validate()) {
        final timestamp = DateTime.now();
        final previousProductData =
            await getPreviousProductData(_nameController.text);

        // Upload images to Firebase Storage and get their URLs
        final List<String> imageUrls = await uploadImages(_images);

        // Create or update the product document in Firestore
        if (_productId != null) {
          await updateProduct({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.parse(_priceController.text),
            'inStock': int.parse(_inStockController.text),
            'images': imageUrls,
          });
        } else {
          await createProduct({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'price': double.parse(_priceController.text),
            'inStock': int.parse(_inStockController.text),
            'images': imageUrls,
          });
        }

        // Log previous product data to history collection
        if (previousProductData != null) {
          final previousProductImages =
              List.castFrom(previousProductData['images']);
          await addProductToHistory({
            'name': previousProductData['name'],
            'description': previousProductData['description'],
            'price': previousProductData['price'],
            'inStock': previousProductData['inStock'],
            'images': previousProductImages,
            'updatedBy': FirebaseAuth.instance.currentUser?.email ?? '',
            'updatedAt': FieldValue.serverTimestamp(),
            'changeDetails': {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'price': double.parse(_priceController.text),
              'inStock': int.parse(_inStockController.text),
              'images': imageUrls,
            },
            'changeTimestamp': timestamp,
          });
        }

        // Navigate back to the previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      // Handle any errors
      print('Error: $e');
    }
  }

  // Code to get the previous product data from Firestore
  Future<Map<String, dynamic>?> getPreviousProductData(
      String productName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('name', isEqualTo: productName)
        .limit(1) // Limit the number of results to one
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      final id = snapshot.docs.first.id;
      _productId = id;
      return {...data, 'id': id};
    }
    return null;
  }

  // Code to add a product to the product_history collection
  Future<void> addProductToHistory(Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('product_history').add(data);
  }

  // Code to upload images to Firebase Storage and get their URLs
  Future<List<String>> uploadImages(List<File> images) async {
    List<String> urls = [];

    for (var image in images) {
      // Define a filename for the image using the current timestamp
      String fileName = DateTime.now().millisecondsSinceEpoch.toString() +
          image.path.split('/').last;

      // Upload the image to Firebase Storage at the path "/images/$fileName"
      final Reference ref =
          FirebaseStorage.instance.ref().child('images').child(fileName);
      await ref.putFile(image);

      // Get the download URL of the uploaded image
      final String url = await ref.getDownloadURL();

      // Add the download URL to the list of image URLs
      urls.add(url);
    }

    // Return the list of image URLs
    return urls;
  }

  // Code to create a new product document in Firestore
  Future<void> createProduct(Map<String, dynamic> data) async {
// Generate a new product ID
    final productRef = FirebaseFirestore.instance.collection('products').doc();
    final productId = productRef.id;
    final imageUrls = await uploadImages(_images);
// Set the product ID field using the set() method
    await FirebaseFirestore.instance.collection('products').doc(productId).set({
      ...data,
      'id': productId,
      'inStock': data['inStock'],
      'images': imageUrls,
    });
  }

  // Code to update an existing product document in Firestore
  Future<void> updateProduct(Map<String, dynamic> data) async {
    if (_productId != null) {
      final productRef =
          FirebaseFirestore.instance.collection('products').doc(_productId);
      final productSnapshot = await productRef.get();
      if (productSnapshot.exists) {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(_productId!)
            .update(data);
      }
    }
  }

  // Code to delete the product document from Firestore
  Future<void> deleteProduct() async {
    if (_productId != null) {
      final productRef =
          FirebaseFirestore.instance.collection('products').doc(_productId);
      final productSnapshot = await productRef.get();
      if (productSnapshot.exists) {
        await productRef.delete();
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มสินค้า'),
        actions: [
          IconButton(
            onPressed: deleteProduct,
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'ชื่อสินค้า'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'คำอธิบาย'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Description is required';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'ราคา'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Price is required';
                    } else if (double.tryParse(value) == null) {
                      return 'Price must be a number';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _inStockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'สินค้าคงคลัง'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'In stock is required';
                    } else if (int.tryParse(value) == null) {
                      return 'In stock must be a number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                const Text(
                  'รูปภาพ',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  height: 200.0,
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    children: [
                      ..._images.map((image) {
                        final index = _images.indexOf(image);
                        return Stack(
                          children: [
                            Image.file(image),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ],
                        );
                      }),
                      GestureDetector(
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.add,
                            size: 40.0,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('เพิ่มสินค้า'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
