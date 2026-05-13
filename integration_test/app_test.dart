import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launchApp(WidgetTester tester) async {
    app.main(); // ← no isTest param, just call it normally
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // ─── AUTH SCREEN ───────────────────────────────────────────────

  group('Auth Screen', () {

    testWidgets('App launches and shows auth screen', (tester) async {
      await launchApp(tester);

      expect(find.byKey(const Key('app_title')), findsOneWidget);
      expect(find.byKey(const Key('login_tab')), findsOneWidget);
      expect(find.byKey(const Key('register_tab')), findsOneWidget);
    });

    testWidgets('Login tab is selected by default', (tester) async {
      await launchApp(tester);

      expect(find.byKey(const Key('login_form')), findsOneWidget);
      expect(find.byKey(const Key('register_form')), findsNothing);
    });

    testWidgets('Tapping Register tab shows register form', (tester) async {
      await launchApp(tester);

      await tester.tap(find.byKey(const Key('register_tab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('register_form')), findsOneWidget);
      expect(find.byKey(const Key('login_form')), findsNothing);
    });

    testWidgets('Switching tabs back to Login works', (tester) async {
      await launchApp(tester);

      await tester.tap(find.byKey(const Key('register_tab')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('login_tab')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('login_form')), findsOneWidget);
    });

  });

  // ─── LOGIN VALIDATION ──────────────────────────────────────────

  group('Login Form Validation', () {

    testWidgets('Empty login form shows errors', (tester) async {
      await launchApp(tester);

      // tap login button without filling anything
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Please enter email'), findsOneWidget);
    });

    testWidgets('Short password shows error', (tester) async {
      await launchApp(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@gmail.com');
      await tester.enterText(fields.at(1), '123'); // too short

      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

  });

  // ─── REGISTER VALIDATION ───────────────────────────────────────

  group('Register Form Validation', () {

    Future<void> goToRegister(WidgetTester tester) async {
      await launchApp(tester);
      await tester.tap(find.byKey(const Key('register_tab')));
      await tester.pumpAndSettle();
    }

    testWidgets('Empty register form shows errors', (tester) async {
      await goToRegister(tester);

      // scroll to and tap Register button
      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
    });

    testWidgets('Single word name fails validation', (tester) async {
      await goToRegister(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed'); // only 1 word

      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Enter at least 2 names'), findsOneWidget);
    });

    testWidgets('Numbers in name fails validation', (tester) async {
      await goToRegister(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed 123');

      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Name must contain letters only'), findsOneWidget);
    });

    testWidgets('Short national ID fails validation', (tester) async {
      await goToRegister(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed Ali');
      await tester.enterText(fields.at(1), '1234'); // less than 8 digits

      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('National ID must be 8 to 12 digits'), findsOneWidget);
    });

    testWidgets('Phone not starting with 7 or 9 fails', (tester) async {
      await goToRegister(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed Ali');
      await tester.enterText(fields.at(1), '12345678');
      await tester.enterText(fields.at(2), '81234567'); // starts with 8

      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Must start with 7 or 9 and be 8 digits'), findsOneWidget);
    });

    testWidgets('Invalid email fails validation', (tester) async {
      await goToRegister(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed Ali');
      await tester.enterText(fields.at(1), '12345678');
      await tester.enterText(fields.at(2), '91234567');
      await tester.enterText(fields.at(3), 'notanemail'); // no @

      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Password over 15 chars fails validation', (tester) async {
      await goToRegister(tester);

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed Ali');
      await tester.enterText(fields.at(1), '12345678');
      await tester.enterText(fields.at(2), '91234567');
      await tester.enterText(fields.at(3), 'test@gmail.com');
      await tester.enterText(fields.at(4), '1234567890123456'); // 16 chars

      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.text('Password cannot exceed 15 characters'), findsOneWidget);
    });

  });

}