import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_theme.dart';
import '../../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(settings.isArabic ? 'الإعدادات' : 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        children: [
          // ── APPEARANCE ────────────────────────────────
          _SectionLabel(
            label: settings.isArabic ? 'المظهر' : 'Appearance',
          ),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: isDark
                    ? Icons.dark_mode
                    : Icons.light_mode_outlined,
                iconColor: isDark ? Colors.indigo : Colors.amber,
                title: settings.isArabic ? 'الوضع الداكن' : 'Dark Mode',
                subtitle: settings.isArabic
                    ? 'تغيير مظهر التطبيق'
                    : 'Switch between light and dark',
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
          _SectionLabel(
            label: settings.isArabic ? 'اللغة' : 'Language',
          ),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _LanguageTile(
                flag: '🇬🇧',
                language: 'English',
                isSelected: settings.language == 'en',
                onTap: () => settings.setLanguage('en'),
              ),
              const Divider(height: 1, indent: 56),
              _LanguageTile(
                flag: '🇴🇲',
                language: 'العربية',
                isSelected: settings.language == 'ar',
                onTap: () => settings.setLanguage('ar'),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // ── NOTIFICATIONS ─────────────────────────────
          _SectionLabel(
            label: settings.isArabic ? 'الإشعارات' : 'Notifications',
          ),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.update_outlined,
                iconColor: AppTheme.info,
                title: settings.isArabic
                    ? 'تحديثات البلاغات'
                    : 'Issue Updates',
                subtitle: settings.isArabic
                    ? 'إشعارات عند تغيير حالة البلاغ'
                    : 'Notify when issue status changes',
                trailing: Switch.adaptive(
                  value: settings.notifIssueUpdates,
                  activeColor: AppTheme.primary,
                  onChanged: (_) => settings.toggleNotifIssueUpdates(),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.campaign_outlined,
                iconColor: AppTheme.primary,
                title: settings.isArabic
                    ? 'الإشعارات العامة'
                    : 'Broadcast Messages',
                subtitle: settings.isArabic
                    ? 'إشعارات من إدارة البلدية'
                    : 'Messages from municipality admin',
                trailing: Switch.adaptive(
                  value: settings.notifBroadcast,
                  activeColor: AppTheme.primary,
                  onChanged: (_) => settings.toggleNotifBroadcast(),
                ),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.assignment_outlined,
                iconColor: AppTheme.purple,
                title: settings.isArabic
                    ? 'إشعارات المهام'
                    : 'Task Notifications',
                subtitle: settings.isArabic
                    ? 'إشعارات عند تعيين مهمة جديدة'
                    : 'Notify when a task is assigned',
                trailing: Switch.adaptive(
                  value: settings.notifTasks,
                  activeColor: AppTheme.primary,
                  onChanged: (_) => settings.toggleNotifTasks(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceMd),

          // ── ABOUT ─────────────────────────────────────
          _SectionLabel(
            label: settings.isArabic ? 'حول التطبيق' : 'About',
          ),
          const SizedBox(height: 8),

          _SettingsCard(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                iconColor: AppTheme.textSecondary,
                title: settings.isArabic
                    ? 'الإصدار'
                    : 'App Version',
                subtitle: '1.0.0',
                trailing: const SizedBox.shrink(),
              ),
              const Divider(height: 1, indent: 56),
              _SettingsTile(
                icon: Icons.location_city_outlined,
                iconColor: AppTheme.textSecondary,
                title: settings.isArabic
                    ? 'بلدية مسقط'
                    : 'Muscat Municipality',
                subtitle: settings.isArabic
                    ? 'نظام البلاغات البلدية'
                    : 'Municipal Reporting System',
                trailing: const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceLg),

          // ── LOGOUT ────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout, color: AppTheme.error),
              label: Text(
                settings.isArabic ? 'تسجيل الخروج' : 'Sign Out',
                style: const TextStyle(color: AppTheme.error),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              },
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161B22)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: isDark
              ? const Color(0xFF30363D)
              : AppTheme.border,
        ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
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
                child: Text(flag, style: const TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                language,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle,
                  color: AppTheme.primary, size: 20)
            else
              const Icon(Icons.circle_outlined,
                  color: AppTheme.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}