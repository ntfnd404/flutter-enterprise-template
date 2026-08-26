import 'package:template/app/di/app_dependencies.dart';
import 'package:template/core/event_bus/app_event_bus.dart';

import '../../../support/noop_catalog_facade.dart';
import '../../../support/noop_ordering_facade.dart';

final class RoutingTestFixture {
  RoutingTestFixture() {
    dependencies = AppDependencies(
      catalog: const NoopCatalogFacade(),
      ordering: const NoopOrderingFacade(),
      eventPublisher: eventBus,
      eventSubscriber: eventBus,
    );
  }

  final eventBus = AppEventBus();
  late final AppDependencies dependencies;

  Future<void> dispose() => eventBus.dispose();
}
