import 'package:flutter/material.dart';

/// Isolated, pre-graph fallback displayed after a required startup failure.
final class StartupFailureApp extends StatelessWidget {
  /// Creates a fallback containing only a stable support [diagnosticCode].
  const StartupFailureApp({required this.diagnosticCode, super.key});

  /// Privacy-safe code describing the failed startup stage.
  final String diagnosticCode;

  @override
  Widget build(BuildContext context) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: Column(
          key: const ValueKey('startup-failure-marker'),
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('The application could not be started.'),
            Text(diagnosticCode),
          ],
        ),
      ),
    ),
  );
}
