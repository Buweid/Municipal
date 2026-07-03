import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../screens/services/audit_service.dart';

class AddFOScreen extends StatefulWidget {
  const AddFOScreen({super.key});

  @override
  State<AddFOScreen> createState() => _AddFOScreenState();
}

class _AddFOScreenState extends State<AddFOScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createFO() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'secondaryApp',
        options: Firebase.app().options,
      );

      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      final userCredential = await secondaryAuth
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 15));

      final newUid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(newUid)
          .set({
        'uid': newUid,
        'name': _nameController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'fo',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));
      await AuditService.log(
        action: 'FO_CREATED',
        description: 'Admin created field officer "${_nameController.text.trim()}"',
        metadata: {
          'foUid': newUid,
          'foEmail': _emailController.text.trim(),
        },
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Field Officer created successfully ✅"),
          backgroundColor: Colors.green,
        ),
      );

      _nameController.clear();
      _nationalIdController.clear();
      _phoneController.clear();
      _emailController.clear();
      _passwordController.clear();

    } on TimeoutException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Request timed out. Try again."),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Failed to create account";
      if (e.code == 'email-already-in-use') message = "Email already exists";
      else if (e.code == 'weak-password') message = "Password is too weak";
      else if (e.code == 'invalid-email') message = "Invalid email format";
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      await secondaryApp?.delete();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Field Officer"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Icon(Icons.engineering, size: 64, color: Color(0xFF2E7D32)),
              const SizedBox(height: 8),
              const Text(
                "Create Field Officer Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 28),

              // Full Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline),
                  hintText: 'e.g. Ahmed Ali Al-Rashdi',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Full name is required';
                  if (!RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-']+$").hasMatch(v.trim())) {
                    return 'Name must contain letters only';
                  }
                  final wordCount = v.trim().split(RegExp(r'\s+')).length;
                  if (wordCount < 2) return 'Enter at least 2 names';
                  if (wordCount > 5) return 'Name cannot exceed 5 words';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // National ID
              TextFormField(
                controller: _nationalIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'National ID',
                  prefixIcon: Icon(Icons.badge_outlined),
                  hintText: '8 - 12 digits',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'National ID is required';
                  if (!RegExp(r'^\d{8,12}$').hasMatch(v.trim())) {
                    return 'National ID must be 8 to 12 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '+968  7XXXXXXX or 9XXXXXXX',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Phone number is required';
                  if (!RegExp(r'^[79]\d{7}$').hasMatch(v.trim())) {
                    return 'Must start with 7 or 9 and be 8 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  hintText: 'example@gmail.com',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(v.trim())) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: '6 - 15 characters',
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 6) return 'Password must be at least 6 characters';
                  if (v.length > 15) return 'Password cannot exceed 15 characters';
                  return null;
                },
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createFO,
                  child: _isLoading
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Text("Create Field Officer", style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}