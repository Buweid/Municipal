import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/main.dart' as app;
//flutter clean
//flutter pug get
//fluter upgrade
//flutter run
//flutter test integration_test/app_test.dart
//npm install -g firebase-tools
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launchApp(WidgetTester tester) async {
    app.main();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle(const Duration(seconds: 8));
  }

  group('Full App Automation Testing', () {
    testWidgets('App launches successfully', (tester) async {
      await launchApp(tester);

      expect(find.byType(MaterialApp), findsWidgets);
    });

    testWidgets('Navigate to Register Tab', (tester) async {
      await launchApp(tester);

      await tester.tap(find.text('Register').first);
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('National ID'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Register Form Validation Test', (tester) async {
      await launchApp(tester);

      await tester.tap(find.text('Register').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Register').last);
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Enter valid national ID'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Enter valid email'), findsOneWidget);
      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('Fill Register Form Test', (tester) async {
      await launchApp(tester);

      await tester.tap(find.text('Register').first);
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      final uniqueEmail =
          'test${DateTime.now().millisecondsSinceEpoch}@gmail.com';

      await tester.enterText(fields.at(0), 'Test User');
      await tester.enterText(fields.at(1), '12345678');
      await tester.enterText(fields.at(2), '91234567');
      await tester.enterText(fields.at(3), uniqueEmail);
      await tester.enterText(fields.at(4), '123456');

      await tester.pumpAndSettle();

      await tester.tap(find.text('Register').last);
      await tester.pumpAndSettle(const Duration(seconds: 15));

      expect(find.textContaining('Account created'), findsWidgets);
    });
  });
}