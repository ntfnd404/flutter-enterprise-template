part of 'demo_bloc.dart';

/// Base type for one-shot commands from `DemoBloc` to its own UI.
sealed class DemoAction {
  const DemoAction();
}

/// Requests transient confirmation for a successfully completed demo action.
final class ShowDemoActionCompletedAction extends DemoAction {
  /// Creates a confirmation command for [sequence].
  const ShowDemoActionCompletedAction({required this.sequence});

  /// One-based identifier displayed by the UI.
  final int sequence;
}
