part of 'not_found_bloc.dart';

/// Immutable presentation state for privacy-safe route recovery.
final class NotFoundState {
  /// Creates state for a sanitized routing failure [reason].
  const NotFoundState({required this.reason});

  /// Safe category available to future recovery UI.
  final AppRouteFailureReason reason;
}
