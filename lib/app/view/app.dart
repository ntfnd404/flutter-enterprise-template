import 'package:flutter/material.dart';

/// Router-free root application wrapper used after dependency handoff.
final class App extends StatelessWidget {
  /// Creates the normal application wrapper.
  const App({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text(
          'Template running',
          key: ValueKey('normal-app-marker'),
        ),
      ),
    ),
  );
}
