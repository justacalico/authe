import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'theme.dart';
import 'ui/home_page.dart';

/// App root. Owns the single [AppState] so it survives every resize and
/// rebuild underneath it.
class AutheApp extends StatefulWidget {
  const AutheApp({super.key, this.state});

  /// Injectable for tests; production code leaves it null.
  final AppState? state;

  @override
  State<AutheApp> createState() => _AutheAppState();
}

class _AutheAppState extends State<AutheApp> {
  late final AppState _state = widget.state ?? AppState();

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
      value: _state,
      child: Consumer<AppState>(
        builder: (context, state, _) => MaterialApp(
          title: 'Authe',
          debugShowCheckedModeBanner: false,
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: state.themeMode,
          home: const HomePage(),
        ),
      ),
    );
  }
}
