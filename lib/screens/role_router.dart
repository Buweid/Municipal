import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_fo_screen.dart';
import "admin/manage_issue_types_screen.dart";
import 'admin/manage_users_screen.dart';
import 'user/submit_issue_screen.dart';
import 'admin/issue_management_screen.dart';
import 'fo/fo_tasks_screen.dart';

class RoleRouter extends StatelessWidget {
  final String role;

  const RoleRouter({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    // Determine which page to show based on the role string from Firestore
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminPage();
      case 'fo': // Field Officer
        return const FOPage();
      case 'user':
      default:
        return const UserPage();
    }
  }
}

// --- Helper for Logout ---
Future<void> _signOut(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (context.mounted) {
    Navigator.of(context).pushReplacementNamed('/'); // Assumes AuthScreen is '/'
    // Or simply use:
    // Navigator.of(context).pushAndRemoveUntil(
    //   MaterialPageRoute(builder: (context) => const AuthScreen()),
    //   (route) => false,
    // );
  }
}

// ---------------- PAGES ----------------

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.admin_panel_settings, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              "Administrator Access",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Manage municipality staff and reports here."),
            const SizedBox(height: 24), // ← breathing room
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("Add Field Officer"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddFOScreen()),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text("Manage Users"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageUsersScreen(),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.category),
              label: const Text("Manage Issue Types"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ManageIssueTypesScreen(),
                  ),
                );
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.report_outlined),
              label: const Text("Manage Issues"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const IssueManagementScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class FOPage extends StatelessWidget {
  const FOPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FOTasksScreen();
  }
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Muscat Municipality"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.report_problem, size: 80, color: Color(0xFF2E7D32)),
            const SizedBox(height: 16),
            const Text(
              "Welcome, Citizen",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Submit a report or track your requests."),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.report_problem),
              label: const Text("Submit New Report"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SubmitIssueScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}