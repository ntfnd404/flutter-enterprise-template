import 'dart:async';

import 'package:template/core/event_bus/app_event.dart';

/// In-process broadcast bus for typed cross-feature application facts.
///
/// Producers publish immutable [AppEvent] objects with [emit], and consumers
/// subscribe to the event type they need with [on]. Delivery is asynchronous
/// and ordered per subscription, with no replay, persistence, acknowledgement,
/// or retry. Events emitted before a consumer subscribes are lost.
/// Listener failures remain asynchronous and are delivered to the Zone that
/// owns the failing subscription; they are not returned to the producer.
///
/// The application graph owns and disposes the bus. Consumers own their stream
/// subscriptions and must cancel them before graph teardown. After disposal
/// starts, both [on] and [emit] throw a [StateError].
///
/// This bus is not a transport for navigation, UI effects, current state,
/// transaction coordination, or work that must complete reliably.
///
/// Events are published and observed as follows:
///
/// ```
/// final eventBus = AppEventBus();
/// final subscription = eventBus
///     .on<FeatureChangedAppEvent>()
///     .listen(onFeatureChanged);
///
/// eventBus.emit(const FeatureChangedAppEvent());
///
/// // When the graph owner is disposed:
/// await subscription.cancel();
/// await eventBus.dispose();
/// ```
final class AppEventBus {
  /// Creates an active event bus.
  AppEventBus();

  final _controller = StreamController<AppEvent>.broadcast();

  /// Returns an asynchronous broadcast stream containing events of type [T].
  ///
  /// Past events are not replayed. Requesting a new event stream after disposal
  /// starts throws [StateError].
  Stream<T> on<T extends AppEvent>() {
    if (_controller.isClosed) {
      throw StateError(
        'Cannot subscribe after event bus disposal has started.',
      );
    }

    return _controller.stream.where((event) => event is T).cast<T>();
  }

  /// Publishes [event] to every current matching subscriber.
  ///
  /// Delivery is ordered per subscription. Publishing after disposal starts
  /// throws [StateError].
  void emit(AppEvent event) => _controller.add(event);

  /// Closes the bus and returns its shared completion future.
  ///
  /// Repeated calls are safe and return the same future. The future completes
  /// after current subscribers process the done event; paused subscriptions
  /// can delay completion.
  Future<void> dispose() => _controller.close();
}
