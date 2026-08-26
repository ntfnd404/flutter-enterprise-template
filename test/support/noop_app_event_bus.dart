import 'package:template/core/event_bus/app_event.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';
import 'package:template/core/event_bus/app_event_subscriber.dart';

/// Lifecycle-free event roles used when a test does not exercise delivery.
final class NoopAppEventBus implements AppEventPublisher, AppEventSubscriber {
  /// Creates borrowed no-op roles.
  const NoopAppEventBus();

  @override
  void emit(AppEvent event) {}

  @override
  Stream<T> on<T extends AppEvent>() => const Stream.empty();
}
