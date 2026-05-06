import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_fo_screen.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Field Officer"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          )
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.engineering, size: 80, color: Color(0xFF2E7D32)),
            SizedBox(height: 16),
            Text(
              "Field Officer Portal",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("View assigned inspection tasks."),
          ],
        ),
      ),
    );
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
            ElevatedButton(
              onPressed: () {
                // Navigate to report submission form
              },
              child: const Text("Submit New Report"),
            )
          ],
        ),
      ),
    );
  }
}