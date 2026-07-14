import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';
import '../services/audit_service.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  late final GlobalKey<FormState> _formKey;
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _targetAudience = 'all';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _formKey = GlobalKey<FormState>();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendBroadcast() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      Query query =
      FirebaseFirestore.instance.collection('users');

      if (_targetAudience == 'citizens') {
        query = query.where('role', isEqualTo: 'user');
      } else if (_targetAudience == 'fo') {
        query = query.where('role', isEqualTo: 'fo');
      }

      final usersSnap = await query.get();

      if (usersSnap.docs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('No users found for selected audience'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();
      final adminUid =
          FirebaseAuth.instance.currentUser?.uid ?? '';

      for (final doc in usersSnap.docs) {
        final uid = doc.id;
        if (uid == adminUid) continue;

        final notifRef = FirebaseFirestore.instance
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'uid': uid,
          'title': _titleController.text.trim(),
          'body': _bodyController.text.trim(),
          'type': 'broadcast',
          'isRead': false,
          'createdAt': now,
        });
      }

      final historyRef = FirebaseFirestore.instance
          .collection('broadcast_history')
          .doc();
      batch.set(historyRef, {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'targetAudience': _targetAudience,
        'recipientCount': usersSnap.docs.length,
        'sentBy': adminUid,
        'sentAt': now,
      });

      await batch.commit();

      await AuditService.log(
        action: 'BROADCAST_SENT',
        description:
        'Admin sent broadcast "${_titleController.text.trim()}" to $_targetAudience',
        metadata: {
          'title': _titleController.text.trim(),
          'audience': _targetAudience,
          'recipientCount': usersSnap.docs.length,
        },
      );

      if (!mounted) return;

      _titleController.clear();
      _bodyController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.sendBroadcast} — ${usersSnap.docs.length} ${l10n.recipients} ✅',
          ),
          backgroundColor: Colors.green,
        ),
      );

      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}  '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _audienceLabel(
      String audience, AppLocalizations l10n) {
    switch (audience) {
      case 'citizens':
        return l10n.citizens;
      case 'fo':
        return l10n.fieldOfficers;
      default:
        return l10n.all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.broadcastTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          labelColor: AppTheme.primary,
          unselectedLabelColor:
          AppTheme.textSecondaryColor(context),
          tabs: [
            Tab(
                icon: const Icon(Icons.send),
                text: l10n.broadcast),
            Tab(
                icon: const Icon(Icons.history),
                text: l10n.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: BROADCAST FORM ─────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color:
                      AppTheme.primary.withOpacity(0.08),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                        color:
                        AppTheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Send a notification to all users or a specific group.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Target audience
                  Text(
                    l10n.targetAudience,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color:
                      AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final option in [
                        {
                          'value': 'all',
                          'label': l10n.all,
                          'icon': Icons.people
                        },
                        {
                          'value': 'citizens',
                          'label': l10n.citizens,
                          'icon': Icons.person
                        },
                        {
                          'value': 'fo',
                          'label': l10n.fieldOfficers,
                          'icon': Icons.engineering
                        },
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                right: 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                    () => _targetAudience =
                                option['value'] as String,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(
                                    milliseconds: 200),
                                padding:
                                const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: _targetAudience ==
                                      option['value']
                                      ? AppTheme.primary
                                      : AppTheme.cardColor(
                                      context),
                                  borderRadius:
                                  BorderRadius.circular(
                                      12),
                                  border: Border.all(
                                    color: _targetAudience ==
                                        option['value']
                                        ? AppTheme.primary
                                        : AppTheme.borderColor(
                                        context),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme
                                          .shadowColor(context),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      option['icon']
                                      as IconData,
                                      color: _targetAudience ==
                                          option['value']
                                          ? Colors.white
                                          : AppTheme
                                          .textSecondaryColor(
                                          context),
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['label']
                                      as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight:
                                        FontWeight.w600,
                                        color: _targetAudience ==
                                            option['value']
                                            ? Colors.white
                                            : AppTheme
                                            .textSecondaryColor(
                                            context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Content
                  Text(
                    l10n.notificationContent,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color:
                      AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: l10n.title,
                      prefixIcon: const Icon(Icons.title),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Title is required';
                      }
                      if (v.trim().length < 3) {
                        return 'Title must be at least 3 characters';
                      }
                      if (v.trim().length > 100) {
                        return 'Title cannot exceed 100 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Body
                  TextFormField(
                    controller: _bodyController,
                    maxLines: 4,
                    maxLength: 300,
                    decoration: InputDecoration(
                      labelText: l10n.message,
                      prefixIcon: const Icon(
                          Icons.message_outlined),
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Message is required';
                      }
                      if (v.trim().length < 10) {
                        return 'Message must be at least 10 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Send button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: _isSending
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
                        _isSending
                            ? l10n.sending
                            : l10n.sendBroadcast,
                        style:
                        const TextStyle(fontSize: 16),
                      ),
                      onPressed:
                      _isSending ? null : _sendBroadcast,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB 2: HISTORY ────────────────────────────
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('broadcast_history')
                .orderBy('sentAt', descending: true)
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
                      Icon(Icons.history,
                          size: 56,
                          color: AppTheme.textSecondaryColor(
                              context)
                              .withOpacity(0.4)),
                      const SizedBox(height: 12),
                      Text(
                        l10n.noBroadcastsYet,
                        style: TextStyle(
                          color:
                          AppTheme.textSecondaryColor(
                              context),
                          fontSize: 15,
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
                  final data = docs[index].data()
                  as Map<String, dynamic>;
                  final sentAt = data['sentAt'] != null
                      ? _formatDate(
                      (data['sentAt'] as dynamic)
                          .toDate() as DateTime)
                      : '';
                  final audience = _audienceLabel(
                      data['targetAudience'] ?? 'all', l10n);
                  final recipientCount =
                      data['recipientCount'] ?? 0;

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
                      border: Border(
                        left: BorderSide(
                          color: AppTheme.primary,
                          width: 4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                  Icons
                                      .notifications_active,
                                  color: AppTheme.primary,
                                  size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight:
                                    FontWeight.w700,
                                    fontSize: 14,
                                    color: AppTheme
                                        .textPrimaryColor(
                                        context),
                                  ),
                                ),
                              ),
                              Text(
                                sentAt,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme
                                      .textSecondaryColor(
                                      context),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['body'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme
                                  .textSecondaryColor(
                                  context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(
                                      6),
                                ),
                                child: Text(
                                  audience,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primary,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue
                                      .withOpacity(0.1),
                                  borderRadius:
                                  BorderRadius.circular(
                                      6),
                                ),
                                child: Text(
                                  '$recipientCount ${l10n.recipients}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}