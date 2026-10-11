import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../add_fo_screen.dart';
import '../constants/app_theme.dart';
import '../shared/chatbot_screen.dart';
import 'manage_issue_types_screen.dart';
import 'manage_users_screen.dart';
import 'issue_management_screen.dart';
import '../../widgets/notification_bell.dart';
import 'analytics_screen.dart';
import 'issues_map_screen.dart';
import 'audit_log_screen.dart';
import 'feedback_screen.dart';
import 'broadcast_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  Future<Map<String, int>> _fetchStats() async {
    final issues = await FirebaseFirestore.instance
        .collection('issues')
        .get();
    final users = await FirebaseFirestore.instance
        .collection('users')
        .get();

    int pending = 0, approved = 0, inProgress = 0,
        resolved = 0, rejected = 0, citizens = 0, officers = 0;

    for (final doc in issues.docs) {
      final status = doc.data()['status'] ?? 'pending';
      if (status == 'pending') pending++;
      else if (status == 'approved') approved++;
      else if (status == 'in_progress') inProgress++;
      else if (status == 'resolved') resolved++;
      else if (status == 'rejected') rejected++;
    }

    for (final doc in users.docs) {
      final role = doc.data()['role'] ?? 'user';
      if (role == 'user') citizens++;
      else if (role == 'fo') officers++;
    }

    return {
      'total': issues.docs.length,
      'pending': pending,
      'approved': approved,
      'inProgress': inProgress,
      'resolved': resolved,
      'rejected': rejected,
      'citizens': citizens,
      'officers': officers,
    };
  }

  // Adds rating/resolution-rate figures on top of _fetchStats without
  // touching that method's contract.
  Future<Map<String, dynamic>> _fetchDashboardData() async {
    final stats = await _fetchStats();

    final issues = await FirebaseFirestore.instance
        .collection('issues')
        .get();
    int totalRating = 0, ratedCount = 0;
    for (final doc in issues.docs) {
      final rating = doc.data()['rating'];
      if (rating != null) {
        totalRating += (rating as num).toInt();
        ratedCount++;
      }
    }

    final total = stats['total'] ?? 0;
    final resolved = stats['resolved'] ?? 0;

    return <String, dynamic>{
      ...stats,
      'avgRating': ratedCount > 0 ? totalRating / ratedCount : 0.0,
      'resolutionRate': total > 0 ? resolved / total : 0.0,
    };
  }

  int _i(Map<String, dynamic> stats, String key) =>
      (stats[key] as int?) ?? 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArabic = context.watch<SettingsProvider>().isArabic;
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        toolbarHeight: 64,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.adminDashboard),
            if (email.isNotEmpty)
              Text(
                email,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
          ],
        ),
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => (context as Element).markNeedsBuild(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── A: WELCOME BANNER ─────────────────────────
              _welcomeBanner(context, l10n, isArabic),
              const SizedBox(height: 24),

              // ── B/C/D: STATS ───────────────────────────────
              Text(l10n.overview, style: _sectionTitle(context)),
              const SizedBox(height: 12),
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchDashboardData(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final stats = snapshot.data ?? <String, dynamic>{};

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _statsRow(context, l10n, stats),
                      const SizedBox(height: 24),
                      _secondaryStatsRow(context, l10n, stats),
                      const SizedBox(height: 24),
                      _performanceCard(context, l10n, stats),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // ── E: QUICK ACTIONS ───────────────────────────
              Text(l10n.quickActions, style: _sectionTitle(context)),
              const SizedBox(height: 12),
              _quickActionsGrid(context, l10n, isArabic),
              const SizedBox(height: 24),

              // ── F: RECENT ACTIVITY ─────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.recentActivity,
                      style: _sectionTitle(context)),
                  TextButton(
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const AuditLogScreen())),
                    child: Text(l10n.viewAll),
                  ),
                ],
              ),
              _recentActivity(context, l10n, isArabic),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _sectionTitle(BuildContext context) => TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 16,
    color: AppTheme.textPrimaryColor(context),
  );

  BoxDecoration _cardDecoration(BuildContext context) => BoxDecoration(
    color: AppTheme.cardColor(context),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppTheme.borderColor(context)),
    boxShadow: [
      BoxShadow(
        color: AppTheme.shadowColor(context),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ],
  );

  String _formatDate(DateTime date, bool isArabic) {
    const monthsEn = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const monthsAr = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
    ];
    if (isArabic) {
      return '${date.day} ${monthsAr[date.month - 1]} ${date.year}';
    }
    return '${monthsEn[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _timeAgo(DateTime date, bool isArabic) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'Just now';
    if (diff.inMinutes < 60) {
      return isArabic ? 'قبل ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'قبل ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return isArabic ? 'قبل ${diff.inDays} يوم' : '${diff.inDays}d ago';
    }
    return '${date.day}/${date.month}/${date.year}';
  }

  // ── SECTION A ────────────────────────────────────────────────────
  Widget _welcomeBanner(
      BuildContext context, AppLocalizations l10n, bool isArabic) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, AppTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.welcomeAdmin,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.municipalitySystem,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.white, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        _formatDate(DateTime.now(), isArabic),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.admin_panel_settings,
              color: Colors.white.withOpacity(0.25), size: 64),
        ],
      ),
    );
  }

  // ── SECTION B ────────────────────────────────────────────────────
  Widget _statsRow(
      BuildContext context, AppLocalizations l10n, Map<String, dynamic> stats) {
    final cards = [
      (l10n.totalIssues, _i(stats, 'total'), Icons.report_outlined,
      Colors.blueGrey),
      (l10n.pending, _i(stats, 'pending'), Icons.hourglass_empty,
      Colors.orange),
      (l10n.inProgress, _i(stats, 'inProgress'), Icons.engineering,
      Colors.purple),
      (l10n.resolved, _i(stats, 'resolved'), Icons.task_alt,
      AppTheme.primary),
    ];

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final (label, value, icon, color) = cards[i];
          return _statCard(context, label, value, icon, color);
        },
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int value,
      IconData icon, Color color) {
    return Container(
      width: 136,
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION C ────────────────────────────────────────────────────
  Widget _secondaryStatsRow(
      BuildContext context, AppLocalizations l10n, Map<String, dynamic> stats) {
    final citizens = _i(stats, 'citizens');
    final officers = _i(stats, 'officers');
    final totalUsers = citizens + officers;

    return Row(
      children: [
        Expanded(
          child: _wideStatCard(context, l10n.citizens, citizens,
              totalUsers, Icons.people_outline, Colors.teal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _wideStatCard(context, l10n.fieldOfficers, officers,
              totalUsers, Icons.engineering_outlined, AppTheme.purple),
        ),
      ],
    );
  }

  Widget _wideStatCard(BuildContext context, String label, int value,
      int total, IconData icon, Color color) {
    final pct = total > 0 ? value / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
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
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.textSecondaryColor(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${(pct * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── SECTION D ────────────────────────────────────────────────────
  Widget _performanceCard(
      BuildContext context, AppLocalizations l10n, Map<String, dynamic> stats) {
    final avgRating = (stats['avgRating'] as double?) ?? 0.0;
    final resolutionRate = (stats['resolutionRate'] as double?) ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: _cardDecoration(context),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '${avgRating.toStringAsFixed(1)} / 5.0',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.avgRating,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            VerticalDivider(
                color: AppTheme.borderColor(context),
                thickness: 1,
                width: 32),
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: resolutionRate,
                          strokeWidth: 4,
                          backgroundColor:
                          AppTheme.primary.withOpacity(0.1),
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary),
                        ),
                        Text(
                          '${(resolutionRate * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.resolutionRate,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondaryColor(context),
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

  // ── SECTION E ────────────────────────────────────────────────────
  List<_QuickAction> _quickActions(
      BuildContext context, AppLocalizations l10n, bool isArabic) {
    return [
      _QuickAction(
        icon: Icons.report_outlined,
        color: Colors.blue,
        title: l10n.manageIssues,
        subtitle: isArabic
            ? 'عرض البلاغات والموافقة عليها وتعيينها'
            : 'View, approve, reject and assign issues',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const IssueManagementScreen())),
      ),
      _QuickAction(
        icon: Icons.people_outline,
        color: Colors.teal,
        title: l10n.manageUsers,
        subtitle: isArabic
            ? 'عرض وتحديث حسابات المواطنين'
            : 'View and update citizen accounts',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const ManageUsersScreen())),
      ),
      _QuickAction(
        icon: Icons.person_add_outlined,
        color: const Color(0xFF6A1B9A),
        title: l10n.addFieldOfficer,
        subtitle: isArabic
            ? 'تسجيل حساب ضابط ميدان جديد'
            : 'Register a new field officer account',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddFOScreen())),
      ),
      _QuickAction(
        icon: Icons.category_outlined,
        color: Colors.orange,
        title: l10n.manageIssueTypes,
        subtitle: isArabic
            ? 'إضافة أو حذف فئات البلاغات'
            : 'Add or delete issue categories',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(
                builder: (_) => const ManageIssueTypesScreen())),
      ),
      _QuickAction(
        icon: Icons.map_outlined,
        color: Colors.teal,
        title: l10n.issuesMap,
        subtitle: isArabic
            ? 'عرض البلاغات على الخريطة'
            : 'View issues on map and heat map',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const IssuesMapScreen())),
      ),
      _QuickAction(
        icon: Icons.bar_chart,
        color: Colors.red,
        title: l10n.analyticsReports,
        subtitle: isArabic
            ? 'عرض الإحصائيات وإنشاء تقارير PDF'
            : 'View stats and generate PDF reports',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
      ),
      _QuickAction(
        icon: Icons.history,
        color: Colors.indigo,
        title: l10n.activityLog,
        subtitle: isArabic
            ? 'عرض جميع إجراءات النظام'
            : 'View all system actions and audit trail',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AuditLogScreen())),
      ),
      _QuickAction(
        icon: Icons.star_outline,
        color: Colors.amber,
        title: l10n.feedbackRatings,
        subtitle: isArabic
            ? 'عرض تقييمات المواطنين والرد عليها'
            : 'View citizen ratings and respond to feedback',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const FeedbackScreen())),
      ),
      _QuickAction(
        icon: Icons.campaign_outlined,
        color: const Color(0xFF2E7D32),
        title: l10n.broadcastNotifications,
        subtitle: isArabic
            ? 'إرسال رسائل للمواطنين أو ضباط الميدان'
            : 'Send messages to citizens or field officers',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BroadcastScreen())),
      ),
      _QuickAction(
        icon: Icons.smart_toy_outlined,
        color: AppTheme.primary,
        title: l10n.aiAssistant,
        subtitle: isArabic
            ? 'احصل على مساعدة وإجابات فورية'
            : 'Get help and answers instantly',
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ChatbotScreen())),
      ),
    ];
  }

  Widget _quickActionsGrid(
      BuildContext context, AppLocalizations l10n, bool isArabic) {
    final actions = _quickActions(context, l10n, isArabic);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 160,
      ),
      itemBuilder: (context, i) =>
          _quickActionTile(context, actions[i]),
    );
  }

  Widget _quickActionTile(BuildContext context, _QuickAction action) {
    return Container(
      decoration: _cardDecoration(context),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: action.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(action.icon,
                          color: action.color, size: 20),
                    ),
                    Icon(Icons.chevron_right,
                        size: 18,
                        color: AppTheme.textSecondaryColor(context)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  action.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  action.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── SECTION F ────────────────────────────────────────────────────
  (IconData, Color) _activityIcon(String action) {
    switch (action) {
      case 'LOGIN':
        return (Icons.login, Colors.teal);
      case 'ISSUE_SUBMITTED':
        return (Icons.report_outlined, Colors.blue);
      case 'ISSUE_APPROVED':
        return (Icons.check_circle_outline, AppTheme.primary);
      case 'ISSUE_REJECTED':
        return (Icons.cancel_outlined, Colors.red);
      case 'TASK_ASSIGNED':
        return (Icons.assignment, Colors.purple);
      case 'TASK_ACCEPTED':
        return (Icons.assignment_turned_in, Colors.blue);
      case 'TASK_REJECTED':
        return (Icons.assignment_late, Colors.red);
      case 'PROGRESS_UPDATED':
        return (Icons.update, Colors.orange);
      case 'EVIDENCE_UPLOADED':
        return (Icons.camera_alt_outlined, Colors.indigo);
      case 'STATUS_UPDATED':
        return (Icons.swap_horiz, Colors.orange);
      case 'FO_CREATED':
        return (Icons.person_add_outlined, const Color(0xFF6A1B9A));
      case 'BROADCAST_SENT':
        return (Icons.campaign_outlined, AppTheme.primary);
      default:
        return (Icons.info_outline, Colors.grey);
    }
  }

  Widget _recentActivity(
      BuildContext context, AppLocalizations l10n, bool isArabic) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('audit_logs')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Container(
          decoration: _cardDecoration(context),
          child: docs.isEmpty
              ? Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n.noActivityYet,
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
            ),
          )
              : Column(
            children: [
              for (int i = 0; i < docs.length; i++) ...[
                _activityTile(
                    context,
                    docs[i].data() as Map<String, dynamic>,
                    isArabic),
                if (i != docs.length - 1)
                  Divider(
                    height: 1,
                    indent: 56,
                    color: AppTheme.borderColor(context),
                  ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _activityTile(
      BuildContext context, Map<String, dynamic> data, bool isArabic) {
    final action = data['action'] ?? '';
    final (icon, color) = _activityIcon(action);
    final createdAt = data['createdAt'] != null
        ? (data['createdAt'] as dynamic).toDate() as DateTime
        : DateTime.now();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeAgo(createdAt, isArabic),
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
