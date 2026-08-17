import 'package:catalog/catalog.dart';
import 'package:ordering/ordering.dart';

/// Immutable catalog of application-lifetime dependencies.
///
/// This catalog exposes only public bounded-context facades required by the
/// accepted app composition. Resource ownership, composition-only ports,
/// repositories, stores, modules, factories, widgets, and BLoCs do not belong
/// here.
final class const AppDependencies({
  /// Public application API of the catalog bounded context.
  required final CatalogFacade catalog,

  /// Public application API of the Ordering bounded context.
  required final OrderingFacade ordering,
});
