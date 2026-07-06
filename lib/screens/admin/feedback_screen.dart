import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  String _selectedFilter = 'all';

  // ── STAR RATING WIDGET ───────────────────────────────────────────
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

  // ── RESPOND DIALOG ───────────────────────────────────────────────
  Future<void> _showRespondDialog(
      String issueId, String? existingResponse) async {
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
              title: Text(existingResponse != null
                  ? 'Edit Response'
                  : 'Respond to Feedback'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: const InputDecoration(
                    labelText: 'Your Response',
                    hintText: 'Write your response to the citizen...',
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
                  onPressed:
                  isSaving ? null : () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                    if (!formKey.currentState!.validate()) return;
                    setStateDialog(() => isSaving = true);

                    try {
                      await FirebaseFirestore.instance
                          .collection('issues')
                          .doc(issueId)
                          .update({
                        'adminResponse': controller.text.trim(),
                        'adminRespondedAt':
                        FieldValue.serverTimestamp(),
                      });

                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Response saved ✅'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        setStateDialog(() => isSaving = false);
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
                  child: isSaving
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Text('Save Response'),
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Feedback & Ratings'),
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
                              ? 'All Feedback'
                              : filter == 'responded'
                              ? 'Responded'
                              : 'Awaiting Response',
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                      child: Text('Error: ${snapshot.error}'));
                }

                var docs = snapshot.data?.docs ?? [];

                // Apply filter
                if (_selectedFilter == 'responded') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['adminResponse'] != null;
                  }).toList();
                } else if (_selectedFilter == 'not_responded') {
                  docs = docs.where((d) {
                    final data = d.data() as Map<String, dynamic>;
                    return data['adminResponse'] == null;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.star_outline,
                            size: 56, color: Colors.black26),
                        SizedBox(height: 12),
                        Text(
                          'No feedback yet',
                          style: TextStyle(
                              color: Colors.black45, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                // Calculate average rating
                final totalRating = docs.fold<int>(0, (sum, d) {
                  final data = d.data() as Map<String, dynamic>;
                  return sum + ((data['rating'] as int?) ?? 0);
                });
                final avgRating = totalRating / docs.length;

                return Column(
                  children: [
                    // ── SUMMARY BAR ───────────────────────
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Color(0x0A000000), blurRadius: 6),
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
                              const Text('Avg Rating',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45)),
                            ],
                          ),
                          Container(
                              width: 1, height: 40, color: Colors.black12),
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
                              const Text('Total Reviews',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45)),
                            ],
                          ),
                          Container(
                              width: 1, height: 40, color: Colors.black12),
                          Column(
                            children: [
                              Text(
                                docs
                                    .where((d) {
                                  final data = d.data()
                                  as Map<String, dynamic>;
                                  return data['adminResponse'] !=
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
                              const Text('Responded',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.black45)),
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
                          final data =
                          doc.data() as Map<String, dynamic>;
                          final rating =
                              (data['rating'] as int?) ?? 0;
                          final hasResponse =
                              data['adminResponse'] != null;
                          final ratedAt = data['ratedAt'] != null
                              ? _formatDate((data['ratedAt'] as dynamic)
                              .toDate() as DateTime)
                              : '';

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x0A000000),
                                    blurRadius: 6),
                              ],
                              border: Border(
                                left: BorderSide(
                                  color: rating <= 2
                                      ? Colors.red
                                      : rating == 3
                                      ? Colors.orange
                                      : const Color(0xFF2E7D32),
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  // Issue title + stars
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          data['title'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      _stars(rating),
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Citizen name + date
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline,
                                          size: 12,
                                          color: Colors.black38),
                                      const SizedBox(width: 4),
                                      Text(
                                        data['userName'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.black45,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        ratedAt,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Comment
                                  if (data['ratingComment'] != null &&
                                      (data['ratingComment'] as String)
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.black12),
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.format_quote,
                                              size: 16,
                                              color: Colors.black26),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              data['ratingComment'],
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.black54,
                                                fontStyle:
                                                FontStyle.italic,
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
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E7D32)
                                            .withOpacity(0.06),
                                        borderRadius:
                                        BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF2E7D32)
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
                                              Icon(
                                                Icons
                                                    .admin_panel_settings,
                                                size: 14,
                                                color: Color(0xFF2E7D32),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Admin Response',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color:
                                                  Color(0xFF2E7D32),
                                                  fontWeight:
                                                  FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            data['adminResponse'],
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
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
                                            ? 'Edit Response'
                                            : 'Respond',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                        const Color(0xFF2E7D32),
                                        side: const BorderSide(
                                            color: Color(0xFF2E7D32)),
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