import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageIssueTypesScreen extends StatefulWidget {
  const ManageIssueTypesScreen({super.key});

  @override
  State<ManageIssueTypesScreen> createState() => _ManageIssueTypesScreenState();
}

class _ManageIssueTypesScreenState extends State<ManageIssueTypesScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;

  // Available icons for issue types
  final List<Map<String, dynamic>> _iconOptions = [
    {'label': 'Road',       'icon': Icons.add_road},
    {'label': 'Water',      'icon': Icons.water_damage},
    {'label': 'Electricity','icon': Icons.electrical_services},
    {'label': 'Garbage',    'icon': Icons.delete_outline},
    {'label': 'Tree',       'icon': Icons.park},
    {'label': 'Building',   'icon': Icons.apartment},
    {'label': 'Lighting',   'icon': Icons.lightbulb_outline},
    {'label': 'Sewage',     'icon': Icons.plumbing},
    {'label': 'Noise',      'icon': Icons.volume_up},
    {'label': 'Other',      'icon': Icons.report_problem_outlined},
  ];

  String _selectedIconLabel = 'Road';
  IconData _selectedIcon = Icons.add_road;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addIssueType() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isAdding = true);

    try {
      // Check for duplicate name
      final existing = await FirebaseFirestore.instance
          .collection('issue_types')
          .where('name', isEqualTo: _nameController.text.trim())
          .get();

      if (existing.docs.isNotEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue type already exists'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await FirebaseFirestore.instance.collection('issue_types').add({
        'name': _nameController.text.trim(),
        'iconLabel': _selectedIconLabel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue type added ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteIssueType(String docId, String name) async {
    // Confirm before delete
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Issue Type'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('issue_types')
          .doc(docId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"$name" deleted'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  IconData _getIcon(String label) {
    return _iconOptions.firstWhere(
          (e) => e['label'] == label,
      orElse: () => {'icon': Icons.report_problem_outlined},
    )['icon'] as IconData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Manage Issue Types'),
      ),
      body: Column(
        children: [
          // ── ADD FORM ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x11000000), blurRadius: 8),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Issue Type',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Issue Type Name',
                      prefixIcon: Icon(Icons.label_outline),
                      hintText: 'e.g. Road Damage',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Name is required';
                      }
                      if (v.trim().length < 3) {
                        return 'Name must be at least 3 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Icon picker
                  const Text(
                    'Select Icon',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconOptions.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final opt = _iconOptions[i];
                        final selected = opt['label'] == _selectedIconLabel;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedIconLabel = opt['label'];
                            _selectedIcon = opt['icon'];
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 60,
                            decoration: BoxDecoration(
                              color: selected
                                  ? const Color(0xFF2E7D32)
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF2E7D32)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  opt['icon'] as IconData,
                                  color: selected ? Colors.white : Colors.black54,
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt['label'],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: selected
                                        ? Colors.white
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Add button
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      icon: _isAdding
                          ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.add),
                      label: Text(_isAdding ? 'Adding...' : 'Add Issue Type'),
                      onPressed: _isAdding ? null : _addIssueType,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LIST ──────────────────────────────────────────
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Existing Issue Types',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issue_types')
                  .orderBy('createdAt', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 48, color: Colors.black26),
                        SizedBox(height: 8),
                        Text(
                          'No issue types yet',
                          style: TextStyle(color: Colors.black45),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final iconLabel = data['iconLabel'] ?? 'Other';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(color: Color(0x0A000000), blurRadius: 6),
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIcon(iconLabel),
                            color: const Color(0xFF2E7D32),
                            size: 22,
                          ),
                        ),
                        title: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          iconLabel,
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _deleteIssueType(doc.id, name),
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
}