import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/constants/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/settings_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/role_router.dart';
import 'l10n/app_localizations.dart';

// ── GLOBAL SETTINGS ───────────────────────────────────────────────────
SettingsProvider? globalSettings;

void main() async {
  WidgetsBinding widgetsBinding =
      WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Firebase.initializeApp();
  globalSettings = SettingsProvider();
  await globalSettings!.loadSettings();

  FlutterNativeSplash.remove();

  runApp(const RestartWidget());
}

// ── RESTART WIDGET ────────────────────────────────────────────────────
class RestartWidget extends StatefulWidget {
  const RestartWidget({super.key});

  static Future<void> restartApp(BuildContext context) async {
    FocusScope.of(context).unfocus();
    await globalSettings!.persistLanguage();
    final state =
    context.findAncestorStateOfType<_RestartWidgetState>();
    if (state != null && state.mounted) {
      await state.restartApp();
    }
  }

  @override
  State<RestartWidget> createState() => _RestartWidgetState();
}

class _RestartWidgetState extends State<RestartWidget> {
  Key _key = UniqueKey();
  bool _seenWelcome = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _seenWelcome =
            prefs.getBool('seen_welcome') ?? false;
      });
    }
  }

  Future<void> restartApp() async {
    await globalSettings!.loadSettings();
    final prefs = await SharedPreferences.getInstance();
    _seenWelcome = prefs.getBool('seen_welcome') ?? false;
    if (mounted) {
      setState(() => _key = UniqueKey());
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: ChangeNotifierProvider.value(
        value: globalSettings!,
        child: MunicipalApp(seenWelcome: _seenWelcome),
      ),
    );
  }
}

// ── APP ───────────────────────────────────────────────────────────────
class MunicipalApp extends StatelessWidget {
  final bool seenWelcome;
  const MunicipalApp({super.key, required this.seenWelcome});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

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
      home: _getHome(),
    );
  }

  Widget _getHome() {
    if (!seenWelcome) return const WelcomeScreen();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) return const _RoleResolverScreen();
    return const AuthScreen();
  }
}

// ── ROLE RESOLVER ─────────────────────────────────────────────────────
class _RoleResolverScreen extends StatelessWidget {
  const _RoleResolverScreen();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const AuthScreen();

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                  color: AppTheme.primary),
            ),
          );
        }

        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const AuthScreen();
        }

        final data =
        snapshot.data!.data() as Map<String, dynamic>;
        final role = data['role'] ?? 'user';

        return RoleRouter(role: role);
      },
    );
  }
}