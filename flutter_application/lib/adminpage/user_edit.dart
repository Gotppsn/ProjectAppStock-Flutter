import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserEditPage extends StatefulWidget {
  const UserEditPage({Key? key}) : super(key: key);

  @override
  State<UserEditPage> createState() => _UserEditPageState();
}

class _UserEditPageState extends State<UserEditPage> {
  List<UserData> userList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  Stream<QuerySnapshot> _stream() {
    if (_searchController.text.isEmpty) {
      return FirebaseFirestore.instance.collection('users').snapshots();
    }
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('email')
        .startAt([_searchController.text]).endAt(
            [_searchController.text + '\uf8ff']).snapshots();
  }

  Future<void> getUsers() async {
    _stream().listen((querySnapshot) {
      userList = querySnapshot.docs
          .map((document) => UserData.fromFirestore(document))
          .toList();

      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดการบัญชีผู้ใช้'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'ค้าหาผู้ใช้...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: userList.length,
              itemBuilder: (context, index) {
                final userData = userList[index];
                final userEmail = userData.email;
                final userRole = userData.role;

                return ListTile(
                  leading: Icon(Icons.account_circle_rounded),
                  title: Text(userEmail),
                  subtitle: Text('สถานะ: $userRole'),
                  trailing: Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return UserEditDetailsPage(userEmail: userEmail);
                      }),
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
}

class UserData {
  final String email;
  final String firstName;
  final String lastName;
  final String docId;
  final String role;
  final String phone;
  final String address;
  final String? imageUrl;
  final String bankName;
  final String bankAccountName;
  final String accountNumber;

  UserData({
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.docId,
    required this.role,
    required this.phone,
    required this.address,
    this.imageUrl,
    required this.bankName,
    required this.bankAccountName,
    required this.accountNumber,
  });

  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final email = data['email'] ?? '';
    final firstName = data['firstName'] ?? '';
    final lastName = data['lastName'] ?? '';
    final role = data['role'] ?? '';
    final phone = data['phone'] ?? '';
    final address = data['address'] ?? '';
    final imageUrl = data['imageUrl'];
    final bankName = data['bankName'] ?? '';
    final bankAccountName = data['bankAccountName'] ?? '';
    final accountNumber = data['accountNumber'] ?? '';
    final docId = doc.id;
    return UserData(
      email: email,
      firstName: firstName,
      lastName: lastName,
      docId: docId,
      role: role,
      phone: phone,
      address: address,
      imageUrl: imageUrl,
      bankName: bankName,
      bankAccountName: bankAccountName,
      accountNumber: accountNumber,
    );
  }
}

class UserEditDetailsPage extends StatefulWidget {
  final String userEmail;

  const UserEditDetailsPage({required this.userEmail, Key? key})
      : super(key: key);

  @override
  State<UserEditDetailsPage> createState() => _UserEditDetailsPageState();
}

class _UserEditDetailsPageState extends State<UserEditDetailsPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _bankAccountNameController =
      TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final TextEditingController _roleController = TextEditingController();
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userEmail)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      final userData = UserData.fromFirestore(querySnapshot.docs.first);
      _userData = userData;
      _firstNameController.text = userData.firstName;
      _lastNameController.text = userData.lastName;
      _phoneController.text = userData.phone;
      _addressController.text = userData.address;
      _bankNameController.text = userData.bankName;
      _bankAccountNameController.text = userData.bankAccountName;
      _accountNumberController.text = userData.accountNumber;
      _roleController.text = userData.role;
    }

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> updateUser() async {
    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(_userData!.docId);

      final updatedData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'bankName': _bankNameController.text,
        'bankAccountName': _bankAccountNameController.text,
        'accountNumber': _accountNumberController.text,
        'role': _roleController.text,
      };

      await userRef.update(updatedData);
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error updating user: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_userData!.email),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              decoration: const InputDecoration(
                labelText: 'เบอร์โทร',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _roleController,
              decoration: const InputDecoration(
                labelText: 'สถานะ',
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await updateUser();
              },
              child: const Text('อัพเดทข้อมูล'),
            ),
          ],
        ),
      ),
    );
  }
}
