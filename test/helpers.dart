import 'dart:async';

import 'package:authe/account.dart';
import 'package:authe/account_store.dart';
import 'package:authe/app_state.dart';
import 'package:authe/totp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Fixed instant used by every test so generated codes are deterministic.
/// Epoch second 10 lands inside HOTP counter 0 with 20s remaining.
final DateTime kTestTime =
    DateTime.fromMillisecondsSinceEpoch(10 * 1000, isUtc: true);

/// Base32 form of the RFC 4226 seed "12345678901234567890".
const kRfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';

OtpAccount testAccount({
  String id = 'a1',
  String issuer = 'GitHub',
  String accountName = 'you@example.com',
  String secret = kRfcSecret,
  int digits = 6,
  int period = 30,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) =>
    OtpAccount(
      id: id,
      issuer: issuer,
      accountName: accountName,
      secret: secret,
      digits: digits,
      period: period,
      algorithm: algorithm,
    );

/// AppState backed by an in-memory store with a fixed clock.
AppState testState({AccountStore? store, DateTime Function()? clock}) =>
    AppState(
      store: store ?? MemoryAccountStore(),
      clock: clock ?? () => kTestTime,
    );

/// Store preloaded with accounts; mirrors what the app writes on disk.
Future<MemoryAccountStore> seededStore(List<OtpAccount> accounts,
    {String? theme}) async {
  final store = MemoryAccountStore();
  await store.write('accounts.v1', OtpAccount.encodeList(accounts));
  if (theme != null) await store.write('theme.v1', theme);
  return store;
}

/// AccountStore whose reads never complete, for the loading state.
/// Uses an unresolved completer so no pending timer leaks into the test.
class HangingAccountStore implements AccountStore {
  final _pending = Completer<String?>();

  @override
  Future<String?> read(String key) => _pending.future;

  @override
  Future<void> write(String key, String value) async {}
}

/// Sets the test surface size in logical pixels.
void setSurface(WidgetTester tester, double width, double height) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// url_launcher platform fake that records opened URLs.
class FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> urls = <String>[];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    urls.add(url);
    return true;
  }

  @override
  Future<bool> canLaunch(String url) async => true;
}

/// Installs [FakeUrlLauncher] for the duration of the test.
FakeUrlLauncher useFakeUrlLauncher() {
  final original = UrlLauncherPlatform.instance;
  final fake = FakeUrlLauncher();
  UrlLauncherPlatform.instance = fake;
  addTearDown(() => UrlLauncherPlatform.instance = original);
  return fake;
}

/// Pumps a widget tree containing a route that pushes [page] and captures
/// the value it pops with.
Future<T?> pushAndCapture<T>(
  WidgetTester tester,
  Widget page,
  Future<void> Function() drive,
) async {
  T? result;
  setSurface(tester, 900, 1200);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              result = await Navigator.of(context).push<T>(
                MaterialPageRoute(builder: (_) => page),
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  await drive();
  await tester.pumpAndSettle();
  return result;
}
