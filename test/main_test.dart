import 'package:authe/bootstrap_app.dart' as bootstrap_app;
import 'package:authe/bootstrap_stub.dart' as bootstrap_stub;
import 'package:authe/landing_page.dart';
import 'package:authe/app.dart';
import 'package:authe/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'read') return null;
      return null;
    });
  });

  testWidgets('main() boots the native app', (tester) async {
    app.main();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(AutheApp), findsOneWidget);
    expect(find.text('Authe'), findsWidgets);
    runApp(const SizedBox());
    await tester.pump();
  });

  testWidgets('bootstrap resolves to the app on dart.library.io',
      (tester) async {
    expect(bootstrap_app.buildEntry(), isA<AutheApp>());
    // The stub is compiled for web only but stays importable here.
    expect(bootstrap_stub.buildEntry(), isA<LandingPage>());
  });
}
