import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_application_1/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> launchApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  // ─── AUTH SCREEN ───────────────────────────────────────────────

  group('Auth Screen', () {
    testWidgets('App launches and shows auth screen',
            (tester) async {
          await launchApp(tester);
          expect(find.byType(TextFormField), findsWidgets);
          expect(find.byType(ElevatedButton), findsOneWidget);
        });

    testWidgets('Login tab is selected by default',
            (tester) async {
          await launchApp(tester);
          // Login form has 2 fields (email + password)
          expect(find.byType(TextFormField), findsNWidgets(2));
        });

    testWidgets('Tapping Register tab shows register form',
            (tester) async {
          await launchApp(tester);
          await tester.tap(find.text('Register'));
          await tester.pumpAndSettle();
          // Register form has 5 fields
          expect(find.byType(TextFormField), findsNWidgets(5));
        });

    testWidgets('Switching tabs back to Login works',
            (tester) async {
          await launchApp(tester);
          await tester.tap(find.text('Register'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Login'));
          await tester.pumpAndSettle();
          // Back to 2 fields
          expect(find.byType(TextFormField), findsNWidgets(2));
        });
  });

  // ─── LOGIN VALIDATION ──────────────────────────────────────────

  group('Login Form Validation', () {
    testWidgets('Empty login form shows errors', (tester) async {
      await launchApp(tester);
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Please enter email'), findsOneWidget);
    });

    testWidgets('Short password shows error', (tester) async {
      await launchApp(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'test@gmail.com');
      await tester.enterText(fields.at(1), '123');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle();
      expect(find.text('Password must be at least 6 characters'),
          findsOneWidget);
    });
  });

  // ─── REGISTER VALIDATION ───────────────────────────────────────

  group('Register Form Validation', () {
    Future<void> goToRegister(WidgetTester tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Register'));
      await tester.pumpAndSettle();
    }

    testWidgets('Empty register form shows errors', (tester) async {
      await goToRegister(tester);
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
      await tester.enterText(fields.at(0), 'Ahmed');
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
      expect(
          find.text('Name must contain letters only'), findsOneWidget);
    });

    testWidgets('Short national ID fails validation', (tester) async {
      await goToRegister(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed Ali');
      await tester.enterText(fields.at(1), '1234');
      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('National ID must be 8 to 12 digits'),
          findsOneWidget);
    });

    testWidgets('Phone not starting with 7 or 9 fails',
            (tester) async {
          await goToRegister(tester);
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Ahmed Ali');
          await tester.enterText(fields.at(1), '12345678');
          await tester.enterText(fields.at(2), '81234567');
          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(
              find.text('Must start with 7 or 9 and be 8 digits'),
              findsOneWidget);
        });

    testWidgets('Invalid email fails validation', (tester) async {
      await goToRegister(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Ahmed Ali');
      await tester.enterText(fields.at(1), '12345678');
      await tester.enterText(fields.at(2), '91234567');
      await tester.enterText(fields.at(3), 'notanemail');
      final submit = find.byType(ElevatedButton).last;
      await tester.scrollUntilVisible(submit, 200,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
          find.text('Enter a valid email address'), findsOneWidget);
    });

    testWidgets('Password over 15 chars fails validation',
            (tester) async {
          await goToRegister(tester);
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Ahmed Ali');
          await tester.enterText(fields.at(1), '12345678');
          await tester.enterText(fields.at(2), '91234567');
          await tester.enterText(fields.at(3), 'test@gmail.com');
          await tester.enterText(fields.at(4), '1234567890123456');
          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();
          expect(find.text('Password cannot exceed 15 characters'),
              findsOneWidget);
        });
  });

  // ─── NEW: WELCOME SCREEN ───────────────────────────────────────



  // ─── NEW: DARK MODE ────────────────────────────────────────────

  group('Dark Mode', () {
    Future<void> goToSettings(WidgetTester tester) async {
      await launchApp(tester);
      // Go past welcome screen
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
    }

    testWidgets('Settings screen has dark mode toggle',
            (tester) async {
          await goToSettings(tester);
          // Login first
          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'admin@gmail.com');
          await tester.enterText(fields.at(1), '123456');
          await tester.tap(find.byType(ElevatedButton).first);
          await tester.pumpAndSettle(const Duration(seconds: 4));

          // Navigate to settings
          await tester.tap(find.byIcon(Icons.settings_outlined));
          await tester.pumpAndSettle();

          // Dark mode switch should exist
          expect(find.byType(Switch), findsWidgets);
          expect(find.text('Dark Mode'), findsOneWidget);
        });

    testWidgets('Dark mode toggle changes theme', (tester) async {
      await goToSettings(tester);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'admin@gmail.com');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find and tap the dark mode switch
      final darkSwitch = find.byType(Switch).first;
      await tester.tap(darkSwitch);
      await tester.pumpAndSettle();

      // App should now be in dark mode
      final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });
  });

  // ─── NEW: SUBMIT ISSUE VALIDATION ─────────────────────────────

  group('Submit Issue Validation', () {
    Future<void> goToSubmitIssue(WidgetTester tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Login as citizen
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testt@gmail.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // Tap Submit Report tab
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
    }

    testWidgets('Submit issue screen shows all fields',
            (tester) async {
          await goToSubmitIssue(tester);
          expect(find.text('Issue Title'), findsOneWidget);
          expect(find.text('Issue Type'), findsOneWidget);
          expect(find.text('Description'), findsOneWidget);
          expect(find.text('Photo Evidence'), findsOneWidget);
          expect(find.text('Issue Location'), findsOneWidget);
        });

    testWidgets('Submit with empty title shows error',
            (tester) async {
          await goToSubmitIssue(tester);

          // Scroll to and tap submit button
          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(find.text('Title is required'), findsOneWidget);
        });

    testWidgets('Submit with short title shows error',
            (tester) async {
          await goToSubmitIssue(tester);

          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Hi'); // less than 5 chars

          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(
              find.text('Title must be at least 5 characters'),
              findsOneWidget);
        });

    testWidgets('Submit with empty description shows error',
            (tester) async {
          await goToSubmitIssue(tester);

          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Valid Issue Title Here');
          // leave description empty

          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(find.text('Description is required'), findsOneWidget);
        });

    testWidgets('Submit without issue type shows snackbar',
            (tester) async {
          await goToSubmitIssue(tester);

          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Valid Issue Title Here');
          await tester.enterText(fields.at(1),
              'This is a detailed description of the issue');

          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(find.text('Select issue type'), findsOneWidget);
        });

    testWidgets('Submit without location shows snackbar',
            (tester) async {
          await goToSubmitIssue(tester);

          final fields = find.byType(TextFormField);
          await tester.enterText(fields.at(0), 'Valid Issue Title Here');
          await tester.enterText(fields.at(1),
              'This is a detailed description of the issue');

          // Select issue type from dropdown
          await tester.tap(find.byType(DropdownButtonFormField<String>));
          await tester.pumpAndSettle();
          await tester.tap(find.byType(DropdownMenuItem<String>).first);
          await tester.pumpAndSettle();

          final submit = find.byType(ElevatedButton).last;
          await tester.scrollUntilVisible(submit, 200,
              scrollable: find.byType(Scrollable).first);
          await tester.tap(submit);
          await tester.pumpAndSettle();

          expect(find.text('Tap to select location on map'),
              findsOneWidget);
        });
  });

  // ─── NEW: NAVIGATION ───────────────────────────────────────────

  group('Bottom Navigation', () {
    Future<void> loginAsCitizen(WidgetTester tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testt@gmail.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 4));
    }

    testWidgets('Citizen home shows bottom navigation',
            (tester) async {
          await loginAsCitizen(tester);
          expect(find.byType(BottomNavigationBar), findsOneWidget);
        });

    testWidgets('Citizen nav has 4 items', (tester) async {
      await loginAsCitizen(tester);
      final nav = tester.widget<BottomNavigationBar>(
          find.byType(BottomNavigationBar));
      expect(nav.items.length, equals(4));
    });

    testWidgets('Tapping Submit tab shows submit screen',
            (tester) async {
          await loginAsCitizen(tester);
          await tester.tap(find.byIcon(Icons.add_circle_outline));
          await tester.pumpAndSettle();
          expect(find.text('Issue Title'), findsOneWidget);
        });

    testWidgets('Tapping My Issues tab shows issues screen',
            (tester) async {
          await loginAsCitizen(tester);
          await tester.tap(find.byIcon(Icons.list_alt_outlined));
          await tester.pumpAndSettle();
          expect(find.byType(FilterChip), findsWidgets);
        });

    testWidgets('Tapping Home tab returns to home', (tester) async {
      await loginAsCitizen(tester);
      // Go to submit
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();
      // Go back to home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle();
      // Home should show stats
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('Tapping Profile tab pushes profile screen',
            (tester) async {
          await loginAsCitizen(tester);
          await tester.tap(find.byIcon(Icons.person_outline));
          await tester.pumpAndSettle(const Duration(seconds: 2));
          expect(find.text('Update Profile'), findsOneWidget);
        });

    testWidgets('My Issues screen has filter chips',
            (tester) async {
          await loginAsCitizen(tester);
          await tester.tap(find.byIcon(Icons.list_alt_outlined));
          await tester.pumpAndSettle();
          // Should have All, Pending, Approved etc chips
          expect(find.byType(FilterChip), findsWidgets);
          expect(find.text('All'), findsOneWidget);
        });

    testWidgets('My Issues screen has search bar', (tester) async {
      await loginAsCitizen(tester);
      await tester.tap(find.byIcon(Icons.list_alt_outlined));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.search), findsOneWidget);
    });
  });

  // ─── NEW: SETTINGS SCREEN ─────────────────────────────────────

  group('Settings Screen', () {
    Future<void> goToSettings(WidgetTester tester) async {
      await launchApp(tester);
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'testt@gmail.com');
      await tester.enterText(fields.at(1), '123456');
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pumpAndSettle(const Duration(seconds: 4));
      // Go to profile then settings
      await tester.tap(find.byIcon(Icons.person_outline));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
    }

    testWidgets('Settings screen has all sections', (tester) async {
      await goToSettings(tester);
      expect(find.text('Dark Mode'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('Settings has language options', (tester) async {
      await goToSettings(tester);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('العربية'), findsOneWidget);
    });

    testWidgets('Settings has notification toggles',
            (tester) async {
          await goToSettings(tester);
          expect(find.text('Issue Updates'), findsOneWidget);
          expect(find.text('Broadcast Messages'), findsOneWidget);
        });

    testWidgets('Settings has app version', (tester) async {
      await goToSettings(tester);
      await tester.scrollUntilVisible(
        find.text('App Version'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('1.0.0'), findsOneWidget);
    });

    testWidgets('Dark mode switch is toggleable', (tester) async {
      await goToSettings(tester);
      final switches = find.byType(Switch);
      expect(switches, findsWidgets);
      // Tap dark mode switch
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
      // Switch state should have changed
      final sw = tester.widget<Switch>(switches.first);
      expect(sw.value, isTrue);
    });
  });
}
