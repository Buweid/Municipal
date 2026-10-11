import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';
import '../../providers/settings_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
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

  // ── GROUPING ─────────────────────────────────────────────────────
  Map<String, List<QueryDocumentSnapshot>> _groupByDate(
      List<QueryDocumentSnapshot> docs) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final createdAt = data['createdAt'];
      if (createdAt == null) continue;

      final date = (createdAt as dynamic).toDate() as DateTime;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final docDate = DateTime(date.year, date.month, date.day);

      String groupKey;
      if (docDate == today) {
        groupKey = 'TODAY';
      } else if (docDate == yesterday) {
        groupKey = 'YESTERDAY';
      } else if (now.difference(date).inDays < 7) {
        groupKey = 'THIS_WEEK';
      } else {
        groupKey = 'OLDER';
      }

      grouped.putIfAbsent(groupKey, () => []).add(doc);
    }

    // Return in correct order
    final ordered = <String, List<QueryDocumentSnapshot>>{};
    for (final key in ['TODAY', 'YESTERDAY', 'THIS_WEEK', 'OLDER']) {
      if (grouped.containsKey(key)) {
        ordered[key] = grouped[key]!;
      }
    }
    return ordered;
  }

  String _groupLabel(String key, bool isArabic) {
    switch (key) {
      case 'TODAY':
        return isArabic ? 'اليوم' : 'Today';
      case 'YESTERDAY':
        return isArabic ? 'أمس' : 'Yesterday';
      case 'THIS_WEEK':
        return isArabic ? 'هذا الأسبوع' : 'This Week';
      case 'OLDER':
        return isArabic ? 'أقدم' : 'Older';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final l10n = AppLocalizations.of(context)!;
    final isArabic = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.notifications),
        actions: [
          // Unread count badge + mark all read
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('uid', isEqualTo: uid)
                .where('isRead', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;
              return TextButton.icon(
                onPressed: () => _markAllRead(uid),
                icon: unreadCount > 0
                    ? Badge(
                  label: Text('$unreadCount'),
                  child: const Icon(
                    Icons.done_all,
                    size: 18,
                  ),
                )
                    : const Icon(Icons.done_all, size: 18),
                label: Text(
                  l10n.markAllRead,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                  ),
                ),
              );
            },
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
            return const Center(child: CircularProgressIndicator(
              color: AppTheme.primary,
            ));
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var docs = snapshot.data?.docs ?? [];

          // Apply notification preferences filter
          final settings = context.read<SettingsProvider>();
          docs = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final type = data['type'] ?? '';
            if (type == 'broadcast' && !settings.notifBroadcast) return false;
            if (type == 'task_assigned' && !settings.notifTasks) return false;
            if (['issue_approved', 'issue_rejected',
                  'issue_in_progress', 'issue_resolved',
                  'task_accepted'].contains(type) &&
                !settings.notifIssueUpdates) return false;
            return true;
          }).toList();

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.borderColor(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_none_outlined,
                      size: 40,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noNotifications,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic
                        ? 'ستظهر إشعاراتك هنا'
                        : 'Your notifications will appear here',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            );
          }

          // Group by date
          final grouped = _groupByDate(docs);

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: grouped.entries
                .map((e) => 1 + e.value.length)
                .fold<int>(0, (a, b) => a + b),
            itemBuilder: (context, index) {
              // Build flat list from grouped map
              final items = <dynamic>[];
              for (final entry in grouped.entries) {
                items.add({'type': 'header', 'key': entry.key});
                for (final doc in entry.value) {
                  items.add({'type': 'item', 'doc': doc});
                }
              }

              if (index >= items.length) return const SizedBox();
              final item = items[index];

              // ── GROUP HEADER ──────────────────────
              if (item['type'] == 'header') {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        _groupLabel(item['key'] as String, isArabic),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondaryColor(context),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Divider(
                          color: AppTheme.borderColor(context),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // ── NOTIFICATION ITEM ─────────────────
              final doc = item['doc'] as QueryDocumentSnapshot;
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['isRead'] ?? false;
              final type = data['type'] ?? '';
              final color = _typeColors[type] ?? Colors.blueGrey;
              final icon = _typeIcons[type] ?? Icons.notifications_outlined;
              final createdAt = data['createdAt'] != null
                  ? (data['createdAt'] as dynamic).toDate() as DateTime
                  : DateTime.now();

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: GestureDetector(
                  onTap: () => _markRead(doc.id),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isRead
                          ? AppTheme.cardColor(context)
                          : color.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isRead
                            ? AppTheme.borderColor(context)
                            : color.withOpacity(0.3),
                        width: isRead ? 1 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.shadowColor(context),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon
                          Container(
                            width: 42,
                            height: 42,
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
                                          fontSize: 13,
                                          color: AppTheme.textPrimaryColor(
                                              context),
                                        ),
                                      ),
                                    ),
                                    // Unread dot
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondaryColor(
                                        context),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatTime(createdAt),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryColor(
                                        context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
