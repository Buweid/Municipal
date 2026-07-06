import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import '../../widgets/app_card.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/section_header.dart';
import '../constants/app_theme.dart';
import '../shared/chatbot_screen.dart';
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
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
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.cardColor(context),
          border: Border(
            top: BorderSide(color: AppTheme.borderColor(context)),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) {
            if (i == 2) {
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
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n.home,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.assignment_outlined),
              activeIcon: const Icon(Icons.assignment),
              label: l10n.myTasks,
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
    final l10n = AppLocalizations.of(context)!;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${foName.split(' ').first} 👷',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryColor(context),
              ),
            ),
            Text(
              l10n.fieldOfficer,
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
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.yourTasksToday,
                            style: const TextStyle(
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
                              child: Text(
                                l10n.viewTasks,
                                style: const TextStyle(
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
              SectionHeader(title: l10n.taskOverview),
              const SizedBox(height: AppTheme.spaceMd),
              Row(
                children: [
                  Expanded(
                    child: _FOStatCard(
                      value: (taskStats['total'] ?? 0).toString(),
                      label: l10n.total,
                      color: AppTheme.info,
                      icon: Icons.assignment_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FOStatCard(
                      value: (taskStats['assigned'] ?? 0).toString(),
                      label: l10n.newTasks,
                      color: AppTheme.warning,
                      icon: Icons.new_releases_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FOStatCard(
                      value: (taskStats['completed'] ?? 0).toString(),
                      label: l10n.doneTasks,
                      color: AppTheme.primary,
                      icon: Icons.task_alt,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spaceLg),

              // ── PENDING TASKS ─────────────────────────
              SectionHeader(
                title: l10n.pendingTasks,
                actionLabel: l10n.seeAll,
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];

                  if (docs.isEmpty) {
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            l10n.noPendingTasks,
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: docs.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AppCard(
                          onTap: onTasksTap,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppTheme.warning.withOpacity(0.1),
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
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color:
                                        AppTheme.textPrimaryColor(context),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      data['issueType'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondaryColor(
                                            context),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: AppTheme.textSecondaryColor(context),
                                size: 20,
                              ),
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
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context),
            blurRadius: 12,
            offset: const Offset(0, 2),
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