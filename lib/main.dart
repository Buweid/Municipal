import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '/screens/constants/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Load settings before app starts
  final settings = SettingsProvider();
  await settings.loadSettings();

  runApp(
    ChangeNotifierProvider.value(
      value: settings,
      child: const MunicipalApp(),
    ),
  );
}

class MunicipalApp extends StatelessWidget {
  const MunicipalApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Muscat Municipality',
      debugShowCheckedModeBanner: false,

      // ── THEME ─────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,

      // ── LOCALIZATION ───────────────────────────────────
      locale: settings.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // ── ROUTES ────────────────────────────────────────
      home: const AuthScreen(),
      routes: {
        '/': (context) => const AuthScreen(),
      },
    );
  }
}