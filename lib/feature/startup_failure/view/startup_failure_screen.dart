import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/startup_failure/bloc/startup_failure_bloc.dart';

/// Safe presentation rendered when application startup cannot complete.
final class StartupFailureScreen extends StatelessWidget {
  /// Creates the isolated startup-failure screen.
  const StartupFailureScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<StartupFailureBloc, StartupFailureState>(
    builder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'The application could not start.',
              key: ValueKey<String>('startup-failure-marker'),
            ),
            Text(state.diagnosticCode),
          ],
        ),
      ),
    ),
  );
}
