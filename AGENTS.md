# Authe

TOTP (RFC 6238) authenticator for Android, iOS, macOS, Windows and Linux. The web build is a GitLab Pages landing page only, not the app.

## Structure

- `lib/main.dart` — entrypoint; conditional import picks `bootstrap_app.dart` (native) or `bootstrap_stub.dart` (web → `landing_page.dart`)
- `lib/app_state.dart` — single ChangeNotifier above MaterialApp; owns accounts, theme, 1s ticker
- `lib/totp.dart` — base32/HOTP/TOTP (RFC 4226 + 6238)
- `lib/account.dart` — `OtpAccount`, `otpauth://` parsing, JSON
- `lib/account_store.dart` — `AccountStore` abstraction; `SecureAccountStore` (flutter_secure_storage) + `MemoryAccountStore` (tests)
- `lib/ui/` — home (compact <720 / wide >=720 via LayoutBuilder), add account (URI, scan, manual), scan, settings
- `lib/landing_page.dart` — the whole web build (dark landing page + live demo code)

## Rules

- One `AppState` above `MaterialApp`, injected for tests. Never recreate it on resize.
- Commits: Conventional Commits, `type: 中文描述`. `cog bump` owns versions and CHANGELOG — never edit either by hand.
- Feature branches + MRs only; regular merge commits (no squash) so the changelog stays useful.
- GitLab CI jobs run on the `linux-truenas` shared runner; heavy builds run on the GitHub mirror.

## Verify

```bash
flutter pub get
flutter analyze
flutter test --coverage
# coverage gate (what CI runs):
lcov --remove coverage/lcov.info '**/*.g.dart' '**/*.freezed.dart' '**/l10n/**' -o coverage/lcov.cleaned.info
lcov --summary coverage/lcov.cleaned.info --fail-under-lines 100
```

Tests are 100% line coverage. Goldens live in `test/goldens/`; regenerate with `flutter test --update-goldens`. `test/flutter_test_config.dart` loads the bundled Inter + MaterialIcons fonts so goldens show real glyphs — keep `FLUTTER_VERSION` in `.github/workflows/build.yml` pinned to the local SDK to keep goldens byte-identical.

Widget test gotchas encountered:

- `pump(duration)` produces one frame; route pushes need `pump()` then `pumpAndSettle()`.
- `tester.enterText` shows the fake keyboard and shrinks the viewport — call `tester.testTextInput.hide()` before tapping widgets further down a lazy ListView.
- `find.byType` matches `runtimeType` exactly — generic widgets need explicit type args (`DropdownButtonFormField<int>`).
- Replace-the-root widget test pattern (pumpWidget same type twice) reuses the old State; injected AppStates must be created once, not per-pump.

## Signing

Android upload keystore lives in `~/Desktop/authe-signing/` (backup, never committed). CI injects it from the `ANDROID_*` GitHub secrets.
