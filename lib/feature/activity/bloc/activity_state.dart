part of 'activity_bloc.dart';

/// Immutable, non-authoritative projection observed while Activity is mounted.
final class ActivityState {
  /// Creates a bounded Activity projection.
  const ActivityState({
    required this.observedCount,
    this.lastObservedSequence,
  });

  /// Number of live facts observed since this Activity screen was created.
  final int observedCount;

  /// Most recent live sequence, which may have gaps, or `null` before the first
  /// observed fact.
  final int? lastObservedSequence;
}
