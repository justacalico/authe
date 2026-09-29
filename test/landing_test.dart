import 'package:authe/landing_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('LandingPage', () {
    /// Lets real async work (asset image decode) finish before asserting.
    Future<void> settleImages(WidgetTester tester) async {
      await tester.runAsync(() => Future<void>.delayed(
          const Duration(milliseconds: 100)));
      await tester.pump();
    }

    testWidgets('renders hero, demo card and downloads', (tester) async {
      setSurface(tester, 480, 1000);
      await tester.pumpWidget(const LandingPage());
      await settleImages(tester);

      expect(find.text('Authe'), findsOneWidget);
      expect(
        find.text('Open two-factor authentication\nfor every screen you own.'),
        findsOneWidget,
      );
      expect(find.text('demo@authe.app'), findsOneWidget);
      expect(find.text('Get Authe'), findsOneWidget);
      for (final platform in ['iOS', 'Android', 'macOS', 'Windows', 'Linux']) {
        expect(find.text(platform), findsOneWidget);
      }
      expect(find.text('Source on GitLab'), findsOneWidget);
      expect(find.text('GitHub mirror'), findsOneWidget);
      expect(find.text('Open source under the GNU AGPL v3'), findsOneWidget);
    });

    testWidgets('demo code ticks like a real authenticator', (tester) async {
      setSurface(tester, 480, 1000);
      await tester.pumpWidget(const LandingPage());
      await tester.pump();
      expect(
        find.textContaining(RegExp(r'^\d{3} \d{3}$')),
        findsOneWidget,
      );
      // advance past a code boundary; the widget keeps rebuilding
      await tester.pump(const Duration(seconds: 2));
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('platform rows open release downloads', (tester) async {
      final launcher = useFakeUrlLauncher();
      setSurface(tester, 480, 1000);
      await tester.pumpWidget(const LandingPage());
      await tester.pump();

      await tester.tap(find.text('Android'));
      await tester.pump();
      expect(
        launcher.urls.last,
        '${LandingPage.releasesBase}/authe-android.apk',
      );
    });

    testWidgets('ios row opens the altstore source link', (tester) async {
      final launcher = useFakeUrlLauncher();
      setSurface(tester, 480, 1000);
      await tester.pumpWidget(const LandingPage());
      await tester.pump();

      await tester.tap(find.text('iOS'));
      await tester.pump();
      expect(launcher.urls.last, LandingPage.altstoreUrl);
    });

    testWidgets('footer links open source and mirror', (tester) async {
      final launcher = useFakeUrlLauncher();
      setSurface(tester, 480, 1000);
      await tester.pumpWidget(const LandingPage());
      await tester.pump();

      await tester.tap(find.text('Source on GitLab'));
      await tester.pump();
      expect(launcher.urls.last, LandingPage.sourceUrl);
      await tester.tap(find.text('GitHub mirror'));
      await tester.pump();
      expect(launcher.urls.last, LandingPage.mirrorUrl);
    });
  });
}
