import 'dart:convert';

import 'totp.dart';

/// A single TOTP entry, typically imported from an otpauth:// URI or entered
/// by hand.
class OtpAccount {
  OtpAccount({
    required this.id,
    required this.issuer,
    required this.accountName,
    required this.secret,
    this.digits = 6,
    this.period = 30,
    this.algorithm = OtpAlgorithm.sha1,
  });

  /// Stable random id used for storage and deletion.
  final String id;
  final String issuer;
  final String accountName;

  /// Base32 secret as entered or imported.
  final String secret;
  final int digits;
  final int period;
  final OtpAlgorithm algorithm;

  /// "Issuer (name)" when both parts exist, otherwise whichever is set.
  String get displayName {
    if (issuer.isEmpty) return accountName;
    if (accountName.isEmpty) return issuer;
    return '$issuer ($accountName)';
  }

  String codeAt(DateTime time) => totpCode(
        secret: secret,
        time: time,
        digits: digits,
        period: period,
        algorithm: algorithm,
      );

  /// Seconds until the code currently shown expires.
  int secondsRemaining(DateTime time) {
    final seconds = time.toUtc().millisecondsSinceEpoch ~/ 1000;
    return period - (seconds % period);
  }

  /// Fraction of the period still left (1 → freshly generated, 0 → expired).
  double fractionRemaining(DateTime time) =>
      secondsRemaining(time) / period;

  /// Parses an otpauth://totp/ URI into an account. Throws [FormatException]
  /// on anything malformed or unsupported.
  factory OtpAccount.fromUri(Uri uri) {
    if (uri.scheme != 'otpauth') {
      throw const FormatException('URI must start with otpauth://');
    }
    if (uri.host != 'totp') {
      throw FormatException('Unsupported OTP type: ${uri.host}');
    }
    if (uri.pathSegments.length != 1 || uri.pathSegments.single.isEmpty) {
      throw const FormatException('Missing account label');
    }

    final label = uri.pathSegments.single;
    final separator = label.indexOf(':');
    final labelIssuer = separator >= 0 ? label.substring(0, separator) : '';
    final accountName =
        separator >= 0 ? label.substring(separator + 1) : label;

    final params = uri.queryParameters;
    final secret = params['secret'] ?? '';
    if (secret.isEmpty) {
      throw const FormatException('Missing secret parameter');
    }
    // Fail early on secrets that are not valid base32.
    base32Decode(secret);

    final issuer = params['issuer'] ?? labelIssuer;
    final digits = _parsePositive(params['digits'], 6);
    if (digits != 6 && digits != 8) {
      throw FormatException('Unsupported digit count: $digits');
    }
    final period = _parsePositive(params['period'], 30);
    final algorithm = params.containsKey('algorithm')
        ? OtpAlgorithm.fromUriValue(params['algorithm']!)
        : OtpAlgorithm.sha1;

    return OtpAccount(
      id: _newId(),
      issuer: issuer,
      accountName: accountName,
      secret: secret,
      digits: digits,
      period: period,
      algorithm: algorithm,
    );
  }

  /// Convenience wrapper for parsing a raw otpauth:// string.
  factory OtpAccount.parse(String uri) => OtpAccount.fromUri(Uri.parse(uri));

  /// Serializes back to an otpauth:// URI (used by tests and export).
  Uri toUri() {
    final label = issuer.isEmpty
        ? accountName
        : '$issuer:$accountName';
    return Uri(
      scheme: 'otpauth',
      host: 'totp',
      pathSegments: [label],
      queryParameters: {
        'secret': secret,
        if (issuer.isNotEmpty) 'issuer': issuer,
        if (algorithm != OtpAlgorithm.sha1) 'algorithm': algorithm.uriValue,
        if (digits != 6) 'digits': '$digits',
        if (period != 30) 'period': '$period',
      },
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'issuer': issuer,
        'accountName': accountName,
        'secret': secret,
        'digits': digits,
        'period': period,
        'algorithm': algorithm.uriValue,
      };

  factory OtpAccount.fromJson(Map<String, dynamic> json) => OtpAccount(
        id: json['id'] as String? ?? _newId(),
        issuer: json['issuer'] as String? ?? '',
        accountName: json['accountName'] as String? ?? '',
        secret: json['secret'] as String,
        digits: json['digits'] as int? ?? 6,
        period: json['period'] as int? ?? 30,
        algorithm:
            OtpAlgorithm.fromUriValue(json['algorithm'] as String? ?? 'SHA1'),
      );

  static List<OtpAccount> decodeList(String jsonString) {
    final raw = jsonDecode(jsonString);
    if (raw is! List) {
      throw const FormatException('Account payload is not a list');
    }
    return raw
        .map((e) => OtpAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<OtpAccount> accounts) =>
      jsonEncode(accounts.map((a) => a.toJson()).toList());

  static int _idCounter = 0;

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-${_idCounter++}';

  static int _parsePositive(String? raw, int fallback) {
    if (raw == null) return fallback;
    final value = int.tryParse(raw);
    if (value == null || value <= 0) {
      throw FormatException('Invalid number: $raw');
    }
    return value;
  }
}
