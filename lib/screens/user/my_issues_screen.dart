import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;
  String _selectedFilter = 'all';

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

  // ── RATING DIALOG ────────────────────────────────────────────────
  Future<void> _showRatingDialog(String issueId, String issueTitle) async {
    int selectedRating = 0;
    final commentController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) => PopScope(
            canPop: !isSubmitting,
            child: AlertDialog(
              title: const Text('Rate Service'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      issueTitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'How satisfied are you with the resolution?',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return GestureDetector(
                          onTap: () =>
                              setStateDialog(() => selectedRating = star),
                          child: Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              selectedRating >= star
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 38,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Rating label
                    Text(
                      selectedRating == 0
                          ? 'Tap a star to rate'
                          : selectedRating == 1
                          ? '😞 Very Unsatisfied'
                          : selectedRating == 2
                          ? '😕 Unsatisfied'
                          : selectedRating == 3
                          ? '😐 Neutral'
                          : selectedRating == 4
                          ? '😊 Satisfied'
                          : '😄 Very Satisfied',
                      style: TextStyle(
                        color: selectedRating == 0
                            ? Colors.black38
                            : Colors.amber.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Comment
                    TextField(
                      controller: commentController,
                      maxLines: 3,
                      maxLength: 200,
                      decoration: const InputDecoration(
                        labelText: 'Comment (optional)',
                        hintText: 'Share your experience...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                  isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting || selectedRating == 0
                      ? null
                      : () async {
                    setStateDialog(() => isSubmitting = true);

                    try {
                      await FirebaseFirestore.instance
                          .collection('issues')
                          .doc(issueId)
                          .update({
                        'rating': selectedRating,
                        'ratingComment': commentController.text.trim(),
                        'ratedAt': FieldValue.serverTimestamp(),
                      });

                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your feedback ⭐'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setStateDialog(() => isSubmitting = false);
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Submit Rating'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => commentController.dispose());
  }

  // ── ISSUE DETAIL ─────────────────────────────────────────────────
  void _showIssueDetail(Map<String, dynamic> data, String issueId) {
    final status = data['status'] ?? 'pending';
    final hasRating = data['rating'] != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                  _statusBadge(status),
                ],
              ),
              const SizedBox(height: 12),

              _infoRow(Icons.category_outlined,
                  'Type', data['issueType'] ?? ''),
              const SizedBox(height: 6),
              _infoRow(
                Icons.access_time,
                'Submitted',
                data['createdAt'] != null
                    ? _formatDate(data['createdAt'].toDate())
                    : 'Unknown',
              ),
              const Divider(height: 24),

              // Description
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(
                data['description'] ?? '',
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 16),

              // Image
              if (data['imageUrl'] != null) ...[
                const Text('Photo Evidence',
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

              // Assigned FO
              if (data['assignedToName'] != null) ...[
                _infoRow(Icons.engineering,
                    'Assigned To', data['assignedToName']),
                const SizedBox(height: 16),
              ],

              // Existing rating
              if (hasRating) ...[
                const Divider(),
                const SizedBox(height: 12),
                const Text('Your Rating',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < (data['rating'] as int) ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 28,
                    ),
                  ),
                ),
                if (data['ratingComment'] != null &&
                    (data['ratingComment'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '"${data['ratingComment']}"',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Rate button — only for resolved and not yet rated
              if (status == 'resolved' && !hasRating) ...[
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Rate This Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showRatingDialog(issueId, data['title'] ?? '');
                    },
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Issues'),
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
                    'pending',
                    'approved',
                    'in_progress',
                    'resolved',
                    'rejected',
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

          // ── ISSUES LIST ───────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .where('uid', isEqualTo: _currentUid)
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
                    final config =
                        _statusConfig[status] ?? _statusConfig['pending']!;
                    final color = config['color'] as Color;
                    final hasRating = data['rating'] != null;
                    final isResolved = status == 'resolved';

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
                                      data['title'] ?? '',
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

                                  // Show stars if rated
                                  if (hasRating) ...[
                                    Row(
                                      children: List.generate(
                                        data['rating'] as int,
                                            (_) => const Icon(Icons.star,
                                            color: Colors.amber, size: 14),
                                      ),
                                    ),
                                  ]
                                  // Show rate prompt if resolved and not rated
                                  else if (isResolved) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.amber.shade700
                                                .withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star_outline,
                                              size: 12,
                                              color: Colors.amber.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Rate now',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.amber.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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