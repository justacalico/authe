import 'package:authe/account.dart';
import 'package:authe/totp.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

void main() {
  group('OtpAccount.fromUri', () {
    test('parses a full otpauth uri', () {
      final account = OtpAccount.parse(
        'otpauth://totp/GitHub:you%40example.com'
        '?secret=$kRfcSecret&issuer=GitHub&algorithm=SHA256&digits=8&period=60',
      );
      expect(account.issuer, 'GitHub');
      expect(account.accountName, 'you@example.com');
      expect(account.secret, kRfcSecret);
      expect(account.algorithm, OtpAlgorithm.sha256);
      expect(account.digits, 8);
      expect(account.period, 60);
      expect(account.id, isNotEmpty);
    });

    test('defaults algorithm, digits and period; issuer from label', () {
      final account = OtpAccount.parse(
        'otpauth://totp/GitLab:bot?secret=$kRfcSecret',
      );
      expect(account.issuer, 'GitLab');
      expect(account.accountName, 'bot');
      expect(account.algorithm, OtpAlgorithm.sha1);
      expect(account.digits, 6);
      expect(account.period, 30);
    });

    test('label without issuer prefix', () {
      final account =
          OtpAccount.parse('otpauth://totp/me%40x.co?secret=$kRfcSecret');
      expect(account.issuer, '');
      expect(account.accountName, 'me@x.co');
    });

    test('issuer parameter overrides the label prefix', () {
      final account = OtpAccount.parse(
        'otpauth://totp/Label:acct?secret=$kRfcSecret&issuer=ParamCo',
      );
      expect(account.issuer, 'ParamCo');
    });

    test('rejects malformed uris', () {
      expect(() => OtpAccount.parse('https://totp/x?secret=$kRfcSecret'),
          throwsFormatException);
      expect(() => OtpAccount.parse('otpauth://hotp/x?secret=$kRfcSecret'),
          throwsFormatException);
      expect(() => OtpAccount.parse('otpauth://totp/?secret=$kRfcSecret'),
          throwsFormatException);
      expect(() => OtpAccount.parse('otpauth://totp/x'), throwsFormatException);
      expect(() => OtpAccount.parse('otpauth://totp/x?secret=!!!'),
          throwsFormatException);
      expect(
          () => OtpAccount.parse('otpauth://totp/x?secret=$kRfcSecret&digits=5'),
          throwsFormatException);
      expect(
          () =>
              OtpAccount.parse('otpauth://totp/x?secret=$kRfcSecret&digits=abc'),
          throwsFormatException);
      expect(
          () =>
              OtpAccount.parse('otpauth://totp/x?secret=$kRfcSecret&period=0'),
          throwsFormatException);
      expect(
          () => OtpAccount.parse(
              'otpauth://totp/x?secret=$kRfcSecret&algorithm=MD5'),
          throwsFormatException);
    });
  });

  group('OtpAccount.uri round trip', () {
    test('encodes back to an equivalent uri', () {
      final original = OtpAccount.parse(
        'otpauth://totp/GitHub:you%40example.com?secret=$kRfcSecret'
        '&issuer=GitHub&algorithm=SHA512&digits=8&period=60',
      );
      final copy = OtpAccount.fromUri(original.toUri());
      expect(copy.issuer, original.issuer);
      expect(copy.accountName, original.accountName);
      expect(copy.secret, original.secret);
      expect(copy.algorithm, original.algorithm);
      expect(copy.digits, original.digits);
      expect(copy.period, original.period);
    });

    test('omits default parameters and empty issuer', () {
      final plain = testAccount(issuer: '').toUri();
      expect(plain.queryParameters.containsKey('issuer'), isFalse);
      expect(plain.queryParameters.containsKey('algorithm'), isFalse);
      expect(plain.queryParameters.containsKey('digits'), isFalse);
      expect(plain.queryParameters.containsKey('period'), isFalse);
    });
  });

  group('displayName', () {
    test('combines issuer and account', () {
      expect(testAccount().displayName, 'GitHub (you@example.com)');
      expect(testAccount(issuer: '').displayName, 'you@example.com');
      expect(testAccount(accountName: '').displayName, 'GitHub');
    });
  });

  group('codes and countdown', () {
    test('codeAt returns the hotp for the current counter', () {
      // epoch 10 -> counter 0 -> RFC 4226 code 755224
      expect(testAccount().codeAt(kTestTime), '755224');
    });

    test('secondsRemaining counts down inside the period', () {
      expect(testAccount().secondsRemaining(kTestTime), 20);
      expect(testAccount().fractionRemaining(kTestTime), closeTo(20 / 30, 1e-9));
      final boundary =
          DateTime.fromMillisecondsSinceEpoch(30 * 1000, isUtc: true);
      expect(testAccount().secondsRemaining(boundary), 30);
    });
  });

  group('json', () {
    test('round trips a list', () {
      final accounts = [testAccount(), testAccount(id: 'b2', issuer: 'GitLab')];
      final decoded = OtpAccount.decodeList(OtpAccount.encodeList(accounts));
      expect(decoded, hasLength(2));
      expect(decoded[0].id, 'a1');
      expect(decoded[1].issuer, 'GitLab');
    });

    test('fromJson fills defaults', () {
      final account = OtpAccount.fromJson({'secret': kRfcSecret});
      expect(account.digits, 6);
      expect(account.period, 30);
      expect(account.algorithm, OtpAlgorithm.sha1);
      expect(account.id, isNotEmpty);
      expect(account.issuer, '');
    });

    test('decodeList rejects non-lists', () {
      expect(() => OtpAccount.decodeList('{"a":1}'), throwsFormatException);
    });
  });
}
