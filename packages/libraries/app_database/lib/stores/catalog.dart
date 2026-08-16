/// Catalog-specific persistence contract backed by the application database.
///
/// Catalog infrastructure may import this narrow entrypoint. It does not
/// expose Drift, generated rows, DAOs, or the physical application database.
///
/// {@category database-architecture}
library;

export '../src/persistence/catalog/catalog_database_stores.dart'
    show CatalogDatabaseStores;
export '../src/persistence/catalog/categories/store/catalog_categories_store.dart';
export '../src/persistence/catalog/categories/store/stored_catalog_category.dart';
export '../src/persistence/catalog/failures/catalog_store_exception.dart';
export '../src/persistence/catalog/items/store/catalog_items_store.dart';
export '../src/persistence/catalog/items/store/stored_catalog_item.dart';
