import 'dart:async';

import 'package:flutter/material.dart';

import 'account.dart';
import 'account_store.dart';

/// Single source of truth for the whole app. Lives above [MaterialApp] so
/// window resizes never destroy or recreate it.
class AppState extends ChangeNotifier {
  AppState({
    AccountStore? store,
    DateTime Function()? clock,
  })  : _store = store ?? SecureAccountStore(),
        _clock = clock ?? DateTime.now {
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _now = _clock();
      notifyListeners();
    });
    unawaited(load());
  }

  static const _accountsKey = 'accounts.v1';
  static const _themeKey = 'theme.v1';

  final AccountStore _store;
  final DateTime Function() _clock;
  late final Timer _ticker;

  DateTime _now = DateTime.now();
  List<OtpAccount> _accounts = const [];
  ThemeMode _themeMode = ThemeMode.system;
  bool _loaded = false;

  /// Current time as seen by the app; updates once per second.
  DateTime get now => _now;

  List<OtpAccount> get accounts => List.unmodifiable(_accounts);
  ThemeMode get themeMode => _themeMode;

  /// False until the persisted accounts have been read once.
  bool get loaded => _loaded;

  Future<void> load() async {
    final raw = await _store.read(_accountsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        _accounts = OtpAccount.decodeList(raw);
      } on FormatException {
        _accounts = const [];
      }
    }
    final theme = await _store.read(_themeKey);
    _themeMode = ThemeMode.values.asNameMap()[theme] ?? ThemeMode.system;
    _loaded = true;
    _now = _clock();
    notifyListeners();
  }

  Future<void> addAccount(OtpAccount account) async {
    _accounts = [..._accounts, account];
    await _persist();
    notifyListeners();
  }

  Future<void> removeAccount(String id) async {
    _accounts = _accounts.where((a) => a.id != id).toList();
    await _persist();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    await _store.write(_themeKey, mode.name);
    notifyListeners();
  }

  Future<void> _persist() =>
      _store.write(_accountsKey, OtpAccount.encodeList(_accounts));

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }
}
