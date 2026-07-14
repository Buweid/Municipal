import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/settings_provider.dart';

class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key});

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  late final GlobalKey<FormState> _formKey;
  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    User? createdUser;

    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 15));

      createdUser = userCredential.user;
      if (createdUser == null) throw Exception('User creation failed');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(createdUser.uid)
          .set({
        'uid': createdUser.uid,
        'name': _nameController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              AppLocalizations.of(context)!.accountCreated),
          backgroundColor: Colors.green,
        ),
      );

      _nameController.clear();
      _nationalIdController.clear();
      _phoneController.clear();
      _emailController.clear();
      _passwordController.clear();
    } on TimeoutException {
      await _deleteCreatedUser(createdUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Request timed out. Please check if Firestore is enabled.'),
          backgroundColor: Colors.red,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already exists';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        default:
          message = e.message ?? 'Authentication error';
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message), backgroundColor: Colors.red),
      );
    } on FirebaseException catch (e) {
      await _deleteCreatedUser(createdUser);
      String message = 'Failed to save user data';
      if (e.code == 'permission-denied') {
        message =
        'Firestore permission denied. Enable Firestore API and check rules.';
      } else if (e.message != null) {
        message = e.message!;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      await _deleteCreatedUser(createdUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCreatedUser(User? user) async {
    try {
      if (user != null) await user.delete();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = context.read<SettingsProvider>().isArabic;

    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            // Full Name
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.fullName,
                prefixIcon: const Icon(Icons.person_outline),
                hintText: isArabic
                    ? 'مثال: أحمد علي الرشدي'
                    : 'e.g. Ahmed Ali Al-Rashdi',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Full name is required';
                }
                if (!RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-']+$")
                    .hasMatch(v.trim())) {
                  return 'Name must contain letters only';
                }
                final wordCount =
                    v.trim().split(RegExp(r'\s+')).length;
                if (wordCount < 2) return 'Enter at least 2 names';
                if (wordCount > 5) {
                  return 'Name cannot exceed 5 words';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // National ID
            TextFormField(
              controller: _nationalIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.nationalId,
                prefixIcon: const Icon(Icons.badge_outlined),
                hintText:
                    isArabic ? '8 - 12 رقماً' : '8 - 12 digits',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'National ID is required';
                }
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
              decoration: InputDecoration(
                labelText: l10n.phoneNumber,
                prefixIcon: const Icon(Icons.phone_outlined),
                hintText: isArabic
                    ? '+968  7XXXXXXX أو 9XXXXXXX'
                    : '+968  7XXXXXXX or 9XXXXXXX',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
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
              decoration: InputDecoration(
                labelText: l10n.email,
                prefixIcon: const Icon(Icons.email_outlined),
                hintText: 'example@gmail.com',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(
                    r'^[\w\.\+\-]+@[\w\-]+\.[a-zA-Z]{2,}$')
                    .hasMatch(v.trim())) {
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
                labelText: l10n.password,
                prefixIcon: const Icon(Icons.lock_outline),
                hintText: isArabic
                    ? '6 - 15 حرفاً'
                    : '6 - 15 characters',
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility
                      : Icons.visibility_off),
                  onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Password is required';
                }
                if (v.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                if (v.length > 15) {
                  return 'Password cannot exceed 15 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : Text(l10n.register,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}