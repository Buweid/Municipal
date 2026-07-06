import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

class IssueManagementScreen extends StatefulWidget {
  const IssueManagementScreen({super.key});

  @override
  State<IssueManagementScreen> createState() => _IssueManagementScreenState();
}

class _IssueManagementScreenState extends State<IssueManagementScreen> {
  String _selectedFilter = 'all';

  // ── STATUS CONFIG ────────────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _statusConfig = {
    'pending': {
      'label': 'Pending',
      'color': Colors.orange,
      'icon': Icons.hourglass_empty,
    },
    'approved': {
      'label': 'Approved',
      'color': Colors.blue,
      'icon': Icons.check_circle_outline,
    },
    'rejected': {
      'label': 'Rejected',
      'color': Colors.red,
      'icon': Icons.cancel_outlined,
    },
    'in_progress': {
      'label': 'In Progress',
      'color': Colors.purple,
      'icon': Icons.engineering,
    },
    'resolved': {
      'label': 'Resolved',
      'color': Color(0xFF2E7D32),
      'icon': Icons.task_alt,
    },
  };

  // ── STATUS BADGE ─────────────────────────────────────────────────
  Widget _statusBadge(String status) {
    final config = _statusConfig[status] ?? _statusConfig['pending']!;
    final color = config['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config['icon'] as IconData, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            config['label'] as String,
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

  // ── APPROVE ──────────────────────────────────────────────────────
  Future<void> _approveIssue(String issueId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Issue'),
        content: const Text('Are you sure you want to approve this issue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'status': 'approved',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .get();
      final data = issueDoc.data()!;
      await NotificationService.send(
        uid: data['uid'],
        title: 'Issue Approved ✅',
        body: 'Your issue "${data['title']}" has been approved',
        type: 'issue_approved',
        issueId: issueId,
      );
      await AuditService.log(
        action: 'ISSUE_APPROVED',
        description: 'Admin approved issue "${data['title']}"',
        metadata: {'issueId': issueId, 'issueTitle': data['title']},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue approved ✅'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // ── REJECT ───────────────────────────────────────────────────────
  Future<void> _rejectIssue(String issueId) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Issue'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Explain why this issue is being rejected...',
              alignLabelWithHint: true,
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Reason is required';
              if (v.trim().length < 10) return 'Please provide more detail';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    ).then((result) {
      reasonController.dispose();
      return result;
    });

    if (confirm != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'status': 'rejected',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .get();
      final data = issueDoc.data()!;
      await NotificationService.send(
        uid: data['uid'],
        title: 'Issue Rejected ❌',
        body: 'Your issue "${data['title']}" has been rejected',
        type: 'issue_rejected',
        issueId: issueId,
      );
      await AuditService.log(
        action: 'ISSUE_REJECTED',
        description: 'Admin rejected issue "${data['title']}"',
        metadata: {'issueId': issueId, 'issueTitle': data['title']},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue rejected'),
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

  // ── UPDATE STATUS ────────────────────────────────────────────────
  Future<void> _updateStatus(String issueId, String currentStatus) async {
    // Only approved issues can progress
    final allowedTransitions = {
      'approved': ['in_progress'],
      'in_progress': ['resolved'],
    };

    final nextStatuses = allowedTransitions[currentStatus];
    if (nextStatuses == null) return;

    String? selected = nextStatuses.first;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Update Issue Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: nextStatuses.map((status) {
              final config = _statusConfig[status]!;
              final color = config['color'] as Color;
              return RadioListTile<String>(
                value: status,
                groupValue: selected,
                onChanged: (v) => setStateDialog(() => selected = v),
                title: Row(
                  children: [
                    Icon(config['icon'] as IconData, color: color, size: 18),
                    const SizedBox(width: 8),
                    Text(config['label'] as String),
                  ],
                ),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || selected == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'status': selected,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AuditService.log(
        action: 'STATUS_UPDATED',
        description: 'Admin updated issue status to "$selected"',
        metadata: {'issueId': issueId, 'newStatus': selected},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Status updated to ${_statusConfig[selected]!['label']} ✅',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
// ── ASSIGN TO FIELD OFFICER ──────────────────────────────────────
  Future<void> _assignToFO(String issueId) async {
    // Fetch all field officers
    final foSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'fo')
        .get();

    if (foSnap.docs.isEmpty) {

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No field officers registered yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String? selectedFOId;
    String? selectedFOName;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Assign to Field Officer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: foSnap.docs.map((doc) {
              final data = doc.data();
              return RadioListTile<String>(
                value: doc.id,
                groupValue: selectedFOId,
                onChanged: (v) => setStateDialog(() {
                  selectedFOId = v;
                  selectedFOName = data['name'];
                }),
                title: Text(data['name'] ?? ''),
                subtitle: Text(data['email'] ?? ''),
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedFOId == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || selectedFOId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'assignedTo': selectedFOId,
        'assignedToName': selectedFOName,
        'assignedAt': FieldValue.serverTimestamp(),
        'taskStatus': 'assigned', // FO-specific status
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .get();
      final data = issueDoc.data()!;
      await NotificationService.send(
        uid: selectedFOId!,
        title: 'New Task Assigned 📋',
        body: 'You have been assigned to "${data['title']}"',
        type: 'task_assigned',
        issueId: issueId,
      );
      await AuditService.log(
        action: 'TASK_ASSIGNED',
        description: 'Admin assigned "${data['title']}" to $selectedFOName',
        metadata: {
          'issueId': issueId,
          'assignedTo': selectedFOId,
          'assignedToName': selectedFOName,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Assigned to $selectedFOName ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }
  // ── ISSUE DETAIL BOTTOM SHEET ────────────────────────────────────
  void _showIssueDetail(Map<String, dynamic> data, String issueId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title + status
              Row(
                children: [
                  Expanded(
                    child: Text(
                      data['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _statusBadge(data['status'] ?? 'pending'),
                ],
              ),
              const SizedBox(height: 8),

              // Meta info
              _detailRow(Icons.person_outline, 'Reported by', data['userName'] ?? ''),
              const SizedBox(height: 6),
              _detailRow(Icons.category_outlined, 'Issue Type', data['issueType'] ?? ''),
              const SizedBox(height: 6),
              _detailRow(
                Icons.access_time,
                'Submitted',
                data['createdAt'] != null
                    ? _formatDate(data['createdAt'].toDate())
                    : 'Unknown',
              ),
              const Divider(height: 24),

              // Description
              const Text(
                'Description',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                data['description'] ?? '',
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Image
              if (data['imageUrl'] != null) ...[
                const Text(
                  'Photo Evidence',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['imageUrl'],
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, progress) {
                      if (progress == null) return child;
                      return const SizedBox(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Map
              if (data['latitude'] != null && data['longitude'] != null) ...[
                const Text(
                  'Location',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          data['latitude'],
                          data['longitude'],
                        ),
                        initialZoom: 15,
                        interactionOptions: const InteractionOptions(
                          flags: InteractiveFlag.none,
                        ),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.muscat.municipality',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                data['latitude'],
                                data['longitude'],
                              ),
                              child: const Icon(
                                Icons.location_pin,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // ── ACTION BUTTONS ───────────────────────────
              const Divider(),
              const SizedBox(height: 12),

              // Pending → Approve or Reject
              if (data['status'] == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                        label: const Text(
                          'Reject',
                          style: TextStyle(color: Colors.red),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _rejectIssue(issueId);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _approveIssue(issueId);
                        },
                      ),
                    ),
                  ],
                ),
              ],

              // Approved or In Progress → Update Status
              if (data['status'] == 'approved' || data['status'] == 'in_progress') ...[
                // Assign button — show if not yet assigned
                if (data['assignedTo'] == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: const Text('Assign to Field Officer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6A1B9A),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _assignToFO(issueId);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  // Show who it's assigned to
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6A1B9A).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.engineering,
                            color: Color(0xFF6A1B9A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Assigned to: ${data['assignedToName']}',
                          style: const TextStyle(
                            color: Color(0xFF6A1B9A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Update Status'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(issueId, data['status']);
                    },
                  ),
                ),
              ],

              // Resolved or Rejected — no actions
              if (data['status'] == 'resolved' ||
                  data['status'] == 'rejected') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['status'] == 'resolved'
                        ? '✅ This issue has been resolved'
                        : '❌ This issue has been rejected',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black45),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black45),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.black45)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Issue Management'),
      ),
      body: Column(
        children: [
          // ── FILTER CHIPS ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in [
                    'all',
                    'pending',
                    'approved',
                    'rejected',
                    'in_progress',
                    'resolved',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter == 'all'
                              ? 'All'
                              : _statusConfig[filter]!['label'] as String,
                        ),
                        selected: _selectedFilter == filter,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                        selectedColor:
                        const Color(0xFF2E7D32).withOpacity(0.15),
                        checkmarkColor: const Color(0xFF2E7D32),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── ISSUE LIST ────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
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

                // Apply filter
                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['status'] ?? '') == _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inbox,
                            size: 48, color: Colors.black26),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'all'
                              ? 'No issues submitted yet'
                              : 'No ${_statusConfig[_selectedFilter]!['label']} issues',
                          style: const TextStyle(color: Colors.black45),
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
                    final status = data['status'] ?? 'pending';
                    final config = _statusConfig[status] ?? _statusConfig['pending']!;
                    final color = config['color'] as Color;

                    return GestureDetector(
                      onTap: () => _showIssueDetail(data, doc.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0A000000),
                              blurRadius: 6,
                            ),
                          ],
                          border: Border(
                            left: BorderSide(color: color, width: 4),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? 'No title',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  _statusBadge(status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      size: 13, color: Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['userName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.category_outlined,
                                      size: 13, color: Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['issueType'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black38,
                                    ),
                                  ),
                                ],
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
          ),
        ],
      ),
    );
  }
}