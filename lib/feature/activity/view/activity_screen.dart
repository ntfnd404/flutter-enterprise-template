import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';

/// Displays facts observed during this Activity screen's lifetime.
final class ActivityScreen extends StatelessWidget {
  /// Creates a screen highlighting [highlightSequence].
  const ActivityScreen({required this.highlightSequence, super.key});

  /// Sequence encoded in the typed route.
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
              'Observed since opening Activity: ${state.observedCount}',
              key: const ValueKey<String>('activity-route-marker'),
            ),
            Text(
              state.lastObservedSequence == highlightSequence
                  ? 'Action $highlightSequence was observed live'
                  : 'Action $highlightSequence was published before this screen subscribed and was not replayed',
              key: const ValueKey<String>('activity-highlight-marker'),
            ),
          ],
        ),
      ),
    ),
  );
}
