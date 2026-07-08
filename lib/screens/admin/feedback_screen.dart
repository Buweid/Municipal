import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _selectedFilter = 'all';

  Widget _stars(int rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        return Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 16,
        );
      }),
    );
  }

  Future<void> _showRespondDialog(
      String issueId, String? existingResponse) async {
    final l10n = AppLocalizations.of(context)!;
    final controller =
    TextEditingController(text: existingResponse ?? '');
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (ctx, setStateDialog) => PopScope(
            canPop: !isSaving,
            child: AlertDialog(
              backgroundColor: AppTheme.cardColor(context),
              title: Text(
                existingResponse != null
                    ? l10n.editResponse
                    : l10n.respondToFeedback,
                style: TextStyle(
                    color: AppTheme.textPrimaryColor(context)),
              ),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: l10n.yourResponse,
                    hintText: l10n.yourResponse,
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Response is required';
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
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!
                        .validate()) return;
                    setStateDialog(
                            () => isSaving = true);

                    try {
                      await FirebaseFirestore.instance
                          .collection('issues')
                          .doc(issueId)
                          .update({
                        'adminResponse':
                        controller.text.trim(),
                        'adminRespondedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                            Text('Response saved ✅'),
                            backgroundColor:
                            Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setStateDialog(
                                () => isSaving = false);
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
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(l10n.save),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) => controller.dispose());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.feedbackTitle),
      ),
      body: Column(
        children: [
          // ── FILTER ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final filter in [
                    'all',
                    'responded',
                    'not_responded',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          filter == 'all'
                              ? l10n.allFeedback
                              : filter == 'responded'
                              ? l10n.responded
                              : l10n.awaitingResponse,
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

          // ── FEEDBACK LIST ─────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('issues')
                  .where('rating', isGreaterThan: 0)
                  .orderBy('rating', descending: false)
                  .orderBy('ratedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child:
                      Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                if (_selectedFilter == 'responded') {
                  docs = docs.where((d) {
                    final data =
                    d.data() as Map<String, dynamic>;
                    return data['adminResponse'] != null;
                  }).toList();
                } else if (_selectedFilter ==
                    'not_responded') {
                  docs = docs.where((d) {
                    final data =
                    d.data() as Map<String, dynamic>;
                    return data['adminResponse'] == null;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline,
                            size: 56,
                            color: AppTheme.textSecondaryColor(
                                context)
                                .withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.noFeedbackYet,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(
                                context),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final totalRating =
                docs.fold<int>(0, (sum, d) {
                  final data =
                  d.data() as Map<String, dynamic>;
                  return sum +
                      ((data['rating'] as num?)?.toInt() ?? 0);
                });
                final avgRating = totalRating / docs.length;

                return Column(
                  children: [
                    // ── SUMMARY BAR ───────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(
                          16, 8, 16, 4),
                      padding: const EdgeInsets.all(16),
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
                      ),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                avgRating.toStringAsFixed(1),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.amber,
                                ),
                              ),
                              Text(l10n.avgRating,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme
                                        .textSecondaryColor(
                                        context),
                                  )),
                            ],
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppTheme.borderColor(
                                  context)),
                          Column(
                            children: [
                              Text(
                                docs.length.toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                              Text(l10n.totalReviews,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme
                                        .textSecondaryColor(
                                        context),
                                  )),
                            ],
                          ),
                          Container(
                              width: 1,
                              height: 40,
                              color: AppTheme.borderColor(
                                  context)),
                          Column(
                            children: [
                              Text(
                                docs
                                    .where((d) {
                                  final data = d.data()
                                  as Map<String,
                                      dynamic>;
                                  return data[
                                  'adminResponse'] !=
                                      null;
                                })
                                    .length
                                    .toString(),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.blue,
                                ),
                              ),
                              Text(l10n.responded,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme
                                        .textSecondaryColor(
                                        context),
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ── LIST ─────────────────────────────
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: docs.length,
                        separatorBuilder: (_, __) =>
                        const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = docs[index];
                          final data = doc.data()
                          as Map<String, dynamic>;
                          final rating =
                              (data['rating'] as num?)?.toInt() ?? 0;
                          final hasResponse =
                              data['adminResponse'] != null;
                          final ratedAt =
                          data['ratedAt'] != null
                              ? _formatDate(
                              (data['ratedAt']
                              as dynamic)
                                  .toDate()
                              as DateTime)
                              : '';

                          return Container(
                            decoration: BoxDecoration(
                              color:
                              AppTheme.cardColor(context),
                              borderRadius:
                              BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.shadowColor(
                                      context),
                                  blurRadius: 6,
                                ),
                              ],
                              border: Border(
                                left: BorderSide(
                                  color: rating <= 2
                                      ? Colors.red
                                      : rating == 3
                                      ? Colors.orange
                                      : const Color(
                                      0xFF2E7D32),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding:
                              const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // Title + stars
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['title'] ?? '',
                                          style: TextStyle(
                                            fontWeight:
                                            FontWeight.w700,
                                            fontSize: 14,
                                            color: AppTheme
                                                .textPrimaryColor(
                                                context),
                                          ),
                                        ),
                                      ),
                                      _stars(rating),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Citizen + date
                                  Row(
                                    children: [
                                      Icon(
                                          Icons.person_outline,
                                          size: 12,
                                          color: AppTheme
                                              .textSecondaryColor(
                                              context)),
                                      const SizedBox(width: 4),
                                      Text(
                                        data['userName'] ?? '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme
                                              .textSecondaryColor(
                                              context),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        ratedAt,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme
                                              .textSecondaryColor(
                                              context),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Comment
                                  if (data['ratingComment'] !=
                                      null &&
                                      (data['ratingComment']
                                      as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding:
                                      const EdgeInsets.all(
                                          10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.isDark(
                                            context)
                                            ? const Color(
                                            0xFF30363D)
                                            : Colors
                                            .grey.shade50,
                                        borderRadius:
                                        BorderRadius
                                            .circular(8),
                                        border: Border.all(
                                            color: AppTheme
                                                .borderColor(
                                                context)),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Icon(
                                            Icons.format_quote,
                                            size: 16,
                                            color: AppTheme
                                                .textSecondaryColor(
                                                context),
                                          ),
                                          const SizedBox(
                                              width: 6),
                                          Expanded(
                                            child: Text(
                                              data[
                                              'ratingComment'],
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppTheme
                                                    .textSecondaryColor(
                                                    context),
                                                fontStyle:
                                                FontStyle
                                                    .italic,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],

                                  // Admin response
                                  if (hasResponse) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding:
                                      const EdgeInsets.all(
                                          10),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary
                                            .withOpacity(0.06),
                                        borderRadius:
                                        BorderRadius
                                            .circular(8),
                                        border: Border.all(
                                          color: AppTheme
                                              .primary
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons
                                                    .admin_panel_settings,
                                                size: 14,
                                                color: AppTheme
                                                    .primary,
                                              ),
                                              const SizedBox(
                                                  width: 4),
                                              Text(
                                                l10n.adminResponse,
                                                style:
                                                const TextStyle(
                                                  fontSize: 12,
                                                  color: AppTheme
                                                      .primary,
                                                  fontWeight:
                                                  FontWeight
                                                      .w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 4),
                                          Text(
                                            data[
                                            'adminResponse'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: AppTheme
                                                  .textSecondaryColor(
                                                  context),
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),

                                  // Respond button
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      icon: Icon(
                                        hasResponse
                                            ? Icons.edit_outlined
                                            : Icons.reply,
                                        size: 16,
                                      ),
                                      label: Text(
                                        hasResponse
                                            ? l10n.editResponse
                                            : l10n.respond,
                                      ),
                                      style:
                                      OutlinedButton.styleFrom(
                                        foregroundColor:
                                        AppTheme.primary,
                                        side: const BorderSide(
                                            color:
                                            AppTheme.primary),
                                      ),
                                      onPressed: () =>
                                          _showRespondDialog(
                                            doc.id,
                                            data['adminResponse'],
                                          ),
                                    ),
                                  ),
                                ],
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