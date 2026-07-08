import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';
import '../services/notification_service.dart';
import '../services/audit_service.dart';

class IssueManagementScreen extends StatefulWidget {
  const IssueManagementScreen({super.key});

  @override
  State<IssueManagementScreen> createState() =>
      _IssueManagementScreenState();
}

class _IssueManagementScreenState extends State<IssueManagementScreen> {
  String _selectedFilter = 'all';

  Map<String, Map<String, dynamic>> _statusConfig(
      AppLocalizations l10n) =>
      {
        'pending': {
          'label': l10n.pending,
          'color': Colors.orange,
          'icon': Icons.hourglass_empty,
        },
        'approved': {
          'label': l10n.approved,
          'color': Colors.blue,
          'icon': Icons.check_circle_outline,
        },
        'rejected': {
          'label': l10n.rejected,
          'color': Colors.red,
          'icon': Icons.cancel_outlined,
        },
        'in_progress': {
          'label': l10n.inProgress,
          'color': Colors.purple,
          'icon': Icons.engineering,
        },
        'resolved': {
          'label': l10n.resolved,
          'color': const Color(0xFF2E7D32),
          'icon': Icons.task_alt,
        },
      };

  Widget _statusBadge(String status, AppLocalizations l10n) {
    final config = _statusConfig(l10n)[status] ??
        _statusConfig(l10n)['pending']!;
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
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(l10n.approveIssue,
            style:
            TextStyle(color: AppTheme.textPrimaryColor(context))),
        content: Text(
          'Are you sure you want to approve this issue?',
          style:
          TextStyle(color: AppTheme.textSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.approve),
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
        metadata: {
          'issueId': issueId,
          'issueTitle': data['title']
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.approved} ✅'),
          backgroundColor: Colors.blue,
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

  // ── REJECT ───────────────────────────────────────────────────────
  Future<void> _rejectIssue(String issueId) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? rejectionReason;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) => PopScope(
            canPop: !isSaving,
            child: AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              title: Text(l10n.rejectIssue,
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor(context))),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: l10n.reasonRejection,
                    hintText: l10n.explainRejection,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Reason is required';
                    }
                    if (v.trim().length < 10) {
                      return 'Please provide more detail';
                    }
                    return null;
                  },
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red),
                  onPressed: isSaving
                      ? null
                      : () {
                    if (formKey.currentState!.validate()) {
                      rejectionReason =
                          reasonController.text.trim();
                      Navigator.of(ctx).pop();
                    }
                  },
                  child: Text(l10n.reject),
                ),
              ],
            ),
          ),
        );
      },
    );

    // Dispose after dialog is fully closed
    reasonController.dispose();

    // Only proceed if reason was set (user clicked Reject not Cancel)
    if (rejectionReason == null) return;

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
        metadata: {
          'issueId': issueId,
          'issueTitle': data['title'],
          'reason': rejectionReason,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.rejected),
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
  // ── UPDATE STATUS ────────────────────────────────────────────────
  Future<void> _updateStatus(
      String issueId, String currentStatus) async {
    final l10n = AppLocalizations.of(context)!;

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
          backgroundColor: AppTheme.cardColor(context),
          title: Text(l10n.updateStatus,
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: nextStatuses.map((status) {
              final config = _statusConfig(l10n)[status]!;
              final color = config['color'] as Color;
              return RadioListTile<String>(
                value: status,
                groupValue: selected,
                onChanged: (v) =>
                    setStateDialog(() => selected = v),
                title: Row(
                  children: [
                    Icon(config['icon'] as IconData,
                        color: color, size: 18),
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
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.update),
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
              '${_statusConfig(l10n)[selected]!['label']} ✅'),
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
    }
  }

  // ── ASSIGN TO FIELD OFFICER ──────────────────────────────────────
  Future<void> _assignToFO(String issueId) async {
    final l10n = AppLocalizations.of(context)!;

    final foSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'fo')
        .get();

    if (!mounted) return;

    if (foSnap.docs.isEmpty) {
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
          backgroundColor: AppTheme.cardColor(context),
          title: Text(l10n.assignToFO,
              style: TextStyle(
                  color: AppTheme.textPrimaryColor(context))),
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
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: selectedFOId == null
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: Text(l10n.assign),
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
        'taskStatus': 'assigned',
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
        description:
        'Admin assigned "${data['title']}" to $selectedFOName',
        metadata: {
          'issueId': issueId,
          'assignedTo': selectedFOId,
          'assignedToName': selectedFOName,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedFOName ✅'),
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
    }
  }

  // ── ISSUE DETAIL BOTTOM SHEET ────────────────────────────────────
  void _showIssueDetail(Map<String, dynamic> data, String issueId) {
    final l10n = AppLocalizations.of(context)!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (ctx, scrollController) => Container(
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
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
                    color: AppTheme.borderColor(context),
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                  ),
                  _statusBadge(data['status'] ?? 'pending', l10n),
                ],
              ),
              const SizedBox(height: 8),

              _detailRow(Icons.person_outline, l10n.reportedBy,
                  data['userName'] ?? ''),
              const SizedBox(height: 6),
              _detailRow(Icons.category_outlined, l10n.issueType,
                  data['issueType'] ?? ''),
              const SizedBox(height: 6),
              _detailRow(
                Icons.access_time,
                l10n.submitted,
                data['createdAt'] != null
                    ? _formatDate(data['createdAt'].toDate())
                    : 'Unknown',
              ),
              const Divider(height: 24),

              // Description
              Text(
                l10n.description,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data['description'] ?? '',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // Image
              if (data['imageUrl'] != null) ...[
                Text(
                  l10n.photoEvidence,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor(context),
                  ),
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
                        child: Center(
                            child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Map
              if (data['latitude'] != null &&
                  data['longitude'] != null) ...[
                Text(
                  l10n.locationLabel,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 180,
                    child: FlutterMap(
                      options: MapOptions(
                        initialCenter: LatLng(
                          (data['latitude'] as num).toDouble(),
                          (data['longitude'] as num).toDouble(),
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
                          userAgentPackageName:
                          'com.muscat.municipality',
                        ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: LatLng(
                                (data['latitude'] as num).toDouble(),
                                (data['longitude'] as num).toDouble(),
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

              const Divider(),
              const SizedBox(height: 12),

              // Pending → Approve or Reject
              if (data['status'] == 'pending') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined,
                            color: Colors.red),
                        label: Text(l10n.reject,
                            style: const TextStyle(
                                color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side:
                          const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
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
                        icon: const Icon(
                            Icons.check_circle_outline),
                        label: Text(l10n.approve),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
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

              // Approved or In Progress
              if (data['status'] == 'approved' ||
                  data['status'] == 'in_progress') ...[
                if (data['assignedTo'] == null) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.person_add),
                      label: Text(l10n.assignToFO),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF6A1B9A),
                        padding: const EdgeInsets.symmetric(
                            vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _assignToFO(issueId);
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6A1B9A)
                          .withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF6A1B9A)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.engineering,
                            color: Color(0xFF6A1B9A), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.fieldOfficer}: ${data['assignedToName']}',
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
                    label: Text(l10n.updateStatus),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateStatus(issueId, data['status']);
                    },
                  ),
                ),
              ],

              // Resolved or Rejected
              if (data['status'] == 'resolved' ||
                  data['status'] == 'rejected') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.isDark(context)
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    data['status'] == 'resolved'
                        ? '✅ ${l10n.resolved}'
                        : '❌ ${l10n.rejected}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                      AppTheme.textSecondaryColor(context),
                    ),
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
    return Builder(builder: (context) {
      return Row(
        children: [
          Icon(icon,
              size: 15,
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
              value,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.issueManagement),
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
                              ? l10n.all
                              : _statusConfig(l10n)[filter]![
                          'label'] as String,
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

          // ── ISSUE LIST ────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
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
                      child: Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['status'] ?? '') ==
                        _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox,
                            size: 48,
                            color: AppTheme.textSecondaryColor(
                                context)
                                .withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'all'
                              ? l10n.noIssuesSubmitted
                              : '${l10n.noIssuesSubmitted} (${_statusConfig(l10n)[_selectedFilter]!['label']})',
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
                    final status = data['status'] ?? 'pending';
                    final config =
                        _statusConfig(l10n)[status] ??
                            _statusConfig(l10n)['pending']!;
                    final color = config['color'] as Color;

                    return GestureDetector(
                      onTap: () =>
                          _showIssueDetail(data, doc.id),
                      child: Container(
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
                                color: color, width: 4),
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
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight:
                                        FontWeight.w700,
                                        fontSize: 15,
                                        color: AppTheme
                                            .textPrimaryColor(
                                            context),
                                      ),
                                    ),
                                  ),
                                  _statusBadge(status, l10n),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                data['description'] ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                  AppTheme.textSecondaryColor(
                                      context),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.person_outline,
                                      size: 13,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['userName'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.category_outlined,
                                      size: 13,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['issueType'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context),
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