import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/screens/constants/app_theme.dart';
import '../../providers/settings_provider.dart';
import '../shared/settings_screen.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();

  // Password change controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isChangingPassword = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _showPasswordSection = false;

  String _email = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final data = doc.data();
      if (data != null) {
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _nationalIdController.text = data['nationalId'] ?? '';
        _email = data['email'] ?? '';
        _role = data['role'] ?? 'user';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading profile: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'nationalId': _nationalIdController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully ✅'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    if (_newPasswordController.text.length < 6 ||
        _newPasswordController.text.length > 15) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be 6-15 characters'),
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Re-authenticate first
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(_newPasswordController.text.trim());

      if (!mounted) return;

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      setState(() => _showPasswordSection = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully ✅'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String message = 'Failed to change password';
      if (e.code == 'wrong-password') {
        message = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        message = 'New password is too weak';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isChangingPassword = false);
    }
  }

  // ── ROLE BADGE ───────────────────────────────────────────────────
  Widget _roleBadge() {
    Color color;
    String label;
    IconData icon;

    switch (_role) {
      case 'admin':
        color = AppTheme.info;
        label = 'Administrator';
        icon = Icons.admin_panel_settings_outlined;
        break;
      case 'fo':
        color = AppTheme.purple;
        label = 'Field Officer';
        icon = Icons.engineering_outlined;
        break;
      default:
        color = AppTheme.primary;
        label = 'Citizen';
        icon = Icons.person_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isArabic = settings.isArabic;
    final isDark = settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(isArabic ? 'الملف الشخصي' : 'Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── PROFILE HEADER ─────────────────────
              Center(
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _nameController.text.isNotEmpty
                              ? _nameController.text[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      _nameController.text,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      _email,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Role badge
                    _roleBadge(),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── PERSONAL INFO ──────────────────────
              _SectionTitle(
                title: isArabic
                    ? 'المعلومات الشخصية'
                    : 'Personal Information',
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: isArabic ? 'الاسم الكامل' : 'Full Name',
                  prefixIcon:
                  const Icon(Icons.person_outline),
                  hintText: 'e.g. Ahmed Ali Al-Rashdi',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return isArabic
                        ? 'الاسم مطلوب'
                        : 'Name is required';
                  }
                  if (!RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-']+$")
                      .hasMatch(v.trim())) {
                    return isArabic
                        ? 'أحرف فقط'
                        : 'Letters only';
                  }
                  final words =
                  v.trim().split(RegExp(r'\s+'));
                  if (words.length < 2) {
                    return isArabic
                        ? 'أدخل اسمين على الأقل'
                        : 'At least 2 names';
                  }
                  if (words.length > 5) {
                    return isArabic
                        ? 'الحد الأقصى 5 كلمات'
                        : 'Max 5 words';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: isArabic
                      ? 'رقم الهاتف'
                      : 'Phone Number',
                  prefixIcon:
                  const Icon(Icons.phone_outlined),
                  hintText: '+968  7XXXXXXX or 9XXXXXXX',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return isArabic
                        ? 'رقم الهاتف مطلوب'
                        : 'Phone is required';
                  }
                  if (!RegExp(r'^[79]\d{7}$')
                      .hasMatch(v.trim())) {
                    return isArabic
                        ? 'يجب أن يبدأ بـ 7 أو 9 و8 أرقام'
                        : 'Must start with 7 or 9, 8 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceMd),

              // National ID
              TextFormField(
                controller: _nationalIdController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isArabic
                      ? 'الرقم الوطني'
                      : 'National ID',
                  prefixIcon:
                  const Icon(Icons.badge_outlined),
                  hintText: '8 - 12 digits',
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return isArabic
                        ? 'الرقم الوطني مطلوب'
                        : 'National ID is required';
                  }
                  if (!RegExp(r'^\d{8,12}$')
                      .hasMatch(v.trim())) {
                    return isArabic
                        ? 'يجب أن يكون 8 إلى 12 رقماً'
                        : 'Must be 8 to 12 digits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  icon: _isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    _isSaving
                        ? (isArabic ? 'جاري الحفظ...' : 'Saving...')
                        : (isArabic
                        ? 'حفظ التغييرات'
                        : 'Save Changes'),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── CHANGE PASSWORD ────────────────────
              const Divider(),
              const SizedBox(height: AppTheme.spaceMd),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionTitle(
                    title: isArabic
                        ? 'تغيير كلمة المرور'
                        : 'Change Password',
                  ),
                  TextButton(
                    onPressed: () => setState(
                          () => _showPasswordSection =
                      !_showPasswordSection,
                    ),
                    child: Text(
                      _showPasswordSection
                          ? (isArabic ? 'إلغاء' : 'Cancel')
                          : (isArabic ? 'تغيير' : 'Change'),
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              if (_showPasswordSection) ...[
                const SizedBox(height: AppTheme.spaceMd),

                // Current password
                TextFormField(
                  controller: _currentPasswordController,
                  obscureText: _obscureCurrent,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'كلمة المرور الحالية'
                        : 'Current Password',
                    prefixIcon:
                    const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureCurrent
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                            () => _obscureCurrent = !_obscureCurrent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // New password
                TextFormField(
                  controller: _newPasswordController,
                  obscureText: _obscureNew,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'كلمة المرور الجديدة'
                        : 'New Password',
                    prefixIcon:
                    const Icon(Icons.lock_outline),
                    hintText: '6 - 15 characters',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNew
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                            () => _obscureNew = !_obscureNew,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceMd),

                // Confirm password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'تأكيد كلمة المرور'
                        : 'Confirm New Password',
                    prefixIcon:
                    const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spaceLg),

                // Change password button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    icon: _isChangingPassword
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Icon(Icons.lock_reset),
                    label: Text(
                      _isChangingPassword
                          ? (isArabic
                          ? 'جاري التغيير...'
                          : 'Changing...')
                          : (isArabic
                          ? 'تغيير كلمة المرور'
                          : 'Change Password'),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.info,
                    ),
                    onPressed: _isChangingPassword
                        ? null
                        : _changePassword,
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spaceXl),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SHARED WIDGET ─────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppTheme.textPrimary,
      ),
    );
  }
}