import 'package:authe/account.dart';
import 'package:authe/totp.dart';
import 'package:authe/ui/add_account_page.dart';
import 'package:authe/ui/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('AddAccountPage', () {
    testWidgets('adds from a pasted otpauth link', (tester) async {
      final result = await pushAndCapture<OtpAccount>(
        tester,
        const AddAccountPage(showScan: false),
        () async {
          await tester.enterText(
            find.byWidgetPredicate(
              (w) => w is TextField && (w.decoration?.hintText ?? '')
                  .contains('otpauth://'),
            ),
            'otpauth://totp/GitHub:me%40x.co?secret=$kRfcSecret&issuer=GitHub',
          );
          await tester.tap(find.text('Add from link'));
        },
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'GitHub');
      expect(result.accountName, 'me@x.co');
    });

    testWidgets('keyboard submit adds from the link', (tester) async {
      final result = await pushAndCapture<OtpAccount>(
        tester,
        const AddAccountPage(showScan: false),
        () async {
          await tester.enterText(
            find.byWidgetPredicate(
              (w) => w is TextField && (w.decoration?.hintText ?? '')
                  .contains('otpauth://'),
            ),
            'otpauth://totp/Kbd:k@x.co?secret=$kRfcSecret',
          );
          await tester.testTextInput.receiveAction(TextInputAction.done);
        },
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'Kbd');
    });

    testWidgets('shows an inline error for a bad link', (tester) async {
      final result = await pushAndCapture<OtpAccount>(
        tester,
        const AddAccountPage(showScan: false),
        () async {
          await tester.enterText(
            find.byWidgetPredicate(
              (w) => w is TextField && (w.decoration?.hintText ?? '')
                  .contains('otpauth://'),
            ),
            'not a uri',
          );
          await tester.tap(find.text('Add from link'));
          await tester.pump();
        },
      );
      expect(result, isNull);
      expect(find.text('URI must start with otpauth://'), findsOneWidget);
    });

    testWidgets('manual entry validates required fields', (tester) async {
      await pushAndCapture<OtpAccount>(
        tester,
        const AddAccountPage(showScan: false),
        () async {
          await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
          await tester.pump();
          expect(find.text('Account name is required'), findsOneWidget);
          expect(find.text('Secret key is required'), findsOneWidget);

          await tester.enterText(
              find.widgetWithText(TextFormField, 'Account name'), 'me@x.co');
          await tester.enterText(
              find.widgetWithText(TextFormField, 'Secret key'), 'nope!');
          await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
          await tester.pump();
          expect(find.text('Not valid base32'), findsOneWidget);
        },
      );
    });

    testWidgets('manual entry submits a configured account', (tester) async {
      final result = await pushAndCapture<OtpAccount>(
        tester,
        const AddAccountPage(showScan: false),
        () async {
          await tester.enterText(
              find.widgetWithText(TextFormField, 'Issuer'), 'GitLab');
          await tester.enterText(
              find.widgetWithText(TextFormField, 'Account name'), 'me@x.co');
          await tester.enterText(
              find.widgetWithText(TextFormField, 'Secret key'), kRfcSecret);
          tester.testTextInput.hide();
          await tester.pump();

          await tester.tap(find.widgetWithText(DropdownButtonFormField<OtpAlgorithm>, 'Algorithm'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('SHA256').last);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Digits'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('8').last);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(DropdownButtonFormField<int>, 'Period (s)'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('60').last);
          await tester.pumpAndSettle();

          await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
        },
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'GitLab');
      expect(result.accountName, 'me@x.co');
      expect(result.algorithm, OtpAlgorithm.sha256);
      expect(result.digits, 8);
      expect(result.period, 60);
    });

    testWidgets('scan option returns the scanned account', (tester) async {
      final result = await pushAndCapture<OtpAccount>(
        tester,
        AddAccountPage(
          showScan: true,
          scannerBuilder: (context, onCode) => FilledButton(
            onPressed: () => onCode(
                'otpauth://totp/ScanCo:cam?secret=$kRfcSecret'),
            child: const Text('fake-scan'),
          ),
        ),
        () async {
          await tester.tap(find.text('Scan QR code'));
          await tester.pump();
          await tester.pump();
          await tester.tap(find.text('fake-scan'));
        },
      );
      expect(result, isNotNull);
      expect(result!.issuer, 'ScanCo');
      expect(result.accountName, 'cam');
    });

    testWidgets('hides the scan option when unsupported', (tester) async {
      await pushAndCapture<OtpAccount>(
        tester,
        const AddAccountPage(showScan: false),
        () async {
          expect(find.text('Scan QR code'), findsNothing);
        },
      );
    });
  });

  group('ScanPage', () {
    testWidgets('rejects a non-otpauth code and stays open', (tester) async {
      var popped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                await Navigator.of(context).push<OtpAccount>(
                  MaterialPageRoute(
                    builder: (_) => ScanPage(
                      scannerBuilder: (context, onCode) => FilledButton(
                        onPressed: () => onCode('not an otp uri'),
                        child: const Text('emit-bad'),
                      ),
                    ),
                  ),
                );
                popped = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('emit-bad'));
      await tester.pump();
      expect(find.text('Not a valid TOTP QR code'), findsOneWidget);
      expect(popped, isFalse);
    });
  });
}
