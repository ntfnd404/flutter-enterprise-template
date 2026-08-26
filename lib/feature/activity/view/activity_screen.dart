import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';

/// Displays draft-creation facts observed during this screen's lifetime.
final class ActivityScreen extends StatelessWidget {
  /// Creates a screen highlighting [highlightSequence].
  const ActivityScreen({required this.highlightSequence, super.key});

  /// Non-authoritative operation sequence encoded in the route.
  final int highlightSequence;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Activity')),
    body: Center(
      child: BlocBuilder<ActivityBloc, ActivityState>(
        builder: (context, state) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'Draft completions observed live: ${state.observedCount}',
              key: const ValueKey<String>('activity-route-marker'),
            ),
            Text(
              state.lastObservedSequence == highlightSequence
                  ? 'Draft operation $highlightSequence completed live'
                  : 'No live completion for draft operation '
                        '$highlightSequence. Check Orders for authoritative state.',
              key: const ValueKey<String>('activity-highlight-marker'),
            ),
          ],
        ),
      ),
    ),
  );
}
