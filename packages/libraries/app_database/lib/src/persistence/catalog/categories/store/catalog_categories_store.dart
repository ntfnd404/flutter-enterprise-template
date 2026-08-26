import 'package:app_database/src/persistence/catalog/categories/store/stored_catalog_category.dart';

/// Narrow Catalog categories persistence contract.
abstract interface class CatalogCategoriesStore {
  /// Watches all raw categories in stable database-assigned ID order.
  Stream<List<StoredCatalogCategory>> watchCategories();

  /// Loads one raw category, or `null` when [id] is absent.
  Future<StoredCatalogCategory?> getCategory(int id);

  /// Inserts a caller-validated name and returns its generated ID.
  Future<int> insertCategory(String name);

  /// Updates activation state and returns the number of affected rows.
  Future<int> setCategoryActive({
    required int id,
    required bool isActive,
  });
}
