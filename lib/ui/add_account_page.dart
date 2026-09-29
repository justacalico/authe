import 'package:flutter/material.dart';

import '../account.dart';
import '../totp.dart';
import 'scan_page.dart';

/// Add an account three ways: paste an otpauth:// link, scan a QR code on
/// devices with a camera, or type the details in by hand.
class AddAccountPage extends StatelessWidget {
  const AddAccountPage({super.key, this.showScan, this.scannerBuilder});

  /// Override for tests; defaults to [platformSupportsScan].
  final bool? showScan;
  final ScannerBuilder? scannerBuilder;

  @override
  Widget build(BuildContext context) {
    final canScan = showScan ?? platformSupportsScan;
    return Scaffold(
      appBar: AppBar(title: const Text('Add account')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (canScan)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.qr_code_scanner),
                title: const Text('Scan QR code'),
                subtitle: const Text('Point the camera at the setup code'),
                onTap: () => _scan(context),
              ),
            ),
          if (canScan) const SizedBox(height: 12),
          _UriEntry(onAdd: (a) => Navigator.of(context).pop(a)),
          const SizedBox(height: 12),
          _ManualEntry(onAdd: (a) => Navigator.of(context).pop(a)),
        ],
      ),
    );
  }

  Future<void> _scan(BuildContext context) async {
    final account = await Navigator.of(context).push<OtpAccount>(
      MaterialPageRoute(
        builder: (_) => ScanPage(scannerBuilder: scannerBuilder),
      ),
    );
    if (account != null && context.mounted) {
      Navigator.of(context).pop(account);
    }
  }
}

class _UriEntry extends StatefulWidget {
  const _UriEntry({required this.onAdd});

  final ValueChanged<OtpAccount> onAdd;

  @override
  State<_UriEntry> createState() => _UriEntryState();
}

class _UriEntryState extends State<_UriEntry> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Setup link', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'otpauth://totp/…',
                errorText: _error,
              ),
              autocorrect: false,
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _submit,
                child: const Text('Add from link'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    try {
      widget.onAdd(OtpAccount.parse(_controller.text.trim()));
    } on FormatException catch (e) {
      setState(() => _error = e.message);
    }
  }
}

class _ManualEntry extends StatefulWidget {
  const _ManualEntry({required this.onAdd});

  final ValueChanged<OtpAccount> onAdd;

  @override
  State<_ManualEntry> createState() => _ManualEntryState();
}

class _ManualEntryState extends State<_ManualEntry> {
  final _formKey = GlobalKey<FormState>();
  final _issuer = TextEditingController();
  final _account = TextEditingController();
  final _secret = TextEditingController();
  OtpAlgorithm _algorithm = OtpAlgorithm.sha1;
  int _digits = 6;
  int _period = 30;

  @override
  void dispose() {
    _issuer.dispose();
    _account.dispose();
    _secret.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Manual entry',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _issuer,
                decoration: const InputDecoration(
                  labelText: 'Issuer',
                  hintText: 'GitHub',
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _account,
                decoration: const InputDecoration(
                  labelText: 'Account name',
                  hintText: 'you@example.com',
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? 'Account name is required'
                        : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _secret,
                decoration: const InputDecoration(
                  labelText: 'Secret key',
                  hintText: 'Base32, e.g. JBSW Y3DP EHPK 3PXP',
                ),
                autocorrect: false,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Secret key is required';
                  }
                  try {
                    base32Decode(value);
                  } on FormatException {
                    return 'Not valid base32';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<OtpAlgorithm>(
                      initialValue: _algorithm,
                      decoration: const InputDecoration(labelText: 'Algorithm'),
                      items: OtpAlgorithm.values
                          .map((a) => DropdownMenuItem(
                              value: a, child: Text(a.uriValue)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _algorithm = v ?? OtpAlgorithm.sha1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _digits,
                      decoration: const InputDecoration(labelText: 'Digits'),
                      items: const [
                        DropdownMenuItem(value: 6, child: Text('6')),
                        DropdownMenuItem(value: 8, child: Text('8')),
                      ],
                      onChanged: (v) => setState(() => _digits = v ?? 6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _period,
                      decoration:
                          const InputDecoration(labelText: 'Period (s)'),
                      items: const [
                        DropdownMenuItem(value: 15, child: Text('15')),
                        DropdownMenuItem(value: 30, child: Text('30')),
                        DropdownMenuItem(value: 60, child: Text('60')),
                      ],
                      onChanged: (v) => setState(() => _period = v ?? 30),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Add account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    widget.onAdd(
      OtpAccount(
        id: '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-m',
        issuer: _issuer.text.trim(),
        accountName: _account.text.trim(),
        secret: _secret.text.trim().toUpperCase().replaceAll(' ', ''),
        digits: _digits,
        period: _period,
        algorithm: _algorithm,
      ),
    );
  }
}
