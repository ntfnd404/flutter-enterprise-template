import 'package:template/core/event_bus/app_event.dart';

/// Observes best-effort application-shell notifications by concrete type.
///
/// This non-owning role exposes no event-bus lifecycle. Consumers own and must
/// cancel every subscription they create.
abstract interface class AppEventSubscriber {
  /// Returns events of type [T] emitted after this subscription starts.
  Stream<T> on<T extends AppEvent>();
}
