import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/contexts/catalog/categories/store/catalog_categories_store.dart';
import 'package:app_database/src/contexts/catalog/categories/store/drift_catalog_categories_store.dart';
import 'package:app_database/src/contexts/catalog/items/store/catalog_items_store.dart';
import 'package:app_database/src/contexts/catalog/items/store/drift_catalog_items_store.dart';

/// Borrowed persistence stores owned by the Catalog context boundary.
///
/// The bundle is immutable and lifecycle-free. The application database
/// module remains the owner of the physical connection.
final class CatalogDatabaseStores {
  CatalogDatabaseStores._({
    required this.items,
    required this.categories,
  });

  /// Catalog item persistence.
  final CatalogItemsStore items;

  /// Catalog category persistence.
  final CatalogCategoriesStore categories;
}

/// Creates the Catalog store views over an initialized [database].
///
/// This package-internal assembly is synchronous and performs no I/O.
CatalogDatabaseStores createCatalogDatabaseStores(
  ApplicationDatabase database,
) => CatalogDatabaseStores._(
  items: DriftCatalogItemsStore(dao: database.catalogItemsDao),
  categories: DriftCatalogCategoriesStore(dao: database.catalogCategoriesDao),
);
