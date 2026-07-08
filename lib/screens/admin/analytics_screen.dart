import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  bool _isLoading = true;
  bool _isGeneratingPdf = false;

  int _totalIssues = 0;
  int _pending = 0;
  int _approved = 0;
  int _inProgress = 0;
  int _resolved = 0;
  int _rejected = 0;
  int _totalUsers = 0;
  int _totalFOs = 0;
  double _avgRating = 0;
  int _ratedCount = 0;

  Map<String, int> _issueTypeCount = {};
  Map<String, int> _monthlyIssues = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final issuesSnap = await FirebaseFirestore.instance
          .collection('issues')
          .get();
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .get();

      int pending = 0,
          approved = 0,
          inProgress = 0,
          resolved = 0,
          rejected = 0;
      int totalRating = 0, ratedCount = 0;
      Map<String, int> typeCount = {};
      Map<String, int> monthlyCount = {};

      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final key = '${_monthName(month.month)} ${month.year}';
        monthlyCount[key] = 0;
      }

      for (final doc in issuesSnap.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'pending';
        final type = data['issueType'] ?? 'Other';

        if (status == 'pending') pending++;
        else if (status == 'approved') approved++;
        else if (status == 'in_progress') inProgress++;
        else if (status == 'resolved') resolved++;
        else if (status == 'rejected') rejected++;

        typeCount[type] = (typeCount[type] ?? 0) + 1;

        if (data['rating'] != null) {
          totalRating += (data['rating'] as num).toInt();
          ratedCount++;
        }

        if (data['createdAt'] != null) {
          final date =
          (data['createdAt'] as dynamic).toDate() as DateTime;
          final key = '${_monthName(date.month)} ${date.year}';
          if (monthlyCount.containsKey(key)) {
            monthlyCount[key] = (monthlyCount[key] ?? 0) + 1;
          }
        }
      }

      int citizens = 0, fos = 0;
      for (final doc in usersSnap.docs) {
        final role = doc['role'] ?? 'user';
        if (role == 'user') citizens++;
        else if (role == 'fo') fos++;
      }

      if (!mounted) return;
      setState(() {
        _totalIssues = issuesSnap.docs.length;
        _pending = pending;
        _approved = approved;
        _inProgress = inProgress;
        _resolved = resolved;
        _rejected = rejected;
        _totalUsers = citizens;
        _totalFOs = fos;
        _avgRating =
        ratedCount > 0 ? totalRating / ratedCount : 0;
        _ratedCount = ratedCount;
        _issueTypeCount = typeCount;
        _monthlyIssues = monthlyCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  Future<void> _generatePDF() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isGeneratingPdf = true);

    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) => [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('2E7D32'),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment:
                pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    l10n.appName,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    l10n.analyticsReports,
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 13,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Generated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Summary
            pw.Text(
              l10n.overview,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300),
              children: [
                _pdfTableRow(l10n.totalIssues,
                    _totalIssues.toString()),
                _pdfTableRow(
                    l10n.pending, _pending.toString()),
                _pdfTableRow(
                    l10n.approved, _approved.toString()),
                _pdfTableRow(
                    l10n.inProgress, _inProgress.toString()),
                _pdfTableRow(
                    l10n.resolved, _resolved.toString()),
                _pdfTableRow(
                    l10n.rejected, _rejected.toString()),
                _pdfTableRow(
                    l10n.citizens, _totalUsers.toString()),
                _pdfTableRow(l10n.fieldOfficers,
                    _totalFOs.toString()),
                _pdfTableRow(
                  l10n.avgRating,
                  _ratedCount > 0
                      ? '${_avgRating.toStringAsFixed(1)} / 5.0 ($_ratedCount ${l10n.totalReviews})'
                      : 'N/A',
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Performance
            pw.Text(
              'Performance',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(
                  color: PdfColors.grey300),
              children: [
                _pdfTableRow(
                  l10n.resolutionRate,
                  _totalIssues > 0
                      ? '${(_resolved / _totalIssues * 100).toStringAsFixed(1)}%'
                      : '0%',
                ),
                _pdfTableRow(
                  l10n.rejected,
                  _totalIssues > 0
                      ? '${(_rejected / _totalIssues * 100).toStringAsFixed(1)}%'
                      : '0%',
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            if (_issueTypeCount.isNotEmpty) ...[
              pw.Text(
                l10n.issuesByType,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColors.grey300),
                children: [
                  ..._issueTypeCount.entries.map(
                        (e) => _pdfTableRow(
                        e.key, e.value.toString()),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
            ],

            if (_monthlyIssues.isNotEmpty) ...[
              pw.Text(
                l10n.monthlyIssues,
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColors.grey300),
                children: [
                  ..._monthlyIssues.entries.map(
                        (e) => _pdfTableRow(
                        e.key, e.value.toString()),
                  ),
                ],
              ),
            ],
          ],
        ),
      );

      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name:
        'municipality_report_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  pw.TableRow _pdfTableRow(String col1, String col2,
      {bool isHeader = false}) {
    return pw.TableRow(
      decoration: isHeader
          ? pw.BoxDecoration(
          color: PdfColor.fromHex('E8F5E9'))
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            col1,
            style: pw.TextStyle(
              fontWeight: isHeader
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            col2,
            style: pw.TextStyle(
              fontWeight: isHeader
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.analyticsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadAnalytics,
        child: SingleChildScrollView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ── SUMMARY CARDS ──────────────────────
              Text(
                l10n.overview,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color:
                  AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  _summaryCard(l10n.totalIssues,
                      _totalIssues,
                      Icons.report_outlined,
                      Colors.blueGrey),
                  const SizedBox(width: 12),
                  _summaryCard(l10n.resolved,
                      _resolved, Icons.task_alt,
                      const Color(0xFF2E7D32)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard(l10n.pending,
                      _pending,
                      Icons.hourglass_empty,
                      Colors.orange),
                  const SizedBox(width: 12),
                  _summaryCard(l10n.rejected,
                      _rejected,
                      Icons.cancel_outlined,
                      Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _summaryCard(l10n.citizens,
                      _totalUsers,
                      Icons.people_outline,
                      Colors.teal),
                  const SizedBox(width: 12),
                  _summaryCard(l10n.fieldOfficers,
                      _totalFOs,
                      Icons.engineering_outlined,
                      const Color(0xFF6A1B9A)),
                ],
              ),
              const SizedBox(height: 20),

              // ── RATING CARD ────────────────────────
              Container(
                width: double.infinity,
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
                  children: [
                    const Icon(Icons.star,
                        color: Colors.amber, size: 36),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ratedCount > 0
                              ? _avgRating
                              .toStringAsFixed(1)
                              : 'N/A',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.amber,
                          ),
                        ),
                        Text(
                          '${l10n.avgRating} ($_ratedCount ${l10n.totalReviews})',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            AppTheme.textSecondaryColor(
                                context),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                          _totalIssues > 0
                              ? '${(_resolved / _totalIssues * 100).toStringAsFixed(0)}%'
                              : '0%',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                        Text(
                          l10n.resolutionRate,
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
              const SizedBox(height: 24),

              // ── PIE CHART ─────────────────────────
              Text(
                l10n.issuesByStatus,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color:
                  AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                child: _totalIssues == 0
                    ? SizedBox(
                  height: 180,
                  child: Center(
                    child: Text(
                      'No data yet',
                      style: TextStyle(
                        color: AppTheme
                            .textSecondaryColor(
                            context),
                      ),
                    ),
                  ),
                )
                    : Column(
                  children: [
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 40,
                          sections: [
                            if (_pending > 0)
                              _pieSection(
                                  _pending,
                                  Colors.orange,
                                  l10n.pending),
                            if (_approved > 0)
                              _pieSection(
                                  _approved,
                                  Colors.blue,
                                  l10n.approved),
                            if (_inProgress > 0)
                              _pieSection(
                                  _inProgress,
                                  Colors.purple,
                                  l10n.inProgress),
                            if (_resolved > 0)
                              _pieSection(
                                  _resolved,
                                  const Color(
                                      0xFF2E7D32),
                                  l10n.resolved),
                            if (_rejected > 0)
                              _pieSection(
                                  _rejected,
                                  Colors.red,
                                  l10n.rejected),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        if (_pending > 0)
                          _legendItem(
                              Colors.orange,
                              l10n.pending,
                              _pending),
                        if (_approved > 0)
                          _legendItem(
                              Colors.blue,
                              l10n.approved,
                              _approved),
                        if (_inProgress > 0)
                          _legendItem(
                              Colors.purple,
                              l10n.inProgress,
                              _inProgress),
                        if (_resolved > 0)
                          _legendItem(
                              const Color(
                                  0xFF2E7D32),
                              l10n.resolved,
                              _resolved),
                        if (_rejected > 0)
                          _legendItem(
                              Colors.red,
                              l10n.rejected,
                              _rejected),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── BAR CHART ─────────────────────────
              Text(
                l10n.monthlyIssues,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color:
                  AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),
              Container(
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
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment
                          .spaceAround,
                      maxY: (_monthlyIssues.values
                          .isEmpty
                          ? 1
                          : _monthlyIssues
                          .values
                          .reduce((a, b) =>
                      a > b ? a : b))
                          .toDouble() +
                          2,
                      barTouchData:
                      BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            getTitlesWidget:
                                (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: AppTheme
                                    .textSecondaryColor(
                                    context),
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget:
                                (value, meta) {
                              final keys =
                              _monthlyIssues.keys
                                  .toList();
                              final idx =
                              value.toInt();
                              if (idx < 0 ||
                                  idx >= keys.length) {
                                return const SizedBox();
                              }
                              return Padding(
                                padding:
                                const EdgeInsets.only(
                                    top: 6),
                                child: Text(
                                  keys[idx]
                                      .split(' ')[0],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme
                                        .textSecondaryColor(
                                        context),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: false),
                        ),
                      ),
                      gridData:
                      const FlGridData(show: true),
                      borderData:
                      FlBorderData(show: false),
                      barGroups: _monthlyIssues.values
                          .toList()
                          .asMap()
                          .entries
                          .map(
                            (e) => BarChartGroupData(
                          x: e.key,
                          barRods: [
                            BarChartRodData(
                              toY: e.value
                                  .toDouble(),
                              color: AppTheme.primary,
                              width: 22,
                              borderRadius:
                              BorderRadius
                                  .circular(4),
                            ),
                          ],
                        ),
                      )
                          .toList(),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── ISSUE TYPES ───────────────────────
              if (_issueTypeCount.isNotEmpty) ...[
                Text(
                  l10n.issuesByType,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppTheme.textPrimaryColor(
                        context),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor(context),
                    borderRadius:
                    BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.shadowColor(
                            context),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    children: _issueTypeCount.entries
                        .map((e) {
                      final percent = _totalIssues > 0
                          ? e.value / _totalIssues
                          : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(
                            bottom: 12),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                              children: [
                                Text(
                                  e.key,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                    FontWeight.w500,
                                    color: AppTheme
                                        .textPrimaryColor(
                                        context),
                                  ),
                                ),
                                Text(
                                  '${e.value} (${(percent * 100).toStringAsFixed(0)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme
                                        .textSecondaryColor(
                                        context),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(
                                  4),
                              child:
                              LinearProgressIndicator(
                                value: percent,
                                minHeight: 8,
                                backgroundColor: AppTheme
                                    .isDark(context)
                                    ? const Color(
                                    0xFF30363D)
                                    : const Color(
                                    0xFFE8F5E9),
                                valueColor:
                                const AlwaysStoppedAnimation(
                                  AppTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // ── GENERATE PDF ──────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: _isGeneratingPdf
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child:
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                      : const Icon(
                      Icons.picture_as_pdf),
                  label: Text(
                    _isGeneratingPdf
                        ? l10n.generating
                        : l10n.generatePDF,
                    style:
                    const TextStyle(fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    Colors.red.shade700,
                  ),
                  onPressed: _isGeneratingPdf
                      ? null
                      : _generatePDF,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String label, int value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppTheme.shadowColor(context),
              blurRadius: 6,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color:
                      AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _pieSection(
      int value, Color color, String title) {
    final percent = _totalIssues > 0
        ? (value / _totalIssues * 100)
        : 0.0;
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: '${percent.toStringAsFixed(0)}%',
      radius: 60,
      titleStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _legendItem(Color color, String label, int count) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondaryColor(context),
          ),
        ),
      ],
    );
  }
}