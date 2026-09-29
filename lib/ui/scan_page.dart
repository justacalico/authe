import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../account.dart';

/// Builds the camera surface. Injectable so tests can substitute a fake
/// scanner without a platform camera.
typedef ScannerBuilder = Widget Function(
  BuildContext context,
  ValueChanged<String> onCode,
);

/// Whether this platform build can scan QR codes with the camera.
bool get platformSupportsScan =>
    // coverage:ignore-start
    !kIsWeb &&
    (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
// coverage:ignore-end

/// Full-screen camera scanner. Pops with the parsed [OtpAccount].
class ScanPage extends StatelessWidget {
  const ScanPage({super.key, this.scannerBuilder});

  final ScannerBuilder? scannerBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR code')),
      body: (scannerBuilder ?? _platformScanner)(context, (raw) {
        try {
          final account = OtpAccount.parse(raw);
          Navigator.of(context).pop(account);
        } on FormatException {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Not a valid TOTP QR code')),
            );
        }
      }),
    );
  }

  // coverage:ignore-start
  Widget _platformScanner(BuildContext context, ValueChanged<String> onCode) {
    var handled = false;
    return MobileScanner(
      onDetect: (capture) {
        if (handled) return;
        final raw = capture.barcodes.firstOrNull?.rawValue;
        if (raw == null) return;
        handled = true;
        onCode(raw);
      },
    );
  }
  // coverage:ignore-end
}
