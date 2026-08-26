part of 'demo_bloc.dart';

/// Immutable presentation state rendered by the demo feature.
final class DemoState {
  /// Creates a demo presentation state.
  const DemoState({
    required this.isReady,
    required this.completedActions,
  });

  /// Whether the feature has processed its initial event.
  final bool isReady;

  /// Number of successfully completed persistent demo actions.
  final int completedActions;
}
