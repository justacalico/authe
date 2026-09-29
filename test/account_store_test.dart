import 'package:authe/account_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MemoryAccountStore', () {
    test('round trips values', () async {
      final store = MemoryAccountStore();
      expect(await store.read('k'), isNull);
      await store.write('k', 'v');
      expect(await store.read('k'), 'v');
    });
  });

  group('SecureAccountStore', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    const channel =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    final backend = <String, String>{};

    setUp(() {
      backend.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        switch (call.method) {
          case 'read':
            return backend[call.arguments['key'] as String];
          case 'write':
            backend[call.arguments['key'] as String] =
                call.arguments['value'] as String;
            return null;
          default:
            return null;
        }
      });
    });

    test('reads and writes through the platform channel', () async {
      final store = SecureAccountStore();
      expect(await store.read('k'), isNull);
      await store.write('k', 'v');
      expect(backend['k'], 'v');
      expect(await store.read('k'), 'v');
    });
  });
}
