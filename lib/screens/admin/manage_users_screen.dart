import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() =>
      _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _selectedFilter = 'all';
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── EDIT USER DIALOG ────────────────────────────────────────────
  Future<void> _showEditDialog(
      String docId, Map<String, dynamic> data) async {
    final l10n = AppLocalizations.of(context)!;
    final nameController =
    TextEditingController(text: data['name'] ?? '');
    final phoneController =
    TextEditingController(text: data['phone'] ?? '');
    final nationalIdController =
    TextEditingController(text: data['nationalId'] ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) => PopScope(
            canPop: !isSaving,
            child: AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              title: Text(
                l10n.editUser,
                style: TextStyle(
                    color: AppTheme.textPrimaryColor(context)),
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Name
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: l10n.fullName,
                          prefixIcon: const Icon(
                              Icons.person_outline),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (!RegExp(
                              r"^[a-zA-Z\u0600-\u06FF\s\-']+$")
                              .hasMatch(v.trim())) {
                            return 'Letters only';
                          }
                          final words =
                          v.trim().split(RegExp(r'\s+'));
                          if (words.length < 2) {
                            return 'At least 2 names';
                          }
                          if (words.length > 5) {
                            return 'Max 5 words';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Phone
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          prefixIcon: const Icon(
                              Icons.phone_outlined),
                          hintText: '7XXXXXXX or 9XXXXXXX',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone is required';
                          }
                          if (!RegExp(r'^[79]\d{7}$')
                              .hasMatch(v.trim())) {
                            return 'Must start with 7 or 9, 8 digits';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // National ID
                      TextFormField(
                        controller: nationalIdController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.nationalId,
                          prefixIcon: const Icon(
                              Icons.badge_outlined),
                          hintText: '8 - 12 digits',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'National ID is required';
                          }
                          if (!RegExp(r'^\d{8,12}$')
                              .hasMatch(v.trim())) {
                            return 'Must be 8 to 12 digits';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) return;
                    setStateDialog(
                            () => isSaving = true);

                    try {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(docId)
                          .update({
                        'name':
                        nameController.text.trim(),
                        'phone':
                        phoneController.text.trim(),
                        'nationalId':
                        nationalIdController.text
                            .trim(),
                        'updatedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content:
                            Text(l10n.userUpdated),
                            backgroundColor:
                            Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setStateDialog(
                                () => isSaving = false);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      nameController.dispose();
      phoneController.dispose();
      nationalIdController.dispose();
    });
  }

  // ── ROLE BADGE ──────────────────────────────────────────────────
  Widget _roleBadge(String role, AppLocalizations l10n) {
    Color color;
    String label;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        color = const Color(0xFF1565C0);
        label = l10n.admin;
        icon = Icons.admin_panel_settings;
        break;
      case 'fo':
        color = const Color(0xFF6A1B9A);
        label = l10n.fieldOfficer;
        icon = Icons.engineering;
        break;
      default:
        color = const Color(0xFF2E7D32);
        label = l10n.citizen;
        icon = Icons.person;
    }

    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.manageUsersTitle),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchByNameEmail,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
              ),
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // ── ROLE FILTER CHIPS ─────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in [
                    'all',
                    'user',
                    'fo',
                    'admin'
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter == 'all'
                              ? l10n.all
                              : filter == 'fo'
                              ? l10n.fieldOfficers
                              : filter == 'admin'
                              ? l10n.admin
                              : l10n.citizens,
                        ),
                        selected: _selectedFilter == filter,
                        onSelected: (_) => setState(
                                () => _selectedFilter = filter),
                        selectedColor:
                        AppTheme.primary.withOpacity(0.15),
                        checkmarkColor: AppTheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── USER LIST ─────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child:
                      Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data =
                    d.data() as Map<String, dynamic>;
                    return (data['role'] ?? '') ==
                        _selectedFilter;
                  }).toList();
                }

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data =
                    d.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final email = (data['email'] ?? '')
                        .toString()
                        .toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48,
                            color: AppTheme.textSecondaryColor(
                                context)
                                .withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noUsersFound,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(
                                context),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final email = data['email'] ?? '';
                    final phone = data['phone'] ?? '';
                    final role = data['role'] ?? 'user';
                    final nationalId =
                        data['nationalId'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius:
                        BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color:
                            AppTheme.shadowColor(context),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
                          backgroundColor:
                          AppTheme.cardColor(context),
                          collapsedBackgroundColor:
                          AppTheme.cardColor(context),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary
                                .withOpacity(0.12),
                            child: Text(
                              name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimaryColor(
                                  context),
                            ),
                          ),
                          subtitle: Text(
                            email,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor(
                                  context),
                            ),
                          ),
                          trailing:
                          _roleBadge(role, l10n),
                          children: [
                            Padding(
                              padding:
                              const EdgeInsets.fromLTRB(
                                  16, 0, 16, 16),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Divider(
                                      color: AppTheme
                                          .borderColor(
                                          context)),
                                  const SizedBox(height: 4),

                                  _detailRow(
                                      Icons.badge_outlined,
                                      l10n.nationalId,
                                      nationalId),
                                  const SizedBox(height: 6),
                                  _detailRow(
                                      Icons.phone_outlined,
                                      l10n.phoneNumber,
                                      phone),
                                  const SizedBox(height: 6),
                                  _detailRow(
                                      Icons.email_outlined,
                                      l10n.email,
                                      email),
                                  const SizedBox(height: 16),

                                  if (role != 'admin')
                                    SizedBox(
                                      width: double.infinity,
                                      child:
                                      ElevatedButton.icon(
                                        icon: const Icon(
                                            Icons.edit,
                                            size: 16),
                                        label: Text(
                                            l10n.editUser),
                                        onPressed: () =>
                                            _showEditDialog(
                                                doc.id, data),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _detailRow(
      IconData icon, String label, String value) {
    return Builder(builder: (context) {
      return Row(
        children: [
          Icon(icon,
              size: 16,
              color: AppTheme.textSecondaryColor(context)),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
          ),
        ],
      );
    });
  }
}