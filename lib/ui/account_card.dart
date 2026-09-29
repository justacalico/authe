import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../account.dart';
import '../app_state.dart';

/// One tappable account row. Tapping copies the current code; the overflow
/// menu exposes destructive actions.
class AccountCard extends StatelessWidget {
  const AccountCard({super.key, required this.account});

  final OtpAccount account;

  @override
  Widget build(BuildContext context) {
    final time = context.watch<AppState>().now;
    final code = account.codeAt(time);
    final remaining = account.secondsRemaining(time);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _copyCode(context, code),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      account.issuer.isEmpty ? 'Account' : account.issuer,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _AccountMenu(account: account),
                  const SizedBox(width: 4),
                  _CountdownRing(
                    fraction: account.fractionRemaining(time),
                    seconds: remaining,
                    urgent: remaining <= 5,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                _grouped(code),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: remaining <= 5
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                account.accountName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _grouped(String code) {
    if (code.length <= 4) return code;
    final split = code.length == 8 ? 4 : 3;
    return '${code.substring(0, split)} ${code.substring(split)}';
  }

  void _copyCode(BuildContext context, String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Code copied'),
          duration: Duration(seconds: 2),
        ),
      );
  }
}

class _CountdownRing extends StatelessWidget {
  const _CountdownRing({
    required this.fraction,
    required this.seconds,
    required this.urgent,
  });

  final double fraction;
  final int seconds;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = urgent ? scheme.error : scheme.primary;
    return SizedBox(
      width: 30,
      height: 30,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: fraction,
            strokeWidth: 2.5,
            color: color,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
          Text(
            '$seconds',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountMenu extends StatelessWidget {
  const _AccountMenu({required this.account});

  final OtpAccount account;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_horiz,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      tooltip: 'Account options',
      onSelected: (value) {
        if (value == 'delete') _confirmDelete(context);
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'delete', child: Text('Delete account')),
      ],
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: Text(
          '${account.displayName} will be removed from this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<AppState>().removeAccount(account.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
