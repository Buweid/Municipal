import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';

class ManageIssueTypesScreen extends StatefulWidget {
  const ManageIssueTypesScreen({super.key});

  @override
  State<ManageIssueTypesScreen> createState() =>
      _ManageIssueTypesScreenState();
}

class _ManageIssueTypesScreenState
    extends State<ManageIssueTypesScreen> {
  final _nameController = TextEditingController();
  late final GlobalKey<FormState> _formKey;
  bool _isAdding = false;

  final List<Map<String, dynamic>> _iconOptions = [
    {'label': 'Road', 'icon': Icons.add_road},
    {'label': 'Water', 'icon': Icons.water_damage},
    {'label': 'Electricity', 'icon': Icons.electrical_services},
    {'label': 'Garbage', 'icon': Icons.delete_outline},
    {'label': 'Tree', 'icon': Icons.park},
    {'label': 'Building', 'icon': Icons.apartment},
    {'label': 'Lighting', 'icon': Icons.lightbulb_outline},
    {'label': 'Sewage', 'icon': Icons.plumbing},
    {'label': 'Noise', 'icon': Icons.volume_up},
    {'label': 'Other', 'icon': Icons.report_problem_outlined},
  ];

  String _selectedIconLabel = 'Road';

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _addIssueType() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isAdding = true);

    try {
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

      await FirebaseFirestore.instance
          .collection('issue_types')
          .add({
        'name': _nameController.text.trim(),
        'iconLabel': _selectedIconLabel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _nameController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.addIssueType} ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteIssueType(
      String docId, String name) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          l10n.deleteIssueType,
          style: TextStyle(
              color: AppTheme.textPrimaryColor(context)),
        ),
        content: Text(
          '${l10n.deleteConfirm} "$name"?',
          style: TextStyle(
              color: AppTheme.textSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.reject,
              style: const TextStyle(color: Colors.red),
            ),
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
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.manageIssueTypesTitle),
      ),
      body: Column(
        children: [
          // ── ADD FORM ──────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardColor(context),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowColor(context),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.addNewIssueType,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name field
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: l10n.issueTypeName,
                      prefixIcon:
                      const Icon(Icons.label_outline),
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
                  Text(
                    l10n.selectIcon,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                      AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _iconOptions.length,
                      separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final opt = _iconOptions[i];
                        final selected =
                            opt['label'] == _selectedIconLabel;
                        return GestureDetector(
                          onTap: () => setState(() =>
                          _selectedIconLabel =
                          opt['label']),
                          child: AnimatedContainer(
                            duration: const Duration(
                                milliseconds: 200),
                            width: 60,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppTheme.primary
                                  : AppTheme.isDark(context)
                                  ? const Color(0xFF30363D)
                                  : const Color(0xFFF5F5F5),
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.primary
                                    : Colors.transparent,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              children: [
                                Icon(
                                  opt['icon'] as IconData,
                                  color: selected
                                      ? Colors.white
                                      : AppTheme
                                      .textSecondaryColor(
                                      context),
                                  size: 22,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  opt['label'],
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: selected
                                        ? Colors.white
                                        : AppTheme
                                        .textSecondaryColor(
                                        context),
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
                      label: Text(_isAdding
                          ? l10n.adding
                          : l10n.addIssueType),
                      onPressed:
                      _isAdding ? null : _addIssueType,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── LIST ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  l10n.existingIssueTypes,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textPrimaryColor(context),
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

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 48,
                            color: AppTheme.textSecondaryColor(
                                context)
                                .withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noIssueTypesYet,
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
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data =
                    doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Unknown';
                    final iconLabel =
                        data['iconLabel'] ?? 'Other';

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
                      child: ListTile(
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.primary
                                .withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _getIcon(iconLabel),
                            color: AppTheme.primary,
                            size: 22,
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
                          iconLabel,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor(
                                context),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () =>
                              _deleteIssueType(doc.id, name),
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