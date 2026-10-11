import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/cloudinary_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../constants/app_theme.dart';
import '../services/notification_service.dart';
import '../../widgets/notification_bell.dart';
import '../services/audit_service.dart';

class FOTasksScreen extends StatefulWidget {
  const FOTasksScreen({super.key});

  @override
  State<FOTasksScreen> createState() => _FOTasksScreenState();
}

class _FOTasksScreenState extends State<FOTasksScreen> {
  String _selectedFilter = 'all';
  String get _currentFOId =>
      FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, Map<String, dynamic>> _taskStatusConfig(
      AppLocalizations l10n) =>
      {
        'assigned': {
          'label': l10n.myTasks,
          'color': Colors.orange,
          'icon': Icons.assignment,
        },
        'accepted': {
          'label': l10n.accept,
          'color': const Color(0xFF0EA5E9),
          'icon': Icons.assignment_turned_in,
        },
        'rejected': {
          'label': l10n.rejected,
          'color': Colors.red,
          'icon': Icons.assignment_late,
        },
        'in_progress': {
          'label': l10n.inProgress,
          'color': Colors.purple,
          'icon': Icons.engineering,
        },
        'completed': {
          'label': l10n.doneTasks,
          'color': const Color(0xFF2E7D32),
          'icon': Icons.task_alt,
        },
      };

  Widget _taskStatusBadge(String status, AppLocalizations l10n) {
    final config = _taskStatusConfig(l10n)[status] ??
        _taskStatusConfig(l10n)['assigned']!;
    final color = config['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── ISSUE STATUS (overall issue status, shown alongside taskStatus) ──
  Map<String, Map<String, dynamic>> _statusConfig(
      AppLocalizations l10n) =>
      {
        'pending': {'label': l10n.pending, 'color': Colors.orange},
        'approved': {
          'label': l10n.approved,
          'color': const Color(0xFF0EA5E9),
        },
        'rejected': {'label': l10n.rejected, 'color': Colors.red},
        'in_progress': {
          'label': l10n.inProgress,
          'color': Colors.purple,
        },
        'resolved': {
          'label': l10n.resolved,
          'color': const Color(0xFF2E7D32),
        },
      };

  Widget _statusBadge(String status, AppLocalizations l10n) {
    final config =
        _statusConfig(l10n)[status] ?? _statusConfig(l10n)['pending']!;
    final color = config['color'] as Color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ── ISSUE TYPE ICON MAPPING ────────────────────────────────────────
  final Map<String, IconData> _issueTypeIcons = {
    'Road': Icons.add_road,
    'Water': Icons.water_damage,
    'Electricity': Icons.electrical_services,
    'Garbage': Icons.delete_outline,
    'Tree': Icons.park,
    'Building': Icons.apartment,
    'Lighting': Icons.lightbulb_outline,
    'Sewage': Icons.plumbing,
    'Noise': Icons.volume_up,
    'Other': Icons.report_problem_outlined,
  };

  IconData _getIssueIcon(String? issueType) {
    if (issueType == null) return Icons.report_problem_outlined;
    for (final key in _issueTypeIcons.keys) {
      if (issueType.toLowerCase().contains(key.toLowerCase())) {
        return _issueTypeIcons[key]!;
      }
    }
    return Icons.report_problem_outlined;
  }

  // ── TIME AGO ─────────────────────────────────────────────────────
  String _timeAgo(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = (timestamp as dynamic).toDate() as DateTime;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── ACCEPT TASK ──────────────────────────────────────────────────
  Future<void> _acceptTask(String issueId) async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(l10n.acceptTask,
            style:
            TextStyle(color: AppTheme.textPrimaryColor(context))),
        content: Text(l10n.confirmAcceptTask,
            style:
            TextStyle(color: AppTheme.textSecondaryColor(context))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.accept),
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
        'taskStatus': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .get();
      final data = issueDoc.data()!;
      await NotificationService.send(
        uid: data['uid'],
        title: 'Task Accepted 👷',
        body:
        'A field officer has accepted your issue "${data['title']}"',
        type: 'task_accepted',
        issueId: issueId,
      );
      await AuditService.log(
        action: 'TASK_ACCEPTED',
        description: 'Field officer accepted task',
        metadata: {'issueId': issueId},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskCompleted),
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

  // ── REJECT TASK ──────────────────────────────────────────────────
  Future<void> _rejectTask(String issueId) async {
    final l10n = AppLocalizations.of(context)!;
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String? rejectionReason;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          l10n.rejectTask,
          style: TextStyle(color: AppTheme.textPrimaryColor(context)),
        ),
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
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style:
            ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                rejectionReason = reasonController.text.trim();
                Navigator.of(ctx).pop();
              }
            },
            child: Text(l10n.reject),
          ),
        ],
      ),
    );

    // Dispose only after dialog fully closed
    reasonController.dispose();

    // User cancelled
    if (rejectionReason == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'taskStatus': 'rejected',
        'rejectionReason': rejectionReason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await AuditService.log(
        action: 'TASK_REJECTED',
        description: 'Field officer rejected task',
        metadata: {
          'issueId': issueId,
          'reason': rejectionReason,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.taskRejected),
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


  // ── UPDATE PROGRESS ──────────────────────────────────────────────
  Future<void> _updateProgress(
      String issueId, String currentTaskStatus) async {
    final l10n = AppLocalizations.of(context)!;

    final Map<String, List<String>> transitions = {
      'accepted': ['in_progress'],
      'in_progress': ['completed'],
    };

    final nextStatuses = transitions[currentTaskStatus];
    if (nextStatuses == null) return;

    final nextTaskStatus = nextStatuses.first;
    final isCompleted = nextTaskStatus == 'completed';

    final nextLabel =
    _taskStatusConfig(l10n)[nextTaskStatus]!['label'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(context),
        title: Text(
          l10n.updateProgress,
          style: TextStyle(
            color: AppTheme.textPrimaryColor(context),
          ),
        ),
        content: Text(
          '${l10n.moveTaskTo} "$nextLabel"?',
          style: TextStyle(
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Update the task status and overall issue status together.
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'taskStatus': nextTaskStatus,
        if (nextTaskStatus == 'in_progress')
          'status': 'in_progress',
        if (isCompleted) 'status': 'resolved',
        if (isCompleted)
          'resolvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .get();

      final data = issueDoc.data();

      if (data == null) {
        throw Exception('Issue not found after updating progress.');
      }

      // Notify the user about the progress update.
      await NotificationService.send(
        uid: data['uid'],
        title: isCompleted
            ? 'Issue Resolved ✅'
            : 'Work In Progress 🔧',
        body: isCompleted
            ? 'Your issue "${data['title']}" has been resolved'
            : 'Work has started on your issue "${data['title']}"',
        type: isCompleted
            ? 'issue_resolved'
            : 'issue_in_progress',
        issueId: issueId,
      );

      await AuditService.log(
        action: 'PROGRESS_UPDATED',
        description:
        'Field officer updated task to "$nextTaskStatus"',
        metadata: {
          'issueId': issueId,
          'newStatus': nextTaskStatus,
          'issueStatus': isCompleted
              ? 'resolved'
              : 'in_progress',
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isCompleted
                ? '${l10n.resolved} ✅'
                : '$nextLabel ✅',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  // ── UPLOAD EVIDENCE ──────────────────────────────────────────────
  Future<void> _uploadEvidence(String issueId) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final file = File(picked.path);

    try {
      final url = await CloudinaryService.uploadImage(file);

      if (url == null) throw Exception('Upload failed');

      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'evidenceUrl': url,
        'evidenceUploadedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await AuditService.log(
        action: 'EVIDENCE_UPLOADED',
        description: 'Field officer uploaded completion evidence',
        metadata: {'issueId': issueId},
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.uploadEvidence} ✅'),
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

  // ── TASK DETAIL BOTTOM SHEET ─────────────────────────────────────
  void _showTaskDetail(Map<String, dynamic> data, String issueId) {
    final l10n = AppLocalizations.of(context)!;
    final taskStatus = data['taskStatus'] ?? 'assigned';

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
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(24)),
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
                  _taskStatusBadge(taskStatus, l10n),
                ],
              ),
              const SizedBox(height: 12),

              _infoRow(Icons.category_outlined, l10n.issueType,
                  data['issueType'] ?? ''),
              const SizedBox(height: 6),
              _infoRow(Icons.person_outline, l10n.reportedBy,
                  data['userName'] ?? ''),
              const Divider(height: 24),

              // Description
              Text(l10n.description,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryColor(context),
                  )),
              const SizedBox(height: 6),
              Text(
                data['description'] ?? '',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),

              // ── STATUS TIMELINE ──────────────────────────────
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                l10n.issueProgress,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),
              _buildTimeline(data, context),
              const SizedBox(height: 16),

              // Issue image
              if (data['imageUrl'] != null) ...[
                Text(l10n.issuePhoto,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['imageUrl'],
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Evidence image
              if (data['evidenceUrl'] != null) ...[
                Text(l10n.completionEvidence,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['evidenceUrl'],
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: Colors.grey,
                          size: 40,
                        ),
                      ),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Location map
              if (data['latitude'] != null &&
                  data['longitude'] != null) ...[
                Text(l10n.locationLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
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

              // Assigned → Accept or Reject
              if (taskStatus == 'assigned') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: Text(l10n.reject,
                            style:
                            const TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _rejectTask(issueId);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check),
                        label: Text(l10n.accept),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _acceptTask(issueId);
                        },
                      ),
                    ),
                  ],
                ),
              ],

              // Accepted or In Progress
              if (taskStatus == 'accepted' ||
                  taskStatus == 'in_progress') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    label: Text(l10n.updateProgress),
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _updateProgress(issueId, taskStatus);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(
                      data['evidenceUrl'] != null
                          ? l10n.replaceEvidence
                          : l10n.uploadEvidence,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _uploadEvidence(issueId);
                    },
                  ),
                ),
              ],

              // Completed
              if (taskStatus == 'completed') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.task_alt,
                          color: AppTheme.primary, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        l10n.taskCompleted,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Rejected
              if (taskStatus == 'rejected') ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l10n.taskRejected,
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (data['rejectionReason'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          '${l10n.reasonRejection}: ${data['rejectionReason']}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
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
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── STATUS TIMELINE ────────────────────────────────────────────────
  Widget _buildTimeline(Map<String, dynamic> data, BuildContext context) {
    final status = data['status'] ?? 'pending';

    // Define all possible stages in order
    final List<Map<String, dynamic>> stages = [
      {
        'key': 'submitted',
        'label': 'Submitted',
        'labelAr': 'تم التقديم',
        'icon': Icons.upload_outlined,
        'color': const Color(0xFF0EA5E9),
        'timestamp': data['createdAt'],
        'done': true, // always done
      },
      {
        'key': 'approved',
        'label': 'Approved',
        'labelAr': 'تمت الموافقة',
        'icon': Icons.check_circle_outline,
        'color': Colors.blue,
        'timestamp': data['approvedAt'],
        'done': ['approved', 'in_progress', 'resolved']
            .contains(status),
      },
      {
        'key': 'assigned',
        'label': 'Assigned to Officer',
        'labelAr': 'تم التعيين',
        'icon': Icons.engineering_outlined,
        'color': const Color(0xFF7C3AED),
        'timestamp': data['assignedAt'],
        'done': data['assignedTo'] != null,
      },
      {
        'key': 'in_progress',
        'label': 'In Progress',
        'labelAr': 'قيد التنفيذ',
        'icon': Icons.construction_outlined,
        'color': Colors.purple,
        'timestamp': data['updatedAt'],
        'done': ['in_progress', 'resolved'].contains(status),
      },
      {
        'key': 'resolved',
        'label': 'Resolved',
        'labelAr': 'تم الحل',
        'icon': Icons.task_alt,
        'color': const Color(0xFF2E7D32),
        'timestamp': data['updatedAt'],
        'done': status == 'resolved',
      },
    ];

    // If rejected, show rejection stage instead of rest
    if (status == 'rejected') {
      stages.removeRange(1, stages.length);
      stages.add({
        'key': 'rejected',
        'label': 'Rejected',
        'labelAr': 'مرفوض',
        'icon': Icons.cancel_outlined,
        'color': Colors.red,
        'timestamp': data['updatedAt'],
        'done': true,
      });
    }

    final isArabic = context.read<SettingsProvider>().isArabic;

    return Column(
      children: stages.asMap().entries.map((entry) {
        final index = entry.key;
        final stage = entry.value;
        final isDone = stage['done'] as bool;
        final isLast = index == stages.length - 1;
        final color = isDone
            ? stage['color'] as Color
            : AppTheme.borderColor(context);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── LEFT SIDE: icon + line ──────────
            SizedBox(
              width: 40,
              child: Column(
                children: [
                  // Circle icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? (stage['color'] as Color).withOpacity(0.12)
                          : AppTheme.borderColor(context)
                          .withOpacity(0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: isDone ? 2 : 1,
                      ),
                    ),
                    child: Icon(
                      stage['icon'] as IconData,
                      size: 16,
                      color: isDone
                          ? stage['color'] as Color
                          : AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  // Connecting line
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 40,
                      color: isDone
                          ? (stage['color'] as Color).withOpacity(0.3)
                          : AppTheme.borderColor(context),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── RIGHT SIDE: label + time ────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic
                          ? stage['labelAr'] as String
                          : stage['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isDone
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isDone
                            ? AppTheme.textPrimaryColor(context)
                            : AppTheme.textSecondaryColor(context),
                      ),
                    ),
                    if (isDone && stage['timestamp'] != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(
                            (stage['timestamp'] as dynamic).toDate()
                            as DateTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ] else if (!isDone) ...[
                      const SizedBox(height: 2),
                      Text(
                        isArabic ? 'في الانتظار' : 'Pending',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondaryColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
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
        title: Text(l10n.myTasks),
        actions: const [NotificationBell()],
      ),
      body: Column(
        children: [
          // ── FILTER CHIPS ──────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in [
                    'all',
                    'assigned',
                    'accepted',
                    'in_progress',
                    'completed',
                    'rejected',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter == 'all'
                              ? l10n.all
                              : _taskStatusConfig(l10n)[filter]![
                          'label'] as String,
                        ),
                        selected: _selectedFilter == filter,
                        onSelected: (_) =>
                            setState(() => _selectedFilter = filter),
                        selectedColor: AppTheme.primary.withOpacity(0.15),
                        checkmarkColor: AppTheme.primary,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── TASK LIST ─────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .where('assignedTo', isEqualTo: _currentFOId)
                  .orderBy('assignedAt', descending: true)
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

                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['taskStatus'] ?? '') == _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 48,
                            color: AppTheme.textSecondaryColor(context)
                                .withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          l10n.noTasksAssigned,
                          style: TextStyle(
                            color:
                            AppTheme.textSecondaryColor(context),
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
                    final taskStatus =
                        data['taskStatus'] ?? 'assigned';
                    final config =
                        _taskStatusConfig(l10n)[taskStatus] ??
                            _taskStatusConfig(l10n)['assigned']!;
                    final color = config['color'] as Color;
                    final status = data['status'] ?? 'pending';
                    final isAssigned = data['assignedTo'] != null;
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();
                    final locationText = (lat != null && lng != null)
                        ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
                        : 'No location';

                    return GestureDetector(
                      onTap: () => _showTaskDetail(data, doc.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor(context),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              // ── ROW 1: icon · title/type · badges ──
                              Row(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: color.withOpacity(0.1),
                                      borderRadius:
                                      BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      _getIssueIcon(data['issueType']),
                                      color: color,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['title'] ?? '',
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontWeight:
                                            FontWeight.w700,
                                            fontSize: 14,
                                            color: AppTheme
                                                .textPrimaryColor(
                                                context),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          data['issueType'] ?? '',
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme
                                                .textSecondaryColor(
                                                context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Wrap(
                                      alignment: WrapAlignment.end,
                                      crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        _statusBadge(status, l10n),
                                        if (isAssigned)
                                          _taskStatusBadge(
                                              taskStatus, l10n),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: AppTheme.borderColor(context),
                              ),
                              const SizedBox(height: 10),

                              // ── ROW 2: location · reporter · time ──
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      locationText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme
                                            .textSecondaryColor(
                                            context),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.person_outline,
                                      size: 12,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      data['userName'] ?? '',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme
                                            .textSecondaryColor(
                                            context),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(Icons.access_time,
                                      size: 12,
                                      color:
                                      AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timeAgo(data['createdAt']),
                                    style: TextStyle(
                                      fontSize: 11,
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