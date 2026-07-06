import 'package:flutter/material.dart';
import '/screens/constants/app_theme.dart';
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          AdminDashboardScreen(),
          IssueManagementScreen(),
          ManageUsersScreen(),
          AnalyticsScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration:  BoxDecoration(
          color: AppTheme.cardColor(context),
          border: Border(top: BorderSide(color: AppTheme.borderColor(context))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 4) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UpdateProfileScreen()),
              );
              return;
            }
            setState(() => _currentIndex = i);
          },
          backgroundColor: AppTheme.cardColor(context),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.report_outlined),
              activeIcon: Icon(Icons.report),
              label: 'Issues',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Users',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: 'Analytics',
            ),
            BottomNavigationBarItem( // ← removed duplicate const
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}