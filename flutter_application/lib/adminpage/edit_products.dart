import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _inStockController = TextEditingController();
  final List<File> _images = [];
  List<String> _imageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  // Load the details of the product with the given ID
  Future<void> _loadProductDetails() async {
    try {
      final productSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .get();

      if (productSnapshot.exists) {
        final product = productSnapshot.data()!;
        _nameController.text = product['name'];
        _descriptionController.text = product['description'];
        _priceController.text = product['price'].toString();
        _inStockController.text = product['inStock'].toString();
        _imageUrls = List<String>.from(product['images']);
      }
    } catch (e) {
      // Handle any errors
      print('Error: $e');
    }
  }

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

  // Code to submit the form and update the product details in Firestore
  Future<void> _submit() async {
    try {
      if (_formKey.currentState!.validate()) {
        final timestamp = DateTime.now();

        // Get the previous details of the product
        final productSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .get();
        final previousProductData =
            productSnapshot.exists ? productSnapshot.data() : null;

        // If there are new images, upload them to Firebase Storage and get their URLs
        if (_images.isNotEmpty) {
          _imageUrls = await uploadImages(_images);
        }

        // Update the value of _inStockController based on the sold count and the value entered in the form
        final inStockString = _inStockController.text.trim();
        final inStockMatch = RegExp(r'\b\d+\b').firstMatch(inStockString);
        final inStock =
            inStockMatch != null ? int.parse(inStockMatch.group(0)!) : 0;
        _inStockController.text = inStock.toString();

        // Update the product details in the Firestore database
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.productId)
            .update({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'price': double.parse(_priceController.text),
          'inStock': inStock,
          'images': _imageUrls,
        });

        // Log previous product data to history collection
        if (previousProductData != null) {
          final previousProductImages =
              List.castFrom(previousProductData['images']);
          await addProductToHistory({
            'productId': widget.productId,
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
              'inStock': inStock,
              'images': _imageUrls,
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
  Future<Map<String, dynamic>?> getPreviousProductData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .doc(widget.productId)
        .get();

    if (snapshot.exists) {
      return snapshot.data();
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
      Reference ref =
          FirebaseStorage.instance.ref().child('images').child(fileName);
      await ref.putFile(image);

      // Get the download URL of the uploaded image
      String url = await ref.getDownloadURL();

      // Add the download URL to the list of image URLs
      urls.add(url);
    }

    // Return the list of image URLs
    return urls;
  }

  // Code to delete the product document from Firestore
  Future<void> _deleteProduct() async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .delete();
      Navigator.pop(context);
    } catch (e) {
      // Handle any errors
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('แก้ไขสินค้า'),
        actions: [
          IconButton(
            onPressed: _deleteProduct,
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
                  decoration: const InputDecoration(labelText: 'ชื่อ'),
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
                  decoration: const InputDecoration(labelText: 'สินค้าในคลัง'),
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
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  children: [
                    ..._imageUrls.map((url) {
                      final index = _imageUrls.indexOf(url);
                      return Stack(
                        children: [
                          Image.network(
                            url,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                            alignment: Alignment.center,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => setState(() {
                                _imageUrls.removeAt(index);
                              }),
                            ),
                          ),
                        ],
                      );
                    }),
                    ..._images.map((image) {
                      final index = _images.indexOf(image);
                      return Stack(
                        children: [
                          Image.file(
                            image,
                            fit: BoxFit.cover,
                            height: double.infinity,
                            width: double.infinity,
                            alignment: Alignment.center,
                          ),
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
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('อัพเดทการแก้ไข'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
