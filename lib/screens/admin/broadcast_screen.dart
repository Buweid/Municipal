import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/audit_service.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── BROADCAST FORM ───────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _targetAudience = 'all';
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      // Get target users
      Query query = FirebaseFirestore.instance.collection('users');

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
            content: Text('No users found for selected audience'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Send notification to each user using batch
      final batch = FirebaseFirestore.instance.batch();
      final now = FieldValue.serverTimestamp();
      final adminUid = FirebaseAuth.instance.currentUser!.uid;

      for (final doc in usersSnap.docs) {
        final uid = doc.id;
        // Don't send to admin themselves
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

      // Save to broadcast history
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
            'Broadcast sent to ${usersSnap.docs.length} users ✅',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Switch to history tab
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}  '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _audienceLabel(String audience) {
    switch (audience) {
      case 'citizens':
        return 'Citizens only';
      case 'fo':
        return 'Field Officers only';
      default:
        return 'All Users';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Management'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2E7D32),
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.black45,
          tabs: const [
            Tab(icon: Icon(Icons.send), text: 'Broadcast'),
            Tab(icon: Icon(Icons.history), text: 'History'),
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
                      color: const Color(0xFF2E7D32).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2E7D32).withOpacity(0.3),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: Color(0xFF2E7D32), size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Send a notification to all users or a specific group.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Target audience
                  const Text(
                    'Target Audience',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (final option in [
                        {'value': 'all', 'label': 'All', 'icon': Icons.people},
                        {
                          'value': 'citizens',
                          'label': 'Citizens',
                          'icon': Icons.person
                        },
                        {
                          'value': 'fo',
                          'label': 'Field Officers',
                          'icon': Icons.engineering
                        },
                      ])
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(
                                    () => _targetAudience =
                                option['value'] as String,
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: _targetAudience ==
                                      option['value']
                                      ? const Color(0xFF2E7D32)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _targetAudience ==
                                        option['value']
                                        ? const Color(0xFF2E7D32)
                                        : Colors.black12,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Color(0x0A000000),
                                        blurRadius: 4),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      option['icon'] as IconData,
                                      color: _targetAudience ==
                                          option['value']
                                          ? Colors.white
                                          : Colors.black45,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      option['label'] as String,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _targetAudience ==
                                            option['value']
                                            ? Colors.white
                                            : Colors.black54,
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

                  // Title
                  const Text(
                    'Notification Content',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      prefixIcon: Icon(Icons.title),
                      hintText: 'e.g. Scheduled Maintenance',
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
                    decoration: const InputDecoration(
                      labelText: 'Message',
                      prefixIcon: Icon(Icons.message_outlined),
                      hintText: 'Write your message here...',
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
                        _isSending ? 'Sending...' : 'Send Broadcast',
                        style: const TextStyle(fontSize: 16),
                      ),
                      onPressed: _isSending ? null : _sendBroadcast,
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
                      Icon(Icons.history,
                          size: 56, color: Colors.black26),
                      SizedBox(height: 12),
                      Text(
                        'No broadcasts sent yet',
                        style: TextStyle(
                            color: Colors.black45, fontSize: 15),
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
                  final data =
                  docs[index].data() as Map<String, dynamic>;
                  final sentAt = data['sentAt'] != null
                      ? _formatDate((data['sentAt'] as dynamic).toDate()
                  as DateTime)
                      : '';
                  final audience =
                  _audienceLabel(data['targetAudience'] ?? 'all');
                  final recipientCount =
                      data['recipientCount'] ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(
                            color: Color(0x0A000000), blurRadius: 6),
                      ],
                      border: const Border(
                        left: BorderSide(
                          color: Color(0xFF2E7D32),
                          width: 4,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.notifications_active,
                                  color: Color(0xFF2E7D32), size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  data['title'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                sentAt,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['body'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              // Audience badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  audience,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Recipient count
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '$recipientCount recipients',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w600,
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