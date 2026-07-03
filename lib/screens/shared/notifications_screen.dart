import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // ── MOVED TO STATIC ──────────────────────────────────────────────
  static const Map<String, IconData> _typeIcons = {
    'issue_approved': Icons.check_circle_outline,
    'issue_rejected': Icons.cancel_outlined,
    'issue_in_progress': Icons.engineering,
    'issue_resolved': Icons.task_alt,
    'task_assigned': Icons.assignment,
    'task_accepted': Icons.assignment_turned_in,
    'broadcast': Icons.campaign_outlined,
  };

  static const Map<String, Color> _typeColors = {
    'issue_approved': Colors.blue,
    'issue_rejected': Colors.red,
    'issue_in_progress': Colors.purple,
    'issue_resolved': Color(0xFF2E7D32),
    'task_assigned': Colors.orange,
    'task_accepted': Colors.blue,
    'broadcast': Color(0xFF2E7D32),
  };

  Future<void> _markAllRead(String uid) async {
    final unread = await FirebaseFirestore.instance
        .collection('notifications')
        .where('uid', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _markRead(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifications')
        .doc(docId)
        .update({'isRead': true});
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _markAllRead(uid),
            child: const Text(
              'Mark all read',
              style: TextStyle(color: Color(0xFF2E7D32)),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('uid', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // ← changed from final to var so we can reassign
          var docs = snapshot.data?.docs ?? [];

          // Apply notification preferences filter
          final settings = context.read<SettingsProvider>();
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final type = data['type'] ?? '';

            if (type == 'broadcast' && !settings.notifBroadcast) {
              return false;
            }
            if (type == 'task_assigned' && !settings.notifTasks) {
              return false;
            }
            if (['issue_approved', 'issue_rejected', 'issue_in_progress',
              'issue_resolved', 'task_accepted'].contains(type) &&
                !settings.notifIssueUpdates) {
              return false;
            }
            return true;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none,
                      size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    'No notifications yet',
                    style:
                    TextStyle(color: Colors.black45, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? '';
              final color = _typeColors[type] ?? Colors.blueGrey;
              final icon =
                  _typeIcons[type] ?? Icons.notifications_outlined;
              final createdAt = data['createdAt'] != null
                  ? (data['createdAt'] as dynamic).toDate() as DateTime
                  : DateTime.now();

              return GestureDetector(
                onTap: () => _markRead(doc.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color:
                    isRead ? Colors.white : color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isRead
                          ? const Color(0x0A000000)
                          : color.withOpacity(0.3),
                      width: isRead ? 1 : 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x0A000000), blurRadius: 6),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),

                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: isRead
                                            ? FontWeight.w500
                                            : FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  if (!isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                data['body'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black54,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatTime(createdAt),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}