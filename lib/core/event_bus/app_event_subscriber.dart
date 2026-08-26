import 'package:template/core/event_bus/app_event.dart';

/// Non-owning role that observes best-effort application-shell facts.
abstract interface class AppEventSubscriber {
  /// Returns a no-replay stream of events with the requested type.
  Stream<T> on<T extends AppEvent>();
}
