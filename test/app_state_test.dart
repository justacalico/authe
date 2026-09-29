import 'package:authe/account.dart';
import 'package:authe/account_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('AppState', () {
    test('loads persisted accounts and theme', () async {
      final store = await seededStore([testAccount()], theme: 'dark');
      final state = testState(store: store);
      await Future<void>.delayed(Duration.zero);
      expect(state.loaded, isTrue);
      expect(state.accounts, hasLength(1));
      expect(state.themeMode, ThemeMode.dark);
      state.dispose();
    });

    test('starts empty when nothing is stored', () async {
      final state = testState();
      await Future<void>.delayed(Duration.zero);
      expect(state.loaded, isTrue);
      expect(state.accounts, isEmpty);
      expect(state.themeMode, ThemeMode.system);
      state.dispose();
    });

    test('survives corrupt stored data', () async {
      final store = MemoryAccountStore();
      await store.write('accounts.v1', '{not json]');
      final state = testState(store: store);
      await Future<void>.delayed(Duration.zero);
      expect(state.accounts, isEmpty);
      state.dispose();
    });

    test('addAccount persists and notifies', () async {
      final store = MemoryAccountStore();
      final state = testState(store: store);
      await Future<void>.delayed(Duration.zero);
      var notified = 0;
      state.addListener(() => notified++);

      await state.addAccount(testAccount());
      expect(state.accounts, hasLength(1));
      expect(notified, greaterThan(0));
      expect(OtpAccount.decodeList((await store.read('accounts.v1'))!),
          hasLength(1));
      state.dispose();
    });

    test('removeAccount removes by id and persists', () async {
      final store = await seededStore([testAccount(), testAccount(id: 'b2')]);
      final state = testState(store: store);
      await Future<void>.delayed(Duration.zero);
      await state.removeAccount('a1');
      expect(state.accounts.map((a) => a.id), ['b2']);
      expect(OtpAccount.decodeList((await store.read('accounts.v1'))!),
          hasLength(1));
      state.dispose();
    });

    test('setThemeMode persists and ignores no-ops', () async {
      final store = MemoryAccountStore();
      final state = testState(store: store);
      await Future<void>.delayed(Duration.zero);
      var notified = 0;
      state.addListener(() => notified++);

      await state.setThemeMode(ThemeMode.system);
      expect(notified, 0);

      await state.setThemeMode(ThemeMode.light);
      expect(state.themeMode, ThemeMode.light);
      expect(notified, greaterThan(0));
      expect(await store.read('theme.v1'), 'light');
      state.dispose();
    });

    test('ticker notifies once per second and stops on dispose', () {
      fakeAsync((async) {
        final state = testState();
        async.flushMicrotasks();
        var notified = 0;
        state.addListener(() => notified++);
        async.elapse(const Duration(seconds: 3));
        expect(notified, greaterThanOrEqualTo(3));
        state.dispose();
        final after = notified;
        async.elapse(const Duration(seconds: 2));
        expect(notified, after);
      });
    });

    test('now reflects the injected clock after load', () async {
      final state = testState();
      await Future<void>.delayed(Duration.zero);
      expect(state.now, kTestTime);
      state.dispose();
    });
  });
}
