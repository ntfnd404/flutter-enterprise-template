import 'package:catalog/catalog.dart';
import 'package:ordering/ordering.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';
import 'package:template/core/event_bus/app_event_subscriber.dart';

/// Immutable catalog of application-lifetime dependencies.
///
/// This catalog exposes only consumed bounded-context facades and borrowed
/// application roles required by the accepted app composition. Resource
/// ownership, composition-only ports, repositories, stores, modules, factories,
/// widgets, and BLoCs do not belong here.
final class const AppDependencies({
  /// Public application API of the catalog bounded context.
  required final CatalogFacade catalog,

  /// Public application API of the Ordering bounded context.
  required final OrderingFacade ordering,

  /// Borrowed role for best-effort cross-feature publication.
  required final AppEventPublisher eventPublisher,

  /// Borrowed role for best-effort cross-feature observation.
  required final AppEventSubscriber eventSubscriber,
});
