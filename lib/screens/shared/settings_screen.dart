import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/settings_provider.dart';
import '../../main.dart';
import '../constants/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor(context),
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          // ── APPEARANCE ────────────────────────────────
          _SectionLabel(label: l10n.appearance),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: isDark
                    ? Icons.dark_mode
                    : Icons.light_mode_outlined,
                iconColor:
                isDark ? Colors.indigo : Colors.amber,
                title: l10n.darkMode,
                subtitle: l10n.switchTheme,
                trailing: Switch.adaptive(
                  value: isDark,
                  activeColor: AppTheme.primary,
                  onChanged: (_) => settings.toggleDarkMode(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // ── LANGUAGE ──────────────────────────────────
          _SectionLabel(label: l10n.language),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _LanguageTile(
                flag: '🇬🇧',
                language: 'English',
                isSelected: settings.language == 'en',
                onTap: () async {
                  if (settings.language == 'en') return;
                  FocusScope.of(context).unfocus();
                  settings.setLanguage('en');
                  await Future.delayed(
                      const Duration(milliseconds: 300));
                  if (!context.mounted) return;

                  // ← DEBUG
                  final user =
                      FirebaseAuth.instance.currentUser;
                  print(
                      '🔵 Language change → en | User: ${user?.email} | UID: ${user?.uid}');

                  final rootContext =
                      Navigator.of(context, rootNavigator: true)
                          .context;
                  await RestartWidget.restartApp(rootContext);
                },
              ),
              const Divider(height: 1, indent: 56),
              _LanguageTile(
                flag: '🇴🇲',
                language: 'العربية',
                isSelected: settings.language == 'ar',
                onTap: () async {
                  if (settings.language == 'ar') return;
                  FocusScope.of(context).unfocus();
                  settings.setLanguage('ar');
                  await Future.delayed(
                      const Duration(milliseconds: 300));
                  if (!context.mounted) return;

                  // ← DEBUG
                  final user =
                      FirebaseAuth.instance.currentUser;
                  print(
                      '🔵 Language change → ar | User: ${user?.email} | UID: ${user?.uid}');

                  final rootContext =
                      Navigator.of(context, rootNavigator: true)
                          .context;
                  await RestartWidget.restartApp(rootContext);
                },
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // ── NOTIFICATIONS ─────────────────────────────
          _SectionLabel(label: l10n.language),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.update_outlined,
                iconColor: AppTheme.info,
                title: l10n.issueUpdates,
                subtitle: l10n.notifyStatusChange,
                trailing: Switch.adaptive(
                  value: settings.notifIssueUpdates,
                  activeColor: AppTheme.primary,
                  onChanged: (_) =>
                      settings.toggleNotifIssueUpdates(),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.campaign_outlined,
                iconColor: AppTheme.primary,
                title: l10n.broadcastMessages,
                subtitle: l10n.messagesFromAdmin,
                trailing: Switch.adaptive(
                  value: settings.notifBroadcast,
                  activeColor: AppTheme.primary,
                  onChanged: (_) =>
                      settings.toggleNotifBroadcast(),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.assignment_outlined,
                iconColor: AppTheme.purple,
                title: l10n.taskNotifications,
                subtitle: l10n.notifyTaskAssigned,
                trailing: Switch.adaptive(
                  value: settings.notifTasks,
                  activeColor: AppTheme.primary,
                  onChanged: (_) =>
                      settings.toggleNotifTasks(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // ── ABOUT ─────────────────────────────────────
          _SectionLabel(label: l10n.about),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppTheme.textSecondary,
                title: l10n.appVersion,
                subtitle: '1.0.0',
                trailing: const SizedBox.shrink(),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.location_city_outlined,
                iconColor: AppTheme.textSecondary,
                title: l10n.appName,
                subtitle: l10n.municipalitySystem,
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),
        ],
      ),
    );
  }
}

// ── SHARED WIDGETS ────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spaceMd, vertical: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius:
              BorderRadius.circular(AppTheme.radiusSm),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor(context),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                    AppTheme.textSecondaryColor(context),
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String flag;
  final String language;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.flag,
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceMd, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(AppTheme.radiusSm),
                color: AppTheme.primary.withOpacity(0.08),
              ),
              child: Center(
                child: Text(flag,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor(context),
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primary, size: 20)
            else
              Icon(Icons.circle_outlined,
                  color: AppTheme.textSecondaryColor(context),
                  size: 20),
          ],
        ),
      ),
    );
  }
}