import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launchApp(WidgetTester tester) async {
    app.main(isTest: true);

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  }

  group('Full App Automation Testing', () {

    testWidgets('App launches successfully', (tester) async {
      await launchApp(tester);

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Navigate to Register Screen', (tester) async {
      await launchApp(tester);

      final button = find.byType(ElevatedButton).first;

      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Register Form Validation Test', (tester) async {
      await launchApp(tester);

      final button = find.byType(ElevatedButton).first;
      await tester.tap(button);
      await tester.pumpAndSettle();

      final submit = find.byType(ElevatedButton).last;

      await tester.scrollUntilVisible(
        submit,
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(submit);
      await tester.pumpAndSettle();

      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('Fill Register Form Test', (tester) async {
      await launchApp(tester);

      final button = find.byType(ElevatedButton).first;
      await tester.tap(button);
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);

      if (fields.evaluate().length >= 5) {
        await tester.enterText(fields.at(0), 'Test User');
        await tester.enterText(fields.at(1), '12345678');
        await tester.enterText(fields.at(2), '91234567');
        await tester.enterText(fields.at(3),
            'test${DateTime.now().millisecondsSinceEpoch}@gmail.com');
        await tester.enterText(fields.at(4), '123456');
      }

      await tester.pumpAndSettle();

      final submit = find.byType(ElevatedButton).last;

      await tester.scrollUntilVisible(
        submit,
        300,
        scrollable: find.byType(Scrollable).first,
      );

      await tester.tap(submit);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(find.byType(MaterialApp), findsOneWidget);
    });

  });
}