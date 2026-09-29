import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme.dart';
import 'totp.dart';

/// Web entry point. The web build is a marketing/download page only; the
/// authenticator itself never runs in a browser.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key, this.clock});

  static const releasesBase =
      'https://gitlab.com/HttpAnimations/authe/-/releases/permalink/latest/downloads';
  static const sourceUrl = 'https://gitlab.com/HttpAnimations/authe';
  static const mirrorUrl = 'https://github.com/justacalico/authe';
  static const altstoreUrl =
      'altstore://source?URL=https%3A%2F%2Fhttpanimations.gitlab.io%2Fauthe%2Faltstore%2Fapps.json';

  /// Injected clock for deterministic tests; production uses DateTime.now.
  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Authe',
      debugShowCheckedModeBanner: false,
      theme: _landingTheme(),
      home: _LandingBody(clock: clock),
    );
  }

  ThemeData _landingTheme() {
    const card = Color(0xFF1C1C1E);
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Inter',
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0C0C0E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: kAccent,
        primary: kAccent,
        brightness: Brightness.dark,
        surface: card,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2E),
        thickness: 1,
        space: 1,
      ),
    );
  }
}

class _LandingBody extends StatelessWidget {
  const _LandingBody({this.clock});

  final DateTime Function()? clock;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Hero(),
                  const SizedBox(height: 36),
                  _DemoCard(clock: clock),
                  SizedBox(height: 36),
                  _Downloads(),
                  SizedBox(height: 28),
                  _Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Image.asset('assets/icon.png', width: 84, height: 84),
        ),
        const SizedBox(height: 18),
        Text(
          'Authe',
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Open two-factor authentication\nfor every screen you own.',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

/// A live TOTP code generated in the browser from a public demo secret,
/// ticking exactly like the real app does.
class _DemoCard extends StatefulWidget {
  const _DemoCard({this.clock});

  final DateTime Function()? clock;

  static const _secret = 'JBSWY3DPEHPK3PXP';

  @override
  State<_DemoCard> createState() => _DemoCardState();
}

class _DemoCardState extends State<_DemoCard> {
  late Timer _ticker;
  late DateTime Function() _clock;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _clock = widget.clock ?? DateTime.now;
    _now = _clock();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = _clock());
    });
  }

  @override
  void dispose() {
    _ticker.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const period = 30;
    final seconds = _now.toUtc().millisecondsSinceEpoch ~/ 1000;
    final remaining = period - (seconds % period);
    final code = totpCode(secret: _DemoCard._secret, time: _now);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'demo@authe.app',
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${code.substring(0, 3)} ${code.substring(3)}',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 4,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: remaining / period,
                minHeight: 4,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Downloads extends StatelessWidget {
  const _Downloads();

  static const _items = [
    _DownloadItem(
      platform: 'iOS',
      detail: 'AltStore source',
      file: 'authe-ios-arm64-unsigned.ipa',
      icon: Icons.phone_iphone,
      altstore: true,
    ),
    _DownloadItem(
      platform: 'Android',
      detail: 'APK',
      file: 'authe-android.apk',
      icon: Icons.phone_android,
    ),
    _DownloadItem(
      platform: 'macOS',
      detail: 'Apple Silicon · DMG',
      file: 'authe-macos-arm64.dmg',
      icon: Icons.laptop_mac,
    ),
    _DownloadItem(
      platform: 'Windows',
      detail: 'x86_64 · ZIP',
      file: 'authe-windows-x86_64.zip',
      icon: Icons.desktop_windows_outlined,
    ),
    _DownloadItem(
      platform: 'Linux',
      detail: 'x86_64 · AppImage',
      file: 'authe-linux-x86_64.AppImage',
      icon: Icons.terminal,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'Get Authe',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < _items.length; i++) ...[
                if (i > 0) const Divider(indent: 60),
                _DownloadRow(item: _items[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DownloadItem {
  const _DownloadItem({
    required this.platform,
    required this.detail,
    required this.file,
    required this.icon,
    this.altstore = false,
  });

  final String platform;
  final String detail;
  final String file;
  final IconData icon;
  final bool altstore;
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.item});

  final _DownloadItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Icon(item.icon, size: 26),
      title: Text(item.platform),
      subtitle: Text(item.detail),
      trailing: Icon(
        item.altstore ? Icons.add_link : Icons.download_outlined,
        size: 20,
        color: theme.colorScheme.primary,
      ),
      onTap: () {
        final url = item.altstore
            ? LandingPage.altstoreUrl
            : '${LandingPage.releasesBase}/${item.file}';
        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      },
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    final linkStyle = style?.copyWith(
      color: Theme.of(context).colorScheme.primary,
    );
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 18,
          children: [
            _FooterLink('Source on GitLab', LandingPage.sourceUrl, linkStyle),
            _FooterLink('GitHub mirror', LandingPage.mirrorUrl, linkStyle),
          ],
        ),
        const SizedBox(height: 8),
        Text('Open source under the GNU AGPL v3', style: style),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink(this.label, this.url, this.style);

  final String label;
  final String url;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Text(label, style: style),
      ),
    );
  }
}
