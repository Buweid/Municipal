import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';

class MyIssuesScreen extends StatefulWidget {
  const MyIssuesScreen({super.key});

  @override
  State<MyIssuesScreen> createState() => _MyIssuesScreenState();
}

class _MyIssuesScreenState extends State<MyIssuesScreen> {
  String get _currentUid =>
      FirebaseAuth.instance.currentUser?.uid ?? '';
  String _selectedFilter = 'all';

  Map<String, Map<String, dynamic>> _statusConfig(AppLocalizations l10n) => {
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
    final config =
        _statusConfig(l10n)[status] ?? _statusConfig(l10n)['pending']!;
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
  Future<void> _showRatingDialog(
      String issueId, String issueTitle) async {
    final l10n = AppLocalizations.of(context)!;
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
              backgroundColor: AppTheme.cardColor(context),
              title: Text(
                l10n.rateService,
                style:
                TextStyle(color: AppTheme.textPrimaryColor(context)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      issueTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.satisfactionQuestion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Star rating
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return GestureDetector(
                          onTap: () => setStateDialog(
                                  () => selectedRating = star),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6),
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
                          ? l10n.tapStarToRate
                          : selectedRating == 1
                          ? l10n.veryUnsatisfied
                          : selectedRating == 2
                          ? l10n.unsatisfied
                          : selectedRating == 3
                          ? l10n.neutral
                          : selectedRating == 4
                          ? l10n.satisfied
                          : l10n.verySatisfied,
                      style: TextStyle(
                        color: selectedRating == 0
                            ? AppTheme.textSecondaryColor(context)
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
                      decoration: InputDecoration(
                        labelText: l10n.commentOptional,
                        hintText: l10n.shareExperience,
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: Text(l10n.cancel),
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
                        'ratingComment':
                        commentController.text.trim(),
                        'ratedAt': FieldValue.serverTimestamp(),
                      });

                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.thankYouFeedback),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setStateDialog(
                                () => isSubmitting = false);
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
                      : Text(l10n.submitRating),
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
    final l10n = AppLocalizations.of(context)!;
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
                  _statusBadge(status, l10n),
                ],
              ),
              const SizedBox(height: 12),

              _infoRow(Icons.category_outlined, l10n.issueType,
                  data['issueType'] ?? ''),
              const SizedBox(height: 6),
              _infoRow(
                Icons.access_time,
                l10n.submitted,
                data['createdAt'] != null
                    ? _formatDate(data['createdAt'].toDate())
                    : 'Unknown',
              ),
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

              // Image
              if (data['imageUrl'] != null) ...[
                Text(l10n.photoEvidence,
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

              // Assigned FO
              if (data['assignedToName'] != null) ...[
                _infoRow(Icons.engineering, l10n.fieldOfficer,
                    data['assignedToName']),
                const SizedBox(height: 16),
              ],

              // Existing rating
              if (hasRating) ...[
                const Divider(),
                const SizedBox(height: 12),
                Text(l10n.yourRating,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    )),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                    5,
                        (i) => Icon(
                      i < (data['rating'] as num).toInt()
                          ? Icons.star
                          : Icons.star_border,
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
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],

              // Rate button
              if (status == 'resolved' && !hasRating) ...[
                const Divider(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.star_outline),
                    label: Text(l10n.rateThisService),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      padding:
                      const EdgeInsets.symmetric(vertical: 12),
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
    return Builder(builder: (context) {
      return Row(
        children: [
          Icon(icon, size: 15,
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
        title: Text(l10n.myIssues),
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
                              ? l10n.all
                              : _statusConfig(l10n)[filter]!['label']
                          as String,
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
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

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
                        Icon(Icons.inbox,
                            size: 48,
                            color: AppTheme.textSecondaryColor(context)
                                .withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          _selectedFilter == 'all'
                              ? l10n.noIssuesYet
                              : '${l10n.noIssuesYet} (${_statusConfig(l10n)[_selectedFilter]!['label']})',
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
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
                    final config = _statusConfig(l10n)[status] ??
                        _statusConfig(l10n)['pending']!;
                    final color = config['color'] as Color;
                    final hasRating = data['rating'] != null;
                    final isResolved = status == 'resolved';

                    return GestureDetector(
                      onTap: () => _showIssueDetail(data, doc.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor(context),
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
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? '',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                        color: AppTheme.textPrimaryColor(
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
                                  color: AppTheme.textSecondaryColor(
                                      context),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(Icons.category_outlined,
                                      size: 13,
                                      color: AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    data['issueType'] ?? '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondaryColor(
                                          context),
                                    ),
                                  ),
                                  const Spacer(),

                                  // Stars if rated
                                  if (hasRating) ...[
                                    Row(
                                      children: List.generate(
                                        (data['rating'] as num).toInt(),
                                            (_) => const Icon(Icons.star,
                                            color: Colors.amber,
                                            size: 14),
                                      ),
                                    ),
                                  ] else if (isResolved) ...[
                                    Container(
                                      padding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber
                                            .withOpacity(0.15),
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.amber.shade700
                                                .withOpacity(0.5)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.star_outline,
                                              size: 12,
                                              color:
                                              Colors.amber.shade700),
                                          const SizedBox(width: 4),
                                          Text(
                                            l10n.rateNow,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color:
                                              Colors.amber.shade700,
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