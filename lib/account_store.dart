import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Minimal key-value interface the app state persists through. Keeps the
/// concrete storage mechanism swappable for tests.
abstract class AccountStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// Persists entries through the platform secure enclave (Keychain on
/// iOS/macOS, Keystore on Android, libsecret on Linux, DPAPI on Windows).
class SecureAccountStore implements AccountStore {
  SecureAccountStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}

/// Volatile in-memory store used in tests.
class MemoryAccountStore implements AccountStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }
}
