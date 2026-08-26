import 'package:catalog/src/domain/category/catalog_category.dart';
import 'package:catalog/src/domain/category/value_objects/catalog_category_name.dart';

/// Domain-owned persistence port for Catalog categories.
abstract interface class CatalogCategoryRepository {
  /// Observes authoritative categories in stable identifier order.
  Stream<List<CatalogCategory>> watchCategories();

  /// Loads one category, or returns `null` when it is absent.
  Future<CatalogCategory?> getCategory(int id);

  /// Stores a new category from a validated [name].
  Future<void> createCategory(CatalogCategoryName name);

  /// Changes category activation using last-write-wins semantics.
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  });
}
