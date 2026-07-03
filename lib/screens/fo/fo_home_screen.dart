import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/app_theme.dart';
import '../../widgets/app_card.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/section_header.dart';
import 'fo_tasks_screen.dart';
import '../user/update_profile_screen.dart';

class FOHomeScreen extends StatefulWidget {
  const FOHomeScreen({super.key});

  @override
  State<FOHomeScreen> createState() => _FOHomeScreenState();
}

class _FOHomeScreenState extends State<FOHomeScreen> {
  int _currentIndex = 0;
  String _foName = '';
  Map<String, int> _taskStats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final tasksSnap = await FirebaseFirestore.instance
        .collection('issues')
        .where('assignedTo', isEqualTo: uid)
        .get();

    int assigned = 0, accepted = 0, inProgress = 0, completed = 0;
    for (final d in tasksSnap.docs) {
      final s = d['taskStatus'] ?? 'assigned';
      if (s == 'assigned') assigned++;
      else if (s == 'accepted') accepted++;
      else if (s == 'in_progress') inProgress++;
      else if (s == 'completed') completed++;
    }

    if (mounted) {
      setState(() {
        _foName = userDoc.data()?['name'] ?? 'Officer';
        _taskStats = {
          'total': tasksSnap.docs.length,
          'assigned': assigned,
          'inProgress': inProgress,
          'completed': completed,
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _FOHomeTab(
            foName: _foName,
            taskStats: _taskStats,
            onRefresh: _loadData,
            onTasksTap: () => setState(() => _currentIndex = 1),
          ),
          const FOTasksScreen(),
          const UpdateProfileScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          backgroundColor: AppTheme.surface,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'My Tasks',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _FOHomeTab extends StatelessWidget {
  final String foName;
  final Map<String, int> taskStats;
  final VoidCallback onRefresh;
  final VoidCallback onTasksTap;

  const _FOHomeTab({
    required this.foName,
    required this.taskStats,
    required this.onRefresh,
    required this.onTasksTap,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${foName.split(' ').first} 👷',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const Text(
              'Field Officer Portal',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          const NotificationBell(),
          IconButton(
            icon: const Icon(Icons.logout_outlined,
                color: AppTheme.textSecondary),
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
              // ── HERO ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius:
                  BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your tasks\nfor today',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: onTasksTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMd),
                              ),
                              child: const Text(
                                'View Tasks →',
                                style: TextStyle(
                                  color: Color(0xFF7C3AED),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.engineering,
                      color: Colors.white24,
                      size: 72,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── TASK STATS ────────────────────────────
              const SectionHeader(title: 'Task Overview'),
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _FOStatCard(
                      value: (taskStats['total'] ?? 0).toString(),
                      label: 'Total',
                      color: AppTheme.info,
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FOStatCard(
                      value: (taskStats['assigned'] ?? 0).toString(),
                      label: 'New',
                      color: AppTheme.warning,
                      icon: Icons.new_releases_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FOStatCard(
                      value: (taskStats['completed'] ?? 0).toString(),
                      label: 'Done',
                      color: AppTheme.primary,
                      icon: Icons.task_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── PENDING TASKS ─────────────────────────
              SectionHeader(
                title: 'Pending Tasks',
                actionLabel: 'See all',
                onAction: onTasksTap,
              ),
              const SizedBox(height: AppTheme.spaceMd),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('issues')
                    .where('assignedTo', isEqualTo: uid)
                    .where('taskStatus', isEqualTo: 'assigned')
                    .orderBy('assignedAt', descending: true)
                    .limit(3)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return AppCard(
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No pending tasks 🎉',
                            style: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: onTasksTap,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusSm),
                                ),
                                child: const Icon(
                                  Icons.assignment_outlined,
                                  color: AppTheme.warning,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['title'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      data['issueType'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right,
                                  color: AppTheme.textSecondary,
                                  size: 20),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FOStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _FOStatCard({
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.border),
        boxShadow: AppTheme.cardShadow,
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
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}