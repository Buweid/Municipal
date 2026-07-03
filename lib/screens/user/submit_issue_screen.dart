import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'location_picker_screen.dart';
import '../services/audit_service.dart'; // ← add import

class SubmitIssueScreen extends StatefulWidget {
  const SubmitIssueScreen({super.key});

  @override
  State<SubmitIssueScreen> createState() => _SubmitIssueScreenState();
}

class _SubmitIssueScreenState extends State<SubmitIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedIssueType;
  List<Map<String, dynamic>> _issueTypes = [];
  File? _selectedImage;
  LatLng? _selectedLocation;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadIssueTypes();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadIssueTypes() async {
    final snap = await FirebaseFirestore.instance
        .collection('issue_types')
        .orderBy('createdAt')
        .get();

    setState(() {
      _issueTypes = snap.docs
          .map((d) => {'id': d.id, 'name': d['name']})
          .toList();
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Select Image Source',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              ),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              ),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<String?> _uploadImage(String issueId) async {
    if (_selectedImage == null) return null;

    final ref = FirebaseStorage.instance
        .ref()
        .child('issue_images/$issueId.jpg');

    await ref.putFile(_selectedImage!);
    return await ref.getDownloadURL();
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the issue location on the map'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final issueId = const Uuid().v4();

      // Get user name from Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // Upload image if selected
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(issueId);
      }

      // Save issue to Firestore
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .set({
        'issueId': issueId,
        'uid': user.uid,
        'userName': userName,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'issueType': _selectedIssueType,
        'imageUrl': imageUrl,
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AuditService.log(
        action: 'ISSUE_SUBMITTED',
        description: 'Citizen submitted issue "${_titleController.text.trim()}"',
        metadata: {
          'issueId': issueId,
          'issueType': _selectedIssueType,
        },
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue submitted successfully ✅'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── TITLE ───────────────────────────────────
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Issue Title',
                  prefixIcon: Icon(Icons.title),
                  hintText: 'e.g. Large pothole on main road',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Title is required';
                  if (v.trim().length < 5) return 'Title must be at least 5 characters';
                  if (v.trim().length > 100) return 'Title cannot exceed 100 characters';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── ISSUE TYPE ───────────────────────────────
              DropdownButtonFormField<String>(
                value: _selectedIssueType,
                decoration: const InputDecoration(
                  labelText: 'Issue Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                hint: const Text('Select issue type'),
                items: _issueTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type['name'],
                    child: Text(type['name']),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _selectedIssueType = v),
              ),
              const SizedBox(height: 16),

              // ── DESCRIPTION ──────────────────────────────
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description_outlined),
                  hintText: 'Describe the issue in detail...',
                  alignLabelWithHint: true,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Description is required';
                  if (v.trim().length < 10) return 'Description must be at least 10 characters';
                  if (v.trim().length > 500) return 'Description cannot exceed 500 characters';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── IMAGE UPLOAD ─────────────────────────────
              const Text(
                'Photo Evidence',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: _selectedImage != null
                      ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.file(
                          _selectedImage!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImage = null),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 40, color: Color(0xFF2E7D32)),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add photo (optional)',
                        style: TextStyle(color: Colors.black45),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── LOCATION ─────────────────────────────────
              const Text(
                'Issue Location',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickLocation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedLocation != null
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFF2E7D32).withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedLocation != null
                            ? Icons.location_on
                            : Icons.location_off,
                        color: _selectedLocation != null
                            ? Colors.red
                            : Colors.black45,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _selectedLocation != null
                            ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Selected ✅',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            Text(
                              '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                                  '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        )
                            : const Text(
                          'Tap to select location on map',
                          style: TextStyle(color: Colors.black45),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Colors.black26),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── SUBMIT BUTTON ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting ? 'Submitting...' : 'Submit Issue',
                    style: const TextStyle(fontSize: 16),
                  ),
                  onPressed: _isSubmitting ? null : _submitIssue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}