import 'package:authe/account.dart';
import 'package:authe/app.dart';
import 'package:authe/landing_page.dart';
import 'package:authe/theme.dart';
import 'package:authe/ui/add_account_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

Future<void> pumpGoldenApp(
  WidgetTester tester, {
  required double width,
  required double height,
  ThemeMode mode = ThemeMode.light,
  List<OtpAccount> accounts = const [],
}) async {
  final state = testState(store: await seededStore(accounts));
  await state.setThemeMode(mode);
  setSurface(tester, width, height);
  await tester.pumpWidget(AutheApp(state: state));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

void main() {
  group('goldens', () {
    testWidgets('compact home with accounts - light', (tester) async {
      await pumpGoldenApp(
        tester,
        width: 420,
        height: 860,
        accounts: [
          testAccount(),
          testAccount(id: 'b2', issuer: 'GitLab', accountName: 'ops@corp.io'),
        ],
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_compact_light.png'),
      );
    });

    testWidgets('compact home with accounts - dark', (tester) async {
      await pumpGoldenApp(
        tester,
        width: 420,
        height: 860,
        mode: ThemeMode.dark,
        accounts: [
          testAccount(),
          testAccount(id: 'b2', issuer: 'GitLab', accountName: 'ops@corp.io'),
        ],
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_compact_dark.png'),
      );
    });

    testWidgets('wide home with accounts', (tester) async {
      await pumpGoldenApp(
        tester,
        width: 1280,
        height: 800,
        accounts: [
          testAccount(),
          testAccount(id: 'b2', issuer: 'GitLab', accountName: 'ops@corp.io'),
          testAccount(
              id: 'c3', issuer: 'Authe', accountName: 'demo@authe.app'),
        ],
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_wide.png'),
      );
    });

    testWidgets('empty state', (tester) async {
      await pumpGoldenApp(tester, width: 420, height: 860);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/home_empty.png'),
      );
    });

    testWidgets('add account page', (tester) async {
      setSurface(tester, 420, 860);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildLightTheme(),
          home: const AddAccountPage(showScan: true),
        ),
      );
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/add_account.png'),
      );
    });

    testWidgets('landing page', (tester) async {
      setSurface(tester, 480, 1100);
      await tester.pumpWidget(LandingPage(clock: () => kTestTime));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/landing.png'),
      );
    });
  });
}
