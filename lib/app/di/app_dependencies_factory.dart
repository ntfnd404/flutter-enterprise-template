import 'package:app_database/app_database_composition.dart';
import 'package:catalog/catalog_composition.dart';
import 'package:ordering/ordering_composition.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/di/app_resource_registrar.dart';
import 'package:template/app/di/modules/database/app_database_configuration_factory.dart';
import 'package:template/app/environment/storage/app_storage_configuration.dart';
import 'package:template/core/event_bus/app_event_bus.dart';

/// Builds production dependencies for one application graph.
///
/// Constructs the shared database owner and bounded-context facades in explicit
/// dependency order. The database module is registered before initialization;
/// context repositories and facades borrow its narrow stores and own no
/// lifecycle.
///
/// The supplied [resources] accepts registration only. This function neither
/// seals nor disposes the graph's private resource ledger.
///
/// Before adding an integration here, consult the Dependency lifecycle topic
/// for concrete composition and ownership examples. The Application
/// architecture topic defines the governing dependency boundaries.
///
/// {@category dependency-lifecycle}
/// {@category application-architecture}
Future<AppDependencies> buildAppDependencies(
  AppResourceRegistrar resources, {
  required AppStorageConfiguration storageConfiguration,
}) async {
  // Register the bus first so LIFO teardown closes it after every feature and
  // infrastructure resource. Downstream receives only borrowed roles.
  final eventBus = resources.register(
    AppEventBus(),
    (resource) => resource.dispose(),
  );

  // The shared physical database is infrastructure, not a business context.
  // Register it before opening so rollback owns a connection that fails while
  // applying schema work. Contexts receive narrow borrowed stores; they never
  // receive or close the Drift database itself.
  final databaseConfiguration = await createAppDatabaseConfiguration(
    storageNamespace: storageConfiguration.namespace,
  );
  final databaseModule = resources.register(
    createAppDatabaseModule(configuration: databaseConfiguration),
    (module) => module.dispose(),
  );
  await databaseModule.initialize();
  final databaseStores = databaseModule.stores;
  final catalogStores = databaseStores.catalog;

  // Catalog owns its domain repository and application facade. Its repository
  // adapts the borrowed Catalog stores; it does not own a second database
  // module.
  final catalogApplication = createCatalogApplication(
    itemsStore: catalogStores.items,
    categoriesStore: catalogStores.categories,
  );
  final ordering = createOrderingFacade(
    store: databaseStores.ordering.orders,
    productOffers: CatalogProductOfferAdapter(catalogApplication.productOffers),
    utcNow: () => DateTime.now().toUtc(),
  );

  return AppDependencies(
    catalog: catalogApplication.facade,
    ordering: ordering,
    eventPublisher: eventBus,
    eventSubscriber: eventBus,
  );
}
