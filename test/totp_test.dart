import 'dart:typed_data';

import 'package:authe/totp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('base32Decode', () {
    test('decodes uppercase, lowercase, padded and spaced input', () {
      final expected = base32Decode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
      expect(String.fromCharCodes(expected), '12345678901234567890');
      expect(base32Decode('gezdgnbvgy3tqojqgezdgnbvgy3tqojq'), expected);
      expect(base32Decode('GEZD GNBV GY3T QOJQ GEZD GNBV GY3T QOJQ'), expected);
      expect(base32Decode('GEZD-GNBV-GY3T-QOJQ'), base32Decode('GEZDGNBVGY3TQOJQ'));
      expect(base32Decode('GEZDGNBVGY3TQOJQ===='), expected.sublist(0, 10));
    });

    test('rejects empty and invalid input', () {
      expect(() => base32Decode(''), throwsFormatException);
      expect(() => base32Decode('   '), throwsFormatException);
      expect(() => base32Decode('GEZDGNBV!'), throwsFormatException);
      expect(() => base32Decode('0189'), throwsFormatException);
    });
  });

  group('hotp', () {
    // RFC 4226 Appendix D, seed "12345678901234567890".
    final key = base32Decode('GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ');
    const codes = [
      '755224', '287082', '359152', '969429', '338314',
      '254676', '287922', '162583', '399871', '520489',
    ];
    for (var i = 0; i < codes.length; i++) {
      test('counter $i -> ${codes[i]}', () {
        expect(hotp(key: key, counter: i), codes[i]);
      });
    }

    test('respects digit count', () {
      expect(hotp(key: key, counter: 0, digits: 8), '84755224');
    });
  });

  group('totp', () {
    DateTime t(int seconds) =>
        DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);

    // RFC 6238 Appendix B test vectors, truncated to 6 digits where needed.
    test('SHA1 vectors', () {
      const key = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
      const cases = {
        59: '94287082',
        1111111109: '07081804',
        1111111111: '14050471',
        1234567890: '89005924',
        2000000000: '69279037',
        20000000000: '65353130',
      };
      cases.forEach((seconds, expected) {
        expect(
          totpCode(secret: key, time: t(seconds), digits: 8),
          expected,
          reason: 'T=$seconds',
        );
      });
    });

    test('SHA256 vector', () {
      expect(
        totpCode(
          secret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZA',
          time: t(59),
          digits: 8,
          algorithm: OtpAlgorithm.sha256,
        ),
        '46119246',
      );
    });

    test('SHA512 vector', () {
      expect(
        totpCode(
          secret:
              'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'
              'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQGEZDGNA',
          time: t(59),
          digits: 8,
          algorithm: OtpAlgorithm.sha512,
        ),
        '90693936',
      );
    });

    test('uses the configured period', () {
      final key = Uint8List.fromList('12345678901234567890'.codeUnits);
      final code30 = hotp(key: key, counter: 2);
      expect(
        totpCode(
          secret: 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ',
          time: t(75),
          period: 15,
        ),
        // epoch 75 with period 15 -> counter 5
        hotp(key: key, counter: 5),
      );
      expect(code30, isNot(hotp(key: key, counter: 5)));
    });
  });

  group('OtpAlgorithm', () {
    test('maps uri values', () {
      expect(OtpAlgorithm.fromUriValue('SHA1'), OtpAlgorithm.sha1);
      expect(OtpAlgorithm.fromUriValue('sha256'), OtpAlgorithm.sha256);
      expect(OtpAlgorithm.fromUriValue('SHA512'), OtpAlgorithm.sha512);
    });

    test('rejects unknown algorithms', () {
      expect(() => OtpAlgorithm.fromUriValue('MD5'), throwsFormatException);
    });
  });
}
