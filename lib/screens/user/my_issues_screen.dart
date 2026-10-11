import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
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
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Map<String, Map<String, dynamic>> _statusConfig(AppLocalizations l10n) => {
    'pending': {
      'label': l10n.pending,
      'color': Colors.orange,
      'icon': Icons.hourglass_empty,
    },
    'approved': {
      'label': l10n.approved,
      'color': const Color(0xFF0EA5E9),
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

  // ── RATING DIALOG ────────────────────────────────────────────────

  Future<void> _showRatingDialog(
      String issueId, String issueTitle) async {
    final l10n = AppLocalizations.of(context)!;
    int selectedRating = 0;
    bool isSubmitting = false;
    final commentController = TextEditingController();

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (dialogContext, setStateDialog) {
              return PopScope(
                canPop: !isSubmitting,
                child: AlertDialog(
                  backgroundColor: AppTheme.cardColor(context),
                  title: Text(
                    l10n.rateService,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                    ),
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
                              onTap: isSubmitting
                                  ? null
                                  : () {
                                setStateDialog(() {
                                  selectedRating = star;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
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

                        // Optional comment
                        TextField(
                          controller: commentController,
                          enabled: !isSubmitting,
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
                          : () => Navigator.of(dialogContext).pop(),
                      child: Text(l10n.cancel),
                    ),
                    ElevatedButton(
                      onPressed: isSubmitting || selectedRating == 0
                          ? null
                          : () async {
                        setStateDialog(() {
                          isSubmitting = true;
                        });

                        try {
                          await FirebaseFirestore.instance
                              .collection('issues')
                              .doc(issueId)
                              .update({
                            'rating': selectedRating,
                            'ratingComment':
                            commentController.text.trim(),
                            'ratedAt':
                            FieldValue.serverTimestamp(),
                          });

                          if (!dialogContext.mounted) return;

                          Navigator.of(dialogContext).pop();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content:
                                Text(l10n.thankYouFeedback),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (dialogContext.mounted) {
                            setStateDialog(() {
                              isSubmitting = false;
                            });
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
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
              );
            },
          );
        },
      );
    } finally {
      // Dispose after showDialog has finished.
      commentController.dispose();
    }
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
    final isArabic = context.watch<SettingsProvider>().isArabic;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.myIssues),
      ),
      body: Column(
        children: [
          // ── SEARCH BAR ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              onChanged: (v) =>
                  setState(() => _searchQuery = v.toLowerCase().trim()),
              decoration: InputDecoration(
                hintText: isArabic
                    ? 'ابحث في بلاغاتك...'
                    : 'Search your issues...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                filled: true,
                fillColor: AppTheme.cardColor(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                  BorderSide(color: AppTheme.borderColor(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide:
                  BorderSide(color: AppTheme.borderColor(context)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  borderSide: const BorderSide(
                      color: AppTheme.primary, width: 1.5),
                ),
              ),
            ),
          ),

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

                if (_searchQuery.isNotEmpty) {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    final title =
                    (data['title'] ?? '').toString().toLowerCase();
                    final description = (data['description'] ?? '')
                        .toString()
                        .toLowerCase();
                    final issueType = (data['issueType'] ?? '')
                        .toString()
                        .toLowerCase();
                    return title.contains(_searchQuery) ||
                        description.contains(_searchQuery) ||
                        issueType.contains(_searchQuery);
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _searchQuery.isNotEmpty
                              ? Icons.search_off
                              : Icons.inbox,
                          size: 56,
                          color: AppTheme.textSecondaryColor(context)
                              .withOpacity(0.4),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _searchQuery.isNotEmpty
                              ? (isArabic
                              ? 'لا توجد نتائج لـ "$_searchQuery"'
                              : 'No results for "$_searchQuery"')
                              : _selectedFilter == 'all'
                              ? l10n.noIssuesYet
                              : '${l10n.noIssuesYet} (${_statusConfig(l10n)[_selectedFilter]!['label']})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 14,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            icon: const Icon(Icons.clear),
                            label: Text(isArabic
                                ? 'مسح البحث'
                                : 'Clear search'),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (_searchQuery.isNotEmpty)
                      Padding(
                        padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            Text(
                              isArabic
                                  ? '${docs.length} نتيجة'
                                  : '${docs.length} result${docs.length == 1 ? '' : 's'}',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                AppTheme.textSecondaryColor(context),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: ListView.separated(
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
                    final lat = (data['latitude'] as num?)?.toDouble();
                    final lng = (data['longitude'] as num?)?.toDouble();
                    final locationText = (lat != null && lng != null)
                        ? '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}'
                        : 'No location';

                    return GestureDetector(
                      onTap: () => _showIssueDetail(data, doc.id),
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
                              // ── ROW 1: icon · title/type · status ──
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
                                            fontWeight: FontWeight.w700,
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
                                  _statusBadge(status, l10n),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: AppTheme.borderColor(context),
                              ),
                              const SizedBox(height: 10),

                              // ── ROW 2: location · time ──
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined,
                                      size: 12,
                                      color: AppTheme.textSecondaryColor(
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
                                            .textSecondaryColor(context),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(Icons.access_time,
                                      size: 12,
                                      color: AppTheme.textSecondaryColor(
                                          context)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timeAgo(data['createdAt']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textSecondaryColor(
                                          context),
                                    ),
                                  ),
                                ],
                              ),

                              // ── Rating / Rate-now (bottom right) ──
                              if (hasRating) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: List.generate(
                                    (data['rating'] as num).toInt(),
                                        (_) => const Icon(Icons.star,
                                        color: Colors.amber,
                                        size: 14),
                                  ),
                                ),
                              ] else if (isResolved) ...[
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.end,
                                  children: [
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
                                        mainAxisSize: MainAxisSize.min,
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
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}