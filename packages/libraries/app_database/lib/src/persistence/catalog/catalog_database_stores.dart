import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/catalog/categories/store/catalog_categories_store.dart';
import 'package:app_database/src/persistence/catalog/categories/store/drift_catalog_categories_store.dart';
import 'package:app_database/src/persistence/catalog/items/store/catalog_items_store.dart';
import 'package:app_database/src/persistence/catalog/items/store/drift_catalog_items_store.dart';

/// Borrowed persistence stores owned by the Catalog context boundary.
///
/// The bundle is immutable and lifecycle-free. The application database
/// module remains the owner of the physical connection.
final class CatalogDatabaseStores._({
  /// Catalog item persistence.
  required final CatalogItemsStore items,

  /// Catalog category persistence.
  required final CatalogCategoriesStore categories,
});

/// Creates the Catalog store views over an initialized [database].
///
/// This package-internal assembly is synchronous and performs no I/O.
CatalogDatabaseStores createCatalogDatabaseStores(
  ApplicationDatabase database,
) => CatalogDatabaseStores._(
  items: DriftCatalogItemsStore(dao: database.catalogItemsDao),
  categories: DriftCatalogCategoriesStore(dao: database.catalogCategoriesDao),
);
