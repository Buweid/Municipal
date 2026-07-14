import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/section_header.dart';
import '../constants/app_theme.dart';
import '../shared/chatbot_screen.dart';
import 'submit_issue_screen.dart';
import 'my_issues_screen.dart';
import 'update_profile_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  int _currentIndex = 0;
  String _userName = '';
  Map<String, int> _issueStats = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final issuesSnap = await FirebaseFirestore.instance
        .collection('issues')
        .where('uid', isEqualTo: uid)
        .get();

    int pending = 0, inProgress = 0, resolved = 0;
    for (final d in issuesSnap.docs) {
      final status = d['status'] ?? 'pending';
      if (status == 'pending' || status == 'approved') pending++;
      else if (status == 'in_progress') inProgress++;
      else if (status == 'resolved') resolved++;
    }

    if (mounted) {
      setState(() {
        _userName = doc.data()?['name'] ?? 'Citizen';
        _issueStats = {
          'total': issuesSnap.docs.length,
          'pending': pending,
          'inProgress': inProgress,
          'resolved': resolved,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _HomeTab(
            userName: _userName,
            issueStats: _issueStats,
            onRefresh: _loadUserData,
            onSubmitTap: () => setState(() => _currentIndex = 1),
            onIssuesTap: () => setState(() => _currentIndex = 2),
          ),
          const SubmitIssueScreen(key: PageStorageKey('submit')),
          const MyIssuesScreen(key: PageStorageKey('myissues')),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
          onTap: (i) {
            if (i == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateProfileScreen()),
              );
              return;
            }
            setState(() => _currentIndex = i);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.add_circle_outline),
              activeIcon: const Icon(Icons.add_circle),
              label: l10n.submitReport,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.list_alt_outlined),
              activeIcon: const Icon(Icons.list_alt),
              label: l10n.myIssues,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n.profile,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.smart_toy_outlined, color: Colors.white),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChatbotScreen()),
        ),
      ),
    );
  }
}

// ── HOME TAB ─────────────────────────────────────────────────────────
class _HomeTab extends StatelessWidget {
  final String userName;
  final Map<String, int> issueStats;
  final VoidCallback onRefresh;
  final VoidCallback onSubmitTap;
  final VoidCallback onIssuesTap;

  const _HomeTab({
    required this.userName,
    required this.issueStats,
    required this.onRefresh,
    required this.onSubmitTap,
    required this.onIssuesTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${userName.split(' ').first} 👋',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            Text(
              l10n.appName,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondaryColor(context),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: Icon(Icons.logout_outlined,
                color: AppTheme.textSecondaryColor(context)),
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
        onRefresh: () async => onRefresh(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppTheme.spaceMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── HERO CARD ─────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.seeMoreIssues,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.reportInSeconds,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: onSubmitTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add,
                                color: AppTheme.primary, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              l10n.submitReport,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── MY STATS ──────────────────────────────
              SectionHeader(
                title: l10n.myReports,
                actionLabel: l10n.viewAll,
                onAction: onIssuesTap,
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      value: (issueStats['total'] ?? 0).toString(),
                      label: l10n.total,
                      color: AppTheme.info,
                      icon: Icons.report_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: (issueStats['pending'] ?? 0).toString(),
                      label: l10n.pending,
                      color: AppTheme.warning,
                      icon: Icons.hourglass_empty,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      value: (issueStats['resolved'] ?? 0).toString(),
                      label: l10n.resolved,
                      color: AppTheme.primary,
                      icon: Icons.task_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── QUICK ACTIONS ─────────────────────────
              SectionHeader(title: l10n.quickActions),
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.add_circle_outline,
                      label: l10n.submitReport,
                      color: AppTheme.primary,
                      onTap: onSubmitTap,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.list_alt_outlined,
                      label: l10n.myIssues,
                      color: AppTheme.info,
                      onTap: onIssuesTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── RECENT ISSUES ─────────────────────────
              SectionHeader(title: l10n.recentReports),
              const SizedBox(height: AppTheme.spaceMd),
              _RecentIssuesList(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 6,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.isDark(context)
              ? color.withOpacity(0.15)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentIssuesList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('issues')
          .where('uid', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return AppCard(
            child: Column(
              children: [
                const SizedBox(height: 12),
                Icon(
                  Icons.inbox_outlined,
                  size: 40,
                  color: AppTheme.textSecondaryColor(context).withOpacity(0.4),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.noReportsYet,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tapToSubmit,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          );
        }

        final Map<String, Color> statusColors = {
          'pending': AppTheme.warning,
          'approved': AppTheme.info,
          'in_progress': AppTheme.purple,
          'resolved': AppTheme.primary,
          'rejected': AppTheme.error,
        };

        return Column(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] ?? 'pending';
            final color = statusColors[status] ?? AppTheme.warning;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppTheme.textPrimaryColor(context),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            data['issueType'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        status.replaceAll('_', ' '),
                        style: TextStyle(
                          fontSize: 10,
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}