import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_state.dart';

/// Version baked in by the CI build; falls back to a dev marker locally.
const kAppVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

const kSourceUrl = 'https://gitlab.com/HttpAnimations/authe';
const kMirrorUrl = 'https://github.com/justacalico/authe';

/// Settings content, shared by the compact settings route and the wide
/// layout's rail destination.
class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _SectionHeader('Appearance'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.settings_suggest_outlined),
                  label: Text('System'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Dark'),
                ),
              ],
              selected: {state.themeMode},
              onSelectionChanged: (selection) =>
                  state.setThemeMode(selection.first),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _SectionHeader('About'),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: const Text('Private by design'),
                subtitle: const Text(
                  'Secrets stay in your device keychain. Nothing leaves this device.',
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.code),
                title: const Text('Source code'),
                subtitle: const Text('GitLab (primary) · GitHub (mirror)'),
                trailing: const Icon(Icons.open_in_new, size: 18),
                onTap: () => _open(kSourceUrl),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('License'),
                subtitle: const Text('GNU AGPL v3'),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Authe',
                  applicationVersion: kAppVersion,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            'Authe $kAppVersion',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  static void _open(String url) {
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }
}

/// Standalone settings route used by the compact layout.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const SettingsView(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
