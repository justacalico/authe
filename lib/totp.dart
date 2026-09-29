import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// HMAC algorithm used for code generation.
enum OtpAlgorithm {
  sha1('SHA1'),
  sha256('SHA256'),
  sha512('SHA512');

  const OtpAlgorithm(this.uriValue);

  /// Value used inside otpauth:// URIs.
  final String uriValue;

  static OtpAlgorithm fromUriValue(String value) {
    for (final algorithm in values) {
      if (algorithm.uriValue == value.toUpperCase()) return algorithm;
    }
    throw FormatException('Unsupported algorithm: $value');
  }
}

/// Decodes a base32 (RFC 4648) string. Accepts lowercase letters, ignores
/// spaces and dashes, and tolerates missing or misplaced padding.
Uint8List base32Decode(String input) {
  final cleaned =
      input.toUpperCase().replaceAll(RegExp(r'[\s\-=]'), '');
  if (cleaned.isEmpty) {
    throw const FormatException('Empty base32 input');
  }

  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
  var buffer = 0;
  var bitsLeft = 0;
  final out = <int>[];

  for (final unit in cleaned.codeUnits) {
    final value = alphabet.indexOf(String.fromCharCode(unit));
    if (value < 0) {
      throw FormatException('Invalid base32 character: ${String.fromCharCode(unit)}');
    }
    buffer = (buffer << 5) | value;
    bitsLeft += 5;
    if (bitsLeft >= 8) {
      bitsLeft -= 8;
      out.add((buffer >> bitsLeft) & 0xFF);
    }
  }

  return Uint8List.fromList(out);
}

/// Generates an HOTP value (RFC 4226) as a zero-padded decimal string.
String hotp({
  required Uint8List key,
  required int counter,
  int digits = 6,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) {
  final counterBytes = ByteData(8)..setUint64(0, counter);
  final hmac = switch (algorithm) {
    OtpAlgorithm.sha1 => Hmac(sha1, key),
    OtpAlgorithm.sha256 => Hmac(sha256, key),
    OtpAlgorithm.sha512 => Hmac(sha512, key),
  };
  final hash = hmac.convert(counterBytes.buffer.asUint8List()).bytes;

  final offset = hash[hash.length - 1] & 0x0F;
  final binary = ((hash[offset] & 0x7F) << 24) |
      ((hash[offset + 1] & 0xFF) << 16) |
      ((hash[offset + 2] & 0xFF) << 8) |
      (hash[offset + 3] & 0xFF);

  final code = binary % _pow10(digits);
  return code.toString().padLeft(digits, '0');
}

/// Generates the current TOTP code (RFC 6238) for [secret], which may be
/// given in any base32 formatting (spaces, lowercase, missing padding).
String totpCode({
  required String secret,
  required DateTime time,
  int digits = 6,
  int period = 30,
  OtpAlgorithm algorithm = OtpAlgorithm.sha1,
}) {
  final counter = time.toUtc().millisecondsSinceEpoch ~/ 1000 ~/ period;
  return hotp(
    key: base32Decode(secret),
    counter: counter,
    digits: digits,
    algorithm: algorithm,
  );
}

int _pow10(int digits) {
  var value = 1;
  for (var i = 0; i < digits; i++) {
    value *= 10;
  }
  return value;
}
