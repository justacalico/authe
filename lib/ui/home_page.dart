import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../account.dart';
import '../app_state.dart';
import 'account_card.dart';
import 'add_account_page.dart';
import 'settings_page.dart';

/// Breakpoint between the compact phone layout and the wide desktop layout.
const kWideBreakpoint = 720.0;

/// Adaptive root. Swaps between a list-based phone layout and a rail + grid
/// desktop layout based on available width; all data lives in [AppState]
/// above the app, so resizing only rearranges widgets.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth >= kWideBreakpoint
              ? const _WideHome()
              : const _CompactHome(),
    );
  }
}

Future<void> _addAccountFlow(BuildContext context) async {
  final account = await Navigator.of(context).push<OtpAccount>(
    MaterialPageRoute(builder: (_) => const AddAccountPage()),
  );
  if (account == null || !context.mounted) return;
  await context.read<AppState>().addAccount(account);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Account added')),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.compact = true});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.lock_clock_outlined,
          size: 56,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text('No accounts yet', style: theme.textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(
          'Add a two-factor account to start\ngenerating codes.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _addAccountFlow(context),
          icon: const Icon(Icons.add),
          label: const Text('Add account'),
        ),
      ],
    );
    if (compact) {
      return SliverFillRemaining(hasScrollBody: false, child: Center(child: content));
    }
    return Center(child: content);
  }
}

class _CompactHome extends StatelessWidget {
  const _CompactHome();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: const Text('Authe'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsPage(),
                    ),
                  ),
                ),
              ],
            ),
            if (!state.loaded)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (state.accounts.isEmpty)
              const _EmptyState()
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                sliver: SliverList.separated(
                  itemCount: state.accounts.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) =>
                      AccountCard(account: state.accounts[index]),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAccountFlow(context),
        tooltip: 'Add account',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _WideHome extends StatefulWidget {
  const _WideHome();

  @override
  State<_WideHome> createState() => _WideHomeState();
}

class _WideHomeState extends State<_WideHome> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.password_outlined),
                selectedIcon: Icon(Icons.password),
                label: Text('Codes'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: _index == 0 ? const _CodesPane() : const SettingsView(),
          ),
        ],
      ),
    );
  }
}

class _CodesPane extends StatelessWidget {
  const _CodesPane();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 12),
          child: Row(
            children: [
              Text('Authe', style: Theme.of(context).textTheme.headlineMedium),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _addAccountFlow(context),
                icon: const Icon(Icons.add),
                label: const Text('Add account'),
              ),
            ],
          ),
        ),
        Expanded(
          child: !state.loaded
              ? const Center(child: CircularProgressIndicator())
              : state.accounts.isEmpty
                  ? const _EmptyState(compact: false)
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(28, 4, 28, 28),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 340,
                        mainAxisExtent: 132,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: state.accounts.length,
                      itemBuilder: (context, index) =>
                          AccountCard(account: state.accounts[index]),
                    ),
        ),
      ],
    );
  }
}
