import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../constants/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'issue_management_screen.dart';
import 'manage_users_screen.dart';
import 'analytics_screen.dart';
import '../user/update_profile_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdminDashboardScreen(key: PageStorageKey('dashboard')),
          IssueManagementScreen(key: PageStorageKey('issues')),
          ManageUsersScreen(key: PageStorageKey('users')),
          AnalyticsScreen(key: PageStorageKey('analytics')),
          // ← 4 screens, settings is pushed as route
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          border: Border(
              top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: BottomNavigationBar(
          // ← clamp index to 0-3 so it never goes out of range
          currentIndex: _currentIndex.clamp(0, 3),
          onTap: (i) {
            if (i == 4) {
              // Settings → push as route
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const UpdateProfileScreen()),
              );
              return;
            }
            setState(() => _currentIndex = i);
          },
          backgroundColor: AppTheme.cardColor(context),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.dashboard_outlined),
              activeIcon: const Icon(Icons.dashboard),
              label: l10n.adminDashboard,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.report_outlined),
              activeIcon: const Icon(Icons.report),
              label: l10n.manageIssues,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: l10n.manageUsers,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bar_chart_outlined),
              activeIcon: const Icon(Icons.bar_chart),
              label: l10n.analyticsReports,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.settings_outlined),
              activeIcon: const Icon(Icons.settings),
              label: l10n.settings,
            ),
          ],
        ),
      ),
    );
  }
}