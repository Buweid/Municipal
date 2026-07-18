import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_application_1/providers/settings_provider.dart';
import 'package:flutter_application_1/screens/auth_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_application_1/l10n/app_localizations.dart';
import 'package:flutter_application_1/screens/constants/app_theme.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
  });

  testWidgets('Auth screen loads correctly',
          (WidgetTester tester) async {
        await tester.binding
            .setSurfaceSize(const Size(1000, 2000));

        final settings = SettingsProvider();
        await settings.loadSettings();

        // Build AuthScreen directly — skip WelcomeScreen
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
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
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Check app name text exists
        expect(find.textContaining('MUSCAT'), findsOneWidget);

        // Check login and register tabs exist
        expect(find.text('Login'), findsOneWidget);
        expect(find.text('Register'), findsOneWidget);

        // Check login form fields are visible
        expect(find.byType(TextFormField), findsWidgets);

        // Check login button exists
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

  testWidgets('Switching to Register tab works',
          (WidgetTester tester) async {
        await tester.binding
            .setSurfaceSize(const Size(1000, 2000));

        final settings = SettingsProvider();
        await settings.loadSettings();

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
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
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap Register tab
        await tester.tap(find.text('Register'));
        await tester.pumpAndSettle();

        // Register form should have 5 fields
        expect(find.byType(TextFormField),
            findsNWidgets(5));
      });

  testWidgets('Login form validates empty fields',
          (WidgetTester tester) async {
        await tester.binding
            .setSurfaceSize(const Size(1000, 2000));

        final settings = SettingsProvider();
        await settings.loadSettings();

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
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
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Tap login button without filling anything
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();

        // Validation errors should appear
        expect(find.text('Please enter email'), findsOneWidget);
      });

  testWidgets('Welcome screen loads correctly',
          (WidgetTester tester) async {
        await tester.binding
            .setSurfaceSize(const Size(1000, 2000));

        final settings = SettingsProvider();
        await settings.loadSettings();

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: settings,
            child: MaterialApp(
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
              home: const MunicipalApp(seenWelcome: false),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Welcome screen should show language options
        expect(find.text('English'), findsOneWidget);
        expect(find.text('العربية'), findsOneWidget);
        expect(find.text('Get Started'), findsOneWidget);
      });
}