import 'package:template/core/event_bus/app_event.dart';

/// Application-shell fact emitted after a demo action succeeds.
///
/// The contract belongs to the application event catalog rather than either
/// feature: producers and consumers may depend on it without importing one
/// another.
final class DemoActionCompletedAppEvent extends AppEvent {
  /// Creates a completion fact for [sequence].
  const DemoActionCompletedAppEvent({required this.sequence});

  /// One-based identifier assigned by the producer.
  final int sequence;
}
