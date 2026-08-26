import 'package:catalog/catalog.dart';
import 'package:ordering/ordering.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';
import 'package:template/core/event_bus/app_event_subscriber.dart';

/// Immutable catalog of application-lifetime dependencies.
///
/// This catalog exposes only public bounded-context facades and non-owning
/// application roles required by presentation. Resource ownership,
/// composition-only ports, repositories, stores, modules, factories, widgets,
/// and BLoCs do not belong here.
final class const AppDependencies({
  /// Public application API of the catalog bounded context.
  required final CatalogFacade catalog,

  /// Public application API of the Ordering bounded context.
  required final OrderingFacade ordering,

  /// Non-owning role for best-effort cross-feature publication.
  required final AppEventPublisher eventPublisher,

  /// Non-owning role for best-effort cross-feature observation.
  required final AppEventSubscriber eventSubscriber,
});
