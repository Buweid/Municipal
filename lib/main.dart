import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/constants/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/settings_provider.dart';
import 'package:flutter_application_1/screens/auth_screen.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final settings = SettingsProvider();
  await settings.loadSettings();

  runApp(
    RestartWidget(
      child: ChangeNotifierProvider.value(
        value: settings,
        child: const MunicipalApp(),
      ),
    ),
  );
}

// ── RESTART WIDGET ────────────────────────────────────────────────────
class RestartWidget extends StatefulWidget {
  final Widget child;
  const RestartWidget({super.key, required this.child});

  static void restartApp(BuildContext context) {
    FocusScope.of(context).unfocus();

    final state = context.findAncestorStateOfType<_RestartWidgetState>();
    if (state != null && state.mounted) {
      state.restartApp();
    }
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();

  void restartApp() async {
    // Reload settings from prefs before rebuilding
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    await settings.loadSettings();

    if (mounted) {
      setState(() => _key = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}

class MunicipalApp extends StatelessWidget {
  const MunicipalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Muscat Municipality',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthScreen(),
    );
  }
}