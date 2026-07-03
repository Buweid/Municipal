import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
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
  final String _currentFOId = FirebaseAuth.instance.currentUser!.uid;

  // ── TASK STATUS CONFIG ───────────────────────────────────────────
  final Map<String, Map<String, dynamic>> _taskStatusConfig = {
    'assigned': {
      'label': 'Assigned',
      'color': Colors.orange,
      'icon': Icons.assignment,
    },
    'accepted': {
      'label': 'Accepted',
      'color': Colors.blue,
      'icon': Icons.assignment_turned_in,
    },
    'rejected': {
      'label': 'Rejected',
      'color': Colors.red,
      'icon': Icons.assignment_late,
    },
    'in_progress': {
      'label': 'In Progress',
      'color': Colors.purple,
      'icon': Icons.engineering,
    },
    'completed': {
      'label': 'Completed',
      'color': Color(0xFF2E7D32),
      'icon': Icons.task_alt,
    },
  };

  Widget _taskStatusBadge(String status) {
    final config = _taskStatusConfig[status] ?? _taskStatusConfig['assigned']!;
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

  // ── ACCEPT TASK ──────────────────────────────────────────────────
  Future<void> _acceptTask(String issueId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Accept Task'),
        content: const Text('Confirm you are accepting this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Accept'),
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
        body: 'A field officer has accepted your issue "${data['title']}"',
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
        const SnackBar(
          content: Text('Task accepted ✅'),
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

  // ── REJECT TASK ──────────────────────────────────────────────────
  Future<void> _rejectTask(String issueId) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Task'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Reason for rejection',
              hintText: 'Explain why you cannot take this task...',
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
      final reason = reasonController.text.trim();
      reasonController.dispose();
      return result == true ? reason : null;
    });

    if (confirm == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .update({
        'taskStatus': 'rejected',
        'rejectionReason': confirm,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await AuditService.log(
        action: 'TASK_REJECTED',
        description: 'Field officer rejected task',
        metadata: {'issueId': issueId, 'reason': confirm},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task rejected'),
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

  // ── UPDATE PROGRESS ──────────────────────────────────────────────
  Future<void> _updateProgress(String issueId, String currentTaskStatus) async {
    final Map<String, List<String>> transitions = {
      'accepted': ['in_progress'],
      'in_progress': ['completed'],
    };

    final nextStatuses = transitions[currentTaskStatus];
    if (nextStatuses == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Progress'),
        content: Text(
          'Move task to "${_taskStatusConfig[nextStatuses.first]!['label']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
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
        'taskStatus': nextStatuses.first,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      final issueDoc = await FirebaseFirestore.instance
          .collection('issues')
          .doc(issueId)
          .get();
      final data = issueDoc.data()!;

      final isCompleted = nextStatuses.first == 'completed';
      await NotificationService.send(
        uid: data['uid'],
        title: isCompleted ? 'Issue Resolved ✅' : 'Work In Progress 🔧',
        body: isCompleted
            ? 'Your issue "${data['title']}" has been resolved'
            : 'Work has started on your issue "${data['title']}"',
        type: isCompleted ? 'issue_resolved' : 'issue_in_progress',
        issueId: issueId,
      );

      await AuditService.log(
        action: 'PROGRESS_UPDATED',
        description: 'Field officer updated task to "${nextStatuses.first}"',
        metadata: {'issueId': issueId, 'newStatus': nextStatuses.first},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progress updated to ${_taskStatusConfig[nextStatuses.first]!['label']} ✅',
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

  // ── UPLOAD EVIDENCE ──────────────────────────────────────────────
  Future<void> _uploadEvidence(String issueId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1200,
    );

    if (picked == null) return;

    final file = File(picked.path);

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('completion_evidence/$issueId.jpg');

      await ref.putFile(file);
      final url = await ref.getDownloadURL();

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
        const SnackBar(
          content: Text('Evidence uploaded ✅'),
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

  // ── TASK DETAIL BOTTOM SHEET ─────────────────────────────────────
  void _showTaskDetail(Map<String, dynamic> data, String issueId) {
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
                  _taskStatusBadge(taskStatus),
                ],
              ),
              const SizedBox(height: 12),

              _infoRow(Icons.category_outlined, 'Type', data['issueType'] ?? ''),
              const SizedBox(height: 6),
              _infoRow(Icons.person_outline, 'Reported by', data['userName'] ?? ''),
              const Divider(height: 24),

              // Description
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(data['description'] ?? '',
                  style: const TextStyle(color: Colors.black54, height: 1.5)),
              const SizedBox(height: 16),

              // Issue image
              if (data['imageUrl'] != null) ...[
                const Text('Issue Photo',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['imageUrl'],
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Evidence image
              if (data['evidenceUrl'] != null) ...[
                const Text('Completion Evidence',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data['evidenceUrl'],
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Location map
              if (data['latitude'] != null && data['longitude'] != null) ...[
                const Text('Location',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 160,
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

              const Divider(),
              const SizedBox(height: 12),

              // ── ACTION BUTTONS ───────────────────────────

              // Assigned → Accept or Reject
              if (taskStatus == 'assigned') ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close, color: Colors.red),
                        label: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 12),
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

              // Accepted or In Progress → Update Progress + Upload Evidence
              if (taskStatus == 'accepted' || taskStatus == 'in_progress') ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.update),
                    label: const Text('Update Progress'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                          ? 'Replace Evidence Photo'
                          : 'Upload Evidence Photo',
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                    color: const Color(0xFF2E7D32).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF2E7D32).withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_alt, color: Color(0xFF2E7D32), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Task completed ✅',
                        style: TextStyle(
                          color: Color(0xFF2E7D32),
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
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Task Rejected',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (data['rejectionReason'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          'Reason: ${data['rejectionReason']}',
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

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black45),
        const SizedBox(width: 6),
        Text('$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.black45)),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          const NotificationBell(),
        ],
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
                              ? 'All'
                              : _taskStatusConfig[filter]!['label'] as String,
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
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                // Apply filter
                if (_selectedFilter != 'all') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return (data['taskStatus'] ?? '') == _selectedFilter;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.assignment_outlined,
                            size: 48, color: Colors.black26),
                        SizedBox(height: 8),
                        Text(
                          'No tasks assigned to you yet',
                          style: TextStyle(color: Colors.black45),
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
                    final taskStatus = data['taskStatus'] ?? 'assigned';
                    final config = _taskStatusConfig[taskStatus] ??
                        _taskStatusConfig['assigned']!;
                    final color = config['color'] as Color;

                    return GestureDetector(
                      onTap: () => _showTaskDetail(data, doc.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
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
                                      data['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  _taskStatusBadge(taskStatus),
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
                                  const Spacer(),
                                  const Icon(Icons.person_outline,
                                      size: 13, color: Colors.black38),
                                  const SizedBox(width: 4),
                                  Text(
                                    'By ${data['userName'] ?? ''}',
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