import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../constants/app_theme.dart';
import 'location_picker_screen.dart';
import '../services/audit_service.dart';
import '../services/ai_service.dart';
import '../services/cloudinary_service.dart';

class SubmitIssueScreen extends StatefulWidget {
  const SubmitIssueScreen({super.key});

  @override
  State<SubmitIssueScreen> createState() =>
      _SubmitIssueScreenState();
}

class _SubmitIssueScreenState extends State<SubmitIssueScreen> {
  late final GlobalKey<FormState> _formKey;
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedIssueType;
  List<Map<String, dynamic>> _issueTypes = [];
  File? _selectedImage;
  LatLng? _selectedLocation;
  bool _isSubmitting = false;
  List<String> _titleSuggestions = [];
  bool _isLoadingSuggestions = false;
  bool _isImprovingDescription = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
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
    if (!mounted) return;
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
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  void _showImageSourceDialog() {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardColor(context),
      shape: const RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(top: Radius.circular(20)),
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
                color: AppTheme.borderColor(context),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.photoEvidence,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.camera_alt,
                    color: Color(0xFF2E7D32)),
              ),
              title: Text(
                'Camera',
                style: TextStyle(
                    color:
                    AppTheme.textPrimaryColor(context)),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFE8F5E9),
                child: Icon(Icons.photo_library,
                    color: Color(0xFF2E7D32)),
              ),
              title: Text(
                'Gallery',
                style: TextStyle(
                    color:
                    AppTheme.textPrimaryColor(context)),
              ),
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
    if (!mounted) return;
    if (result != null) {
      setState(() => _selectedLocation = result);
    }
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null) return null;
    return await CloudinaryService.uploadImage(_selectedImage!);
  }

  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedIssueType = null;
      _selectedImage = null;
      _selectedLocation = null;
      _titleSuggestions = [];
    });
  }

  Future<void> _submitIssue() async {
    final l10n = AppLocalizations.of(context)!;
    final isArabic =
        context.read<SettingsProvider>().isArabic;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.selectIssueType),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tapToSelectLocation),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be logged in to submit an issue'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final user = currentUser;
      final issueId = const Uuid().v4();

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userName =
          userDoc.data()?['name'] ?? 'Unknown';

      // Upload image to Cloudinary
      String? imageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImage();
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
        description:
        'Citizen submitted issue "${_titleController.text.trim()}"',
        metadata: {
          'issueId': issueId,
          'issueType': _selectedIssueType,
        },
      );

      if (!mounted) return;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.cardColor(context),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.issueSubmitted,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color:
                  AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isArabic
                    ? 'سيتم مراجعة بلاغك من قبل الإدارة'
                    : 'Your report will be reviewed by the municipality',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color:
                  AppTheme.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(),
                  child: Text(l10n.confirm),
                ),
              ),
            ],
          ),
        ),
      );

      // Clear form after dialog closes
      if (!mounted) return;
      _clearForm();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = context.read<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.submitIssue),
        automaticallyImplyLeading: false, // ← no back button since it's in IndexedStack
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── TITLE ───────────────────────────────────
            Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.issueTitle,
                  prefixIcon: const Icon(Icons.title),
                  hintText: isArabic
                      ? 'مثال: حفرة كبيرة في الطريق الرئيسي'
                      : 'e.g. Large pothole on main road',
                ),
                onChanged: (value) async {
                  if (value.trim().length >= 3 &&
                      _selectedIssueType != null) {
                    setState(() =>
                    _isLoadingSuggestions = true);
                    final suggestions = await AIService
                        .getIssueSuggestions(
                      issueType: _selectedIssueType!,
                      partialTitle: value,
                    );
                    if (mounted) {
                      setState(() {
                        _titleSuggestions = suggestions;
                        _isLoadingSuggestions = false;
                      });
                    }
                  } else {
                    setState(
                            () => _titleSuggestions = []);
                  }
                },
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Title is required';
                  }
                  if (v.trim().length < 5) {
                    return 'Title must be at least 5 characters';
                  }
                  if (v.trim().length > 100) {
                    return 'Title cannot exceed 100 characters';
                  }
                  return null;
                },
              ),

              if (_isLoadingSuggestions)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: LinearProgressIndicator(
                    backgroundColor:
                    Color(0xFFE8F5E9),
                    valueColor:
                    AlwaysStoppedAnimation(
                        AppTheme.primary),
                  ),
                ),

              if (_titleSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius: BorderRadius.circular(
                        AppTheme.radiusMd),
                    border: Border.all(
                        color: AppTheme.borderColor(
                            context)),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: Column(
                    children: _titleSuggestions
                        .asMap()
                        .entries
                        .map((e) {
                      final isLast = e.key ==
                          _titleSuggestions.length - 1;
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            leading: const Icon(
                              Icons.auto_awesome,
                              color: AppTheme.primary,
                              size: 16,
                            ),
                            title: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme
                                    .textPrimaryColor(
                                    context),
                              ),
                            ),
                            onTap: () {
                              _titleController.text =
                                  e.value;
                              setState(() =>
                              _titleSuggestions =
                              []);
                            },
                          ),
                          if (!isLast)
                            Divider(
                                height: 1,
                                indent: 16,
                                color: AppTheme
                                    .borderColor(
                                    context)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // ── ISSUE TYPE ───────────────────────────────
          DropdownButtonFormField<String>(
            value: _selectedIssueType,
            decoration: InputDecoration(
              labelText: l10n.issueType,
              prefixIcon: const Icon(
                  Icons.category_outlined),
            ),
            hint: Text(l10n.selectIssueType),
            items: _issueTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type['name'],
                child: Text(type['name']),
              );
            }).toList(),
            onChanged: (v) =>
                setState(() => _selectedIssueType = v),
          ),
          const SizedBox(height: 16),

          // ── DESCRIPTION ──────────────────────────────
          Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
            TextFormField(
            controller: _descriptionController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.description,
              prefixIcon: const Icon(
                  Icons.description_outlined),
              hintText: l10n.describeIssue,
              alignLabelWithHint: true,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Description is required';
              }
              if (v.trim().length < 10) {
                return 'Description must be at least 10 characters';
              }
              if (v.trim().length > 500) {
                return 'Description cannot exceed 500 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 8),

          // AI improve button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
                onTap: _isImprovingDescription ||
                    _descriptionController.text
                        .trim()
                        .length < 10
                ? null
                : () async {
          setState(() =>
          _isImprovingDescription =
          true);
          final improved =
          await AIService
              .improveDescription(
          issueType:
          _selectedIssueType ??
          'General',
          roughDescription:
          _descriptionController
              .text
              .trim(),
          );
          if (mounted) {
          _descriptionController
              .text = improved;
          setState(() =>
          _isImprovingDescription =
          false);
          }
          },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary
                    .withOpacity(0.08),
                borderRadius:
                BorderRadius.circular(
                    AppTheme.radiusSm),
                border: Border.all(
                  color: AppTheme.primary
                      .withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isImprovingDescription
                      ? const SizedBox(
                    width: 12,
                    height: 12,
                    child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                      : const Icon(
                    Icons.auto_awesome,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.improveWithAI,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        ],
      ),
      const SizedBox(height: 20),

      // ── IMAGE UPLOAD ─────────────────────────────
      Text(
        l10n.photoEvidence,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textPrimaryColor(context),
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _showImageSourceDialog,
        child: Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color:
              AppTheme.primary.withOpacity(0.4),
              width: 1.5,
            ),
          ),
          child: _selectedImage != null
              ? Stack(
            children: [
              ClipRRect(
                borderRadius:
                BorderRadius.circular(13),
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
                  onTap: () => setState(
                          () =>
                      _selectedImage =
                      null),
                  child: Container(
                    decoration:
                    const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    padding:
                    const EdgeInsets.all(
                        4),
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
              : Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              const Icon(
                  Icons.add_a_photo_outlined,
                  size: 40,
                  color: AppTheme.primary),
              const SizedBox(height: 8),
              Text(
                l10n.tapToAddPhoto,
                style: TextStyle(
                  color: AppTheme
                      .textSecondaryColor(
                      context),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 20),

      // ── LOCATION ─────────────────────────────────
      Text(
        l10n.issueLocation,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: AppTheme.textPrimaryColor(context),
        ),
      ),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: _pickLocation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _selectedLocation != null
                  ? AppTheme.primary
                  : AppTheme.primary
                  .withOpacity(0.4),
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
                    : AppTheme.textSecondaryColor(
                    context),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _selectedLocation != null
                    ? Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.locationSelected,
                      style: const TextStyle(
                        fontWeight:
                        FontWeight.w600,
                        color: AppTheme.primary,
                      ),
                    ),
                    Text(
                      '${_selectedLocation!.latitude.toStringAsFixed(5)}, '
                          '${_selectedLocation!.longitude.toStringAsFixed(5)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme
                            .textSecondaryColor(
                            context),
                      ),
                    ),
                  ],
                )
                    : Text(
                  l10n.tapToSelectLocation,
                  style: TextStyle(
                    color: AppTheme
                        .textSecondaryColor(
                        context),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textSecondaryColor(
                    context),
              ),
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
            _isSubmitting
                ? l10n.submitting
                : l10n.submitIssue,
            style: const TextStyle(fontSize: 16),
          ),
          onPressed:
          _isSubmitting ? null : _submitIssue,
        ),
      ),
      const SizedBox(height: 20),
      ],
    ),
    ),
    ),
    );
  }
}