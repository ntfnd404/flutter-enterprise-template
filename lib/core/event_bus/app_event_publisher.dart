import 'package:template/core/event_bus/app_event.dart';

/// Non-owning role that publishes best-effort application-shell facts.
abstract interface class AppEventPublisher {
  /// Delivers [event] to the subscribers that are active now.
  void emit(AppEvent event);
}
