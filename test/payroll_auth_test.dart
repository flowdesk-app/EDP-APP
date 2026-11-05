import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:automated_dashboard/widgets/payroll_auth_dialog.dart';

void main() {
  group('PayrollAuthService Tests', () {
    setUp(() {
      PayrollAuthService.lock();
    });

    test('Initially locked', () {
      expect(PayrollAuthService.isUnlocked, isFalse);
    });

    test('Manual unlock and lock works', () {
      expect(PayrollAuthService.isUnlocked, isFalse);
      PayrollAuthService.unlock();
      expect(PayrollAuthService.isUnlocked, isTrue);
      PayrollAuthService.lock();
      expect(PayrollAuthService.isUnlocked, isFalse);
    });

    testWidgets('Password prompt rejects wrong password and accepts 1212', (tester) async {
      bool? authResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    authResult = await PayrollAuthService.ensureAuthorized(
                      context,
                      targetSection: 'Overview',
                    );
                  },
                  child: const Text('Open Overview'),
                );
              },
            ),
          ),
        ),
      );

      // Click button to open dialog
      await tester.tap(find.text('Open Overview'));
      await tester.pumpAndSettle();

      // Verify dialog is visible
      expect(find.text('Unlock Overview'), findsOneWidget);
      expect(find.text('Payroll Security Verification'), findsOneWidget);

      // Enter wrong password
      await tester.enterText(find.byType(TextField), '9999');
      await tester.tap(find.text('Unlock Payroll'));
      await tester.pumpAndSettle();

      // Verify error message and still locked
      expect(find.text('Incorrect password. Access denied.'), findsOneWidget);
      expect(PayrollAuthService.isUnlocked, isFalse);

      // Enter correct password: 1212
      await tester.enterText(find.byType(TextField), '1212');
      await tester.tap(find.text('Unlock Payroll'));
      await tester.pumpAndSettle();

      // Dialog should close and authResult is true
      expect(find.text('Unlock Overview'), findsNothing);
      expect(authResult, isTrue);
      expect(PayrollAuthService.isUnlocked, isTrue);

      // Subsequent access should return true without showing dialog
      await tester.tap(find.text('Open Overview'));
      await tester.pump();
      expect(find.text('Unlock Overview'), findsNothing);
    });

    testWidgets('Cancel button keeps section locked', (tester) async {
      bool? authResult;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () async {
                    authResult = await PayrollAuthService.ensureAuthorized(
                      context,
                      targetSection: 'Statement',
                    );
                  },
                  child: const Text('Open Statement'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Statement'));
      await tester.pumpAndSettle();

      expect(find.text('Unlock Statement'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(authResult, isFalse);
      expect(PayrollAuthService.isUnlocked, isFalse);
    });
  });
}
