import 'package:authe/account.dart';
import 'package:authe/account_store.dart';
import 'package:authe/app.dart';
import 'package:authe/app_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<AppState> pumpAuthe(
  WidgetTester tester, {
  List<OtpAccount> accounts = const [],
  double width = 420,
  double height = 860,
  AccountStore? store,
}) async {
  final s = testState(
    store: store ?? await seededStore(accounts),
  );
  setSurface(tester, width, height);
  await tester.pumpWidget(AutheApp(state: s));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  return s;
}

void main() {
  group('compact layout', () {
    testWidgets('shows the empty state without accounts', (tester) async {
      await pumpAuthe(tester);
      expect(find.text('No accounts yet'), findsOneWidget);
      expect(find.text('Add account'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('empty state button opens the add page', (tester) async {
      await pumpAuthe(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Setup link'), findsOneWidget);
    });

    testWidgets('code turns red when five seconds remain', (tester) async {
      final expiring = DateTime.fromMillisecondsSinceEpoch(27 * 1000,
          isUtc: true);
      final store = await seededStore([testAccount()]);
      final state = testState(store: store, clock: () => expiring);
      setSurface(tester, 420, 860);
      await tester.pumpWidget(AutheApp(state: state));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      final code = tester.widget<Text>(find.text('755 224'));
      expect(code.style?.color,
          Theme.of(tester.element(find.text('755 224'))).colorScheme.error);
    });

    testWidgets('lists accounts with ticking codes', (tester) async {
      await pumpAuthe(tester, accounts: [testAccount()]);
      expect(find.text('GitHub'), findsOneWidget);
      expect(find.text('you@example.com'), findsOneWidget);
      // epoch 10 -> counter 0 -> 755224
      expect(find.text('755 224'), findsOneWidget);
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('tapping a card copies the code', (tester) async {
      await pumpAuthe(tester, accounts: [testAccount()]);
      String? clipboard;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = call.arguments['text'] as String;
        }
        return null;
      });
      await tester.tap(find.text('755 224'));
      await tester.pump();
      expect(clipboard, '755224');
      expect(find.text('Code copied'), findsOneWidget);
    });

    testWidgets('deletes an account through the menu', (tester) async {
      final store = await seededStore([testAccount(), testAccount(id: 'b2', issuer: 'GitLab')]);
      await pumpAuthe(tester, store: store);
      expect(find.text('GitHub'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.more_horiz).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pump();

      expect(find.text('GitHub'), findsNothing);
      expect(find.text('GitLab'), findsOneWidget);
    });

    testWidgets('delete can be cancelled', (tester) async {
      await pumpAuthe(tester, accounts: [testAccount()]);
      await tester.tap(find.byIcon(Icons.more_horiz));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('shows a loading spinner until the store resolves',
        (tester) async {
      await pumpAuthe(tester, store: HangingAccountStore());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('opens the add page from the FAB', (tester) async {
      await pumpAuthe(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Setup link'), findsOneWidget);
      expect(find.text('Manual entry'), findsOneWidget);
    });

    testWidgets('adds an account end to end', (tester) async {
      await pumpAuthe(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Account name'), 'me@corp.io');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Secret key'), kRfcSecret);
      tester.testTextInput.hide();
      await tester.pump();
      await tester.ensureVisible(
          find.widgetWithText(FilledButton, 'Add account'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add account'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Account added'), findsOneWidget);
      expect(find.text('755 224'), findsOneWidget);
    });
  });

  group('wide layout', () {
    testWidgets('uses a navigation rail and a card grid', (tester) async {
      await pumpAuthe(tester,
          accounts: [testAccount(), testAccount(id: 'b2', issuer: 'GitLab')],
          width: 1280,
          height: 800);
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Codes'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.text('755 224'), findsNWidgets(2));
    });

    testWidgets('rail switches to settings and back', (tester) async {
      await pumpAuthe(tester, width: 1280, height: 800);
      await tester.tap(find.text('Settings'));
      await tester.pump();
      expect(find.text('Appearance'), findsOneWidget);
      await tester.tap(find.text('Codes'));
      await tester.pump();
      expect(find.text('No accounts yet'), findsOneWidget);
    });

    testWidgets('add button opens the add page', (tester) async {
      await pumpAuthe(tester, width: 1280, height: 800);
      await tester
          .tap(find.widgetWithText(FilledButton, 'Add account').first);
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('Setup link'), findsOneWidget);
    });
  });

  group('resizing', () {
    testWidgets('layout swaps without losing state', (tester) async {
      final state = await pumpAuthe(tester,
          accounts: [testAccount()], width: 420, height: 860);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('755 224'), findsOneWidget);

      setSurface(tester, 1280, 800);
      await tester.pump();
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('755 224'), findsOneWidget);
      expect(state.accounts, hasLength(1));

      setSurface(tester, 420, 860);
      await tester.pump();
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('755 224'), findsOneWidget);
    });
  });

  group('settings', () {
    testWidgets('theme rows change the theme mode', (tester) async {
      final state = await pumpAuthe(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ListTile, 'Dark'));
      await tester.pump();
      expect(state.themeMode, ThemeMode.dark);
      final material = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(material.themeMode, ThemeMode.dark);

      await tester.tap(find.widgetWithText(ListTile, 'Light'));
      await tester.pump();
      expect(state.themeMode, ThemeMode.light);
      await tester.tap(find.widgetWithText(ListTile, 'System'));
      await tester.pump();
      expect(state.themeMode, ThemeMode.system);
    });

    testWidgets('license row opens the license page', (tester) async {
      await pumpAuthe(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text('License'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.byType(LicensePage), findsOneWidget);
    });

    testWidgets('source row opens the gitlab page', (tester) async {
      final launcher = useFakeUrlLauncher();
      await pumpAuthe(tester);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pump();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Source code'));
      await tester.pump();
      expect(launcher.urls, ['https://gitlab.com/HttpAnimations/authe']);
    });
  });

  group('form factors', () {
    testWidgets('breakpoint boundary renders compact below 720',
        (tester) async {
      await pumpAuthe(tester, width: 719, height: 800);
      expect(find.byType(NavigationRail), findsNothing);
      setSurface(tester, 720, 800);
      await tester.pump();
      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });
}
