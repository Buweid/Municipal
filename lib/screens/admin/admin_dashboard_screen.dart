import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
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
      final status = doc['status'] ?? 'pending';
      if (status == 'pending') pending++;
      else if (status == 'approved') approved++;
      else if (status == 'in_progress') inProgress++;
      else if (status == 'resolved') resolved++;
      else if (status == 'rejected') rejected++;
    }

    for (final doc in users.docs) {
      final role = doc['role'] ?? 'user';
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.adminDashboard),
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
              // ── WELCOME ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: Colors.white70, size: 32),
                    const SizedBox(height: 8),
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
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── STATS ─────────────────────────────────────
              Text(
                l10n.overview,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),

              FutureBuilder<Map<String, int>>(
                future: _fetchStats(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final stats = snapshot.data ?? {};
                  final l10n = AppLocalizations.of(context)!;

                  return Column(
                    children: [
                      Row(
                        children: [
                          _statCard(context, l10n.totalIssues,
                              stats['total'] ?? 0,
                              Icons.report_outlined, Colors.blueGrey),
                          const SizedBox(width: 12),
                          _statCard(context, l10n.pending,
                              stats['pending'] ?? 0,
                              Icons.hourglass_empty, Colors.orange),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(context, l10n.inProgress,
                              stats['inProgress'] ?? 0,
                              Icons.engineering, Colors.purple),
                          const SizedBox(width: 12),
                          _statCard(context, l10n.resolved,
                              stats['resolved'] ?? 0,
                              Icons.task_alt, const Color(0xFF2E7D32)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _statCard(context, l10n.citizens,
                              stats['citizens'] ?? 0,
                              Icons.people_outline, Colors.teal),
                          const SizedBox(width: 12),
                          _statCard(context, l10n.fieldOfficers,
                              stats['officers'] ?? 0,
                              Icons.engineering_outlined,
                              const Color(0xFF6A1B9A)),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 28),

              // ── QUICK ACTIONS ─────────────────────────────
              Text(
                l10n.quickActions,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
              const SizedBox(height: 12),

              _actionTile(context,
                  icon: Icons.report_outlined,
                  color: Colors.blue,
                  title: l10n.manageIssues,
                  subtitle: 'View, approve, reject and assign issues',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const IssueManagementScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.people_outline,
                  color: Colors.teal,
                  title: l10n.manageUsers,
                  subtitle: 'View and update citizen accounts',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ManageUsersScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.person_add_outlined,
                  color: const Color(0xFF6A1B9A),
                  title: l10n.addFieldOfficer,
                  subtitle: 'Register a new field officer account',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AddFOScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.category_outlined,
                  color: Colors.orange,
                  title: l10n.manageIssueTypes,
                  subtitle: 'Add or delete issue categories',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ManageIssueTypesScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.map_outlined,
                  color: Colors.teal,
                  title: l10n.issuesMap,
                  subtitle: 'View issues on map and heat map',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const IssuesMapScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.bar_chart,
                  color: Colors.red,
                  title: l10n.analyticsReports,
                  subtitle: 'View stats and generate PDF reports',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AnalyticsScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.history,
                  color: Colors.indigo,
                  title: l10n.activityLog,
                  subtitle: 'View all system actions and audit trail',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const AuditLogScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.star_outline,
                  color: Colors.amber,
                  title: l10n.feedbackRatings,
                  subtitle: 'View citizen ratings and respond to feedback',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const FeedbackScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.campaign_outlined,
                  color: const Color(0xFF2E7D32),
                  title: l10n.broadcastNotifications,
                  subtitle: 'Send messages to citizens or field officers',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const BroadcastScreen()))),
              const SizedBox(height: 10),
              _actionTile(context,
                  icon: Icons.smart_toy_outlined,
                  color: AppTheme.primary,
                  title: l10n.aiAssistant,
                  subtitle: 'Get help and answers instantly',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const ChatbotScreen()))),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, int value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(
      BuildContext context, {
        required IconData icon,
        required Color color,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondaryColor(context),
            ),
          ],
        ),
      ),
    );
  }
}