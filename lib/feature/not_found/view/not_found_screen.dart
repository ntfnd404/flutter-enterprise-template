import 'package:flutter/material.dart';

/// Privacy-safe fallback for unknown or malformed navigation input.
final class NotFoundScreen extends StatelessWidget {
  /// Creates a fallback that deliberately receives no raw route input.
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Text(
        'Page not found',
        key: ValueKey<String>('not-found-marker'),
      ),
    ),
  );
}
