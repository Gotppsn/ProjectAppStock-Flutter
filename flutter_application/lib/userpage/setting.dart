import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application/userpage/utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNameController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  User? _currentUser;
  File? _image;
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.email != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .then((documentSnapshot) {
        if (documentSnapshot.exists) {
          final data = documentSnapshot.data();
          setState(() {
            _currentUser = currentUser;
            _firstNameController.text = data?['firstName'] ?? '';
            _lastNameController.text = data?['lastName'] ?? '';
            _phoneController.text = data?['phone'] ?? '';
            _addressController.text = data?['address'] ?? '';
            _imageUrl = data?['imageUrl'];
            _bankNameController.text = data?['bankName'];
            _bankAccountNameController.text = data?['bankAccountName'];
            _accountNumberController.text = data?['accountNumber'];
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = _image != null
        ? Image.file(
            _image!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          )
        : _imageUrl != null
            ? Image.network(
                _imageUrl!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              )
            : const Icon(
                Icons.account_circle_rounded,
                size: 120,
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('ตั้งค่าบัญชี'),
        actions: [
          IconButton(
            onPressed: () async {
              // Update user profile information
              await _updateProfile();
            },
            icon: const Icon(Icons.check),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: () async {
                final imagePicker = ImagePicker();

                // Allow the user to select an image from their device
                final image = await imagePicker.pickImage(
                  source: ImageSource.gallery,
                );

                if (image != null) {
                  final imageFile = File(image.path);
                  setState(() {
                    _image = imageFile;
                  });
                }
              },
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: profileImage,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อจริง',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'นามสกุล',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: const InputDecoration(
                labelText: 'เบอร์โทร',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'ที่อยู่',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อธนาคาร',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bankAccountNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อบัญชี',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: 'เลขบัญชี',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateProfile() async {
    try {
      if (_currentUser != null) {
        // Update the display name to the first name
        final firstName = _firstNameController.text;
        final lastName = _lastNameController.text;
        var phone = _phoneController.text;
        final address = _addressController.text;
        final bankName = _bankNameController.text;
        final bankAccountName = _bankAccountNameController.text;
        final accountNumber = _accountNumberController.text;

        await _currentUser!.updateDisplayName(firstName);

        // Format phone number as +[country code][phone number]
        final countryCode =
            '+66'; // Replace with the country code for your region
        phone = '$countryCode$phone';

        // Update user data in Firestore
        final userUid = _currentUser!.uid;
        Map<String, dynamic> userData = {
          'firstName': firstName,
          'lastName': lastName,
          'phone': phone,
          'address': address,
          'bankName': bankName,
          'bankAccountName': bankAccountName,
          'accountNumber': accountNumber,
        };
        if (_imageUrl != null) {
          userData['imageUrl'] = _imageUrl!;
        }
        FirebaseFirestore.instance
            .collection('users')
            .doc(userUid)
            .set(userData, SetOptions(merge: true));

        // Show successful update message
        showToast(context, 'Profile successfully updated!');
      }
    } catch (e) {
      // Show error message
      showToast(context, 'Error updating profile: $e');
    }
  }
}
