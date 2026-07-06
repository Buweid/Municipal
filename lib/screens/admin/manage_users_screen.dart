import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
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
  Future<void> _showEditDialog(String docId, Map<String, dynamic> data) async {
    final nameController = TextEditingController(text: data['name'] ?? '');
    final phoneController = TextEditingController(text: data['phone'] ?? '');
    final nationalIdController = TextEditingController(text: data['nationalId'] ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return PopScope(
              canPop: !isSaving,
              child: AlertDialog(
                title: const Text('Edit User'),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            if (!RegExp(r"^[a-zA-Z\u0600-\u06FF\s\-']+$").hasMatch(v.trim())) {
                              return 'Letters only';
                            }
                            final words = v.trim().split(RegExp(r'\s+'));
                            if (words.length < 2) return 'At least 2 names';
                            if (words.length > 5) return 'Max 5 words';
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // Phone
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            prefixIcon: Icon(Icons.phone_outlined),
                            hintText: '7XXXXXXX or 9XXXXXXX',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Phone is required';
                            if (!RegExp(r'^[79]\d{7}$').hasMatch(v.trim())) {
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
                          decoration: const InputDecoration(
                            labelText: 'National ID',
                            prefixIcon: Icon(Icons.badge_outlined),
                            hintText: '8 - 12 digits',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'National ID is required';
                            if (!RegExp(r'^\d{8,12}$').hasMatch(v.trim())) {
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
                    onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                      if (!formKey.currentState!.validate()) return;

                      setStateDialog(() => isSaving = true);

                      try {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(docId)
                            .update({
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'nationalId': nationalIdController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });

                        if (ctx.mounted) Navigator.of(ctx).pop();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('User updated successfully ✅'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          setStateDialog(() => isSaving = false);
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
                        : const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).then((_) {
      nameController.dispose();
      phoneController.dispose();
      nationalIdController.dispose();
    });
  }

  // ── ROLE BADGE ──────────────────────────────────────────────────
  Widget _roleBadge(String role) {
    Color color;
    String label;
    IconData icon;

    switch (role.toLowerCase()) {
      case 'admin':
        color = const Color(0xFF1565C0);
        label = 'Admin';
        icon = Icons.admin_panel_settings;
        break;
      case 'fo':
        color = const Color(0xFF6A1B9A);
        label = 'Field Officer';
        icon = Icons.engineering;
        break;
      default:
        color = const Color(0xFF2E7D32);
        label = 'Citizen';
        icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Users'),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
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
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
          ),

          // ── ROLE FILTER CHIPS ─────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in ['all', 'user', 'fo', 'admin'])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter == 'all'
                              ? 'All'
                              : filter == 'fo'
                              ? 'Field Officers'
                              : filter == 'admin'
                              ? 'Admins'
                              : 'Citizens',
                        ),
                        selected: _selectedFilter == filter,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                        selectedColor: const Color(0xFF2E7D32).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── USER LIST ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                // Apply role filter
                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['role'] ?? '') == _selectedFilter;
                  }).toList();
                }

                // Apply search filter
                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery) ||
                        email.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 48, color: Colors.black26),
                        SizedBox(height: 8),
                        Text(
                          'No users found',
                          style: TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final email = data['email'] ?? '';
                    final phone = data['phone'] ?? '';
                    final role = data['role'] ?? 'user';
                    final nationalId = data['nationalId'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 6),
                        ],
                      ),
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          const Color(0xFF2E7D32).withOpacity(0.12),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(
                              color: Color(0xFF2E7D32),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          email,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: _roleBadge(role),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Divider(),
                                const SizedBox(height: 4),
                                _detailRow(Icons.badge_outlined, 'National ID', nationalId),
                                const SizedBox(height: 6),
                                _detailRow(Icons.phone_outlined, 'Phone', phone),
                                const SizedBox(height: 6),
                                _detailRow(Icons.email_outlined, 'Email', email),
                                const SizedBox(height: 16),

                                if (role != 'admin')
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.edit, size: 16),
                                      label: const Text('Edit User'),
                                      onPressed: () => _showEditDialog(doc.id, data),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
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

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.black45),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.black45),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}