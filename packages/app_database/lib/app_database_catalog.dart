/// Catalog-specific persistence contract backed by the application database.
///
/// The catalog data layer may import this narrow entrypoint. It does not expose
/// Drift, generated rows, DAOs, or the physical application database.
///
/// {@category database-architecture}
library;

export 'src/contexts/catalog/items/store/catalog_items_store.dart';
export 'src/contexts/catalog/items/store/catalog_items_store_exception.dart';
export 'src/contexts/catalog/items/store/stored_catalog_item.dart';
