part of 'demo_bloc.dart';

/// Base type for events accepted by `DemoBloc`.
sealed class DemoEvent {
  const DemoEvent();
}

/// Requests the initial demo presentation state.
final class DemoStarted extends DemoEvent {
  /// Creates the startup event.
  const DemoStarted();
}

/// Requests one successful action in the demo feature.
final class DemoActionRequested extends DemoEvent {
  /// Creates the user intent.
  const DemoActionRequested();
}
