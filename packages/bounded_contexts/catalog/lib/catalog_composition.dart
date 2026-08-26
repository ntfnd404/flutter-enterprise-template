/// Application-only composition API of the catalog bounded context.
///
/// Only the application dependency graph imports this entrypoint in production.
/// Tests may compose the context directly. Features use `catalog.dart` and
/// cannot construct repositories or persistence adapters. The returned
/// composition view is narrowed immediately to Catalog's independent public
/// ports; it is not itself an application dependency.
library;

export 'src/composition/catalog_application.dart' show CatalogApplication;
export 'src/composition/catalog_factory.dart' show createCatalogApplication;
