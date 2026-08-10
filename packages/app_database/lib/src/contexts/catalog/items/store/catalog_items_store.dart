import 'package:app_database/src/contexts/catalog/items/store/stored_catalog_item.dart';

/// Narrow Catalog items persistence contract exposed across package boundaries.
///
/// Implementations keep Drift rows and DAOs private and return
/// provider-neutral records.
abstract interface class CatalogItemsStore {
  /// Watches all stored Catalog items in stable insertion order.
  Stream<List<StoredCatalogItem>> watchItems();

  /// Inserts a caller-validated canonical title and returns its generated ID.
  Future<int> insertItem(String title);

  /// Updates completion state and returns the number of affected rows.
  Future<int> setItemCompleted({
    required int id,
    required bool isCompleted,
  });

  /// Deletes an item and returns the number of affected rows.
  Future<int> deleteItem(int id);
}
