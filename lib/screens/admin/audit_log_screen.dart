import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogScreen extends StatefulWidget {
  const AuditLogScreen({super.key});

  @override
  State<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends State<AuditLogScreen> {
  String _selectedFilter = 'all';

  final Map<String, Map<String, dynamic>> _actionConfig = {
    'LOGIN': {
      'icon': Icons.login,
      'color': Colors.teal,
      'label': 'Login',
    },
    'ISSUE_SUBMITTED': {
      'icon': Icons.report_outlined,
      'color': Colors.blue,
      'label': 'Issue Submitted',
    },
    'ISSUE_APPROVED': {
      'icon': Icons.check_circle_outline,
      'color': const Color(0xFF2E7D32),
      'label': 'Issue Approved',
    },
    'ISSUE_REJECTED': {
      'icon': Icons.cancel_outlined,
      'color': Colors.red,
      'label': 'Issue Rejected',
    },
    'TASK_ASSIGNED': {
      'icon': Icons.assignment,
      'color': Colors.purple,
      'label': 'Task Assigned',
    },
    'TASK_ACCEPTED': {
      'icon': Icons.assignment_turned_in,
      'color': Colors.blue,
      'label': 'Task Accepted',
    },
    'TASK_REJECTED': {
      'icon': Icons.assignment_late,
      'color': Colors.red,
      'label': 'Task Rejected',
    },
    'PROGRESS_UPDATED': {
      'icon': Icons.update,
      'color': Colors.orange,
      'label': 'Progress Updated',
    },
    'EVIDENCE_UPLOADED': {
      'icon': Icons.camera_alt_outlined,
      'color': Colors.indigo,
      'label': 'Evidence Uploaded',
    },
    'STATUS_UPDATED': {
      'icon': Icons.swap_horiz,
      'color': Colors.orange,
      'label': 'Status Updated',
    },
    'FO_CREATED': {
      'icon': Icons.person_add_outlined,
      'color': const Color(0xFF6A1B9A),
      'label': 'FO Created',
    },
    'BROADCAST_SENT': {
      'icon': Icons.campaign_outlined,
      'color': const Color(0xFF2E7D32),
      'label': 'Broadcast Sent',
    },
  };

  String _formatTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year}  '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Activity Log'),
      ),
      body: Column(
        children: [
          // ── FILTER ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: const Text('All'),
                      selected: _selectedFilter == 'all',
                      onSelected: (_) =>
                          setState(() => _selectedFilter = 'all'),
                      selectedColor:
                      const Color(0xFF2E7D32).withOpacity(0.15),
                      checkmarkColor: const Color(0xFF2E7D32),
                    ),
                  ),
                  for (final entry in _actionConfig.entries)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.value['label'] as String),
                        selected: _selectedFilter == entry.key,
                        onSelected: (_) => setState(
                                () => _selectedFilter = entry.key),
                        selectedColor:
                        const Color(0xFF2E7D32).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── LOG LIST ─────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('audit_logs')
                  .orderBy('createdAt', descending: true)
                  .limit(200)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                // Apply filter
                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['action'] ?? '') == _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history,
                            size: 48, color: Colors.black26),
                        SizedBox(height: 8),
                        Text('No activity logs yet',
                            style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final data =
                    docs[index].data() as Map<String, dynamic>;
                    final action = data['action'] ?? '';
                    final config = _actionConfig[action] ?? {
                      'icon': Icons.info_outline,
                      'color': Colors.grey,
                      'label': action,
                    };
                    final color = config['color'] as Color;
                    final icon = config['icon'] as IconData;
                    final createdAt = data['createdAt'] != null
                        ? (data['createdAt'] as dynamic).toDate()
                    as DateTime
                        : DateTime.now();

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A000000), blurRadius: 6),
                        ],
                        border: Border(
                          left: BorderSide(color: color, width: 3),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                          color.withOpacity(0.1),
                                          borderRadius:
                                          BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          config['label'] as String,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatTime(createdAt),
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['description'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    data['email'] ?? '',
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