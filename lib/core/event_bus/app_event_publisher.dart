import 'package:template/core/event_bus/app_event.dart';

/// Publishes best-effort application-shell notifications.
///
/// This non-owning role exposes no event-bus lifecycle. Delivery remains
/// in-process, asynchronous, and safe to lose.
abstract interface class AppEventPublisher {
  /// Publishes [event] to current matching subscribers.
  void emit(AppEvent event);
}
