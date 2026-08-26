part of 'startup_failure_bloc.dart';

/// Immutable presentation state for the startup fallback.
final class StartupFailureState {
  /// Creates state containing a safe support [diagnosticCode].
  const StartupFailureState({required this.diagnosticCode});

  /// Stable non-sensitive identifier that may be shared with support.
  final String diagnosticCode;
}
