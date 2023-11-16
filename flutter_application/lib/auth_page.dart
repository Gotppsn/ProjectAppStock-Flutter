import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register.dart';
import 'userpage/user_menu.dart';
import 'adminpage/admin_menu.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signInWithEmailAndPassword() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();

        // Sign in with email and password
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        // Check if the sign-in was successful
        if (_auth.currentUser != null) {
          // Get the role of the current user from Firestore
          final roleRef = FirebaseFirestore.instance
              .collection('users')
              .doc(_auth.currentUser?.uid);
          final roleSnapshot = await roleRef.get();

          // Navigate to the appropriate screen based on the role
          if (roleSnapshot.exists) {
            final role = roleSnapshot.data()?['role'];

            switch (role) {
              case 'admin':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminMenu()),
                );
                break;
              case 'user':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserMenu(
                      pageIndex: 0,
                      cartProducts: [],
                      productQuantities: [],
                    ),
                  ),
                );
                break;
              default:
                _showNotification('Invalid role: $role');
                break;
            }
          } else {
            _showNotification('No role found');
          }
        } else {
          // Handle sign-in failure (e.g., show an error message)
          _showNotification('Sign-in failed');
        }
      }
    } catch (e) {
      // Handle any exceptions or errors
      _showNotification('Error: $e');
    }
  }

  Future<void> _registerWithEmailAndPassword() async {
    try {
      if (_formKey.currentState?.validate() ?? false) {
        final String email = _emailController.text.trim();
        final String password = _passwordController.text.trim();
        await _auth.createUserWithEmailAndPassword(
            email: email, password: password);
        // Navigate to the next screen or perform other actions on successful registration.
      }
    } catch (e) {
      // Handle registration errors (e.g., display an error message).
      _showNotification('Registration failed: $e');
    }
  }

  // Helper method to show a Snackbar notification
  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เข้าสู่ระบบ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'อีเมล์'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'กรุณากรอกอีเมล์';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'กรุณากรอกรหัสผ่าน';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () async {
                  await _signInWithEmailAndPassword();
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue,
                ),
                child: const Text('เข้าสู่ระบบ'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text('สมัครสมาชิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
