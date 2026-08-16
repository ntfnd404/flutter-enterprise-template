import 'package:app_database/stores/catalog.dart';
import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/category/catalog_category.dart';
import 'package:catalog/src/domain/category/value_objects/catalog_category_name.dart';
import 'package:catalog/src/domain/repository/catalog_category_repository.dart';
import 'package:catalog/src/infrastructure/persistence/catalog_persistence_failure_mapper.dart';

/// Catalog category repository backed by a borrowed database store.
final class StoreCatalogCategoryRepository
    implements CatalogCategoryRepository {
  /// Creates the adapter over the narrow [store].
  const StoreCatalogCategoryRepository(this._store);

  final CatalogCategoriesStore _store;

  @override
  Stream<List<CatalogCategory>> watchCategories() async* {
    try {
      await for (final records in _store.watchCategories()) {
        yield List<CatalogCategory>.unmodifiable(records.map(_mapCategory));
      }
    } on CatalogStoreException catch (_, stackTrace) {
      throwCatalogPersistence(stackTrace);
    }
  }

  @override
  Future<CatalogCategory?> getCategory(int id) async {
    _validateIdentifier(id);
    final record = await guardCatalogPersistence(
      () => _store.getCategory(id),
    );

    return record == null ? null : _mapCategory(record);
  }

  @override
  Future<void> createCategory(CatalogCategoryName name) =>
      guardCatalogPersistence(() => _store.insertCategory(name.value));

  @override
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    _validateIdentifier(id);
    final changed = await guardCatalogPersistence(
      () => _store.setCategoryActive(id: id, isActive: isActive),
    );
    if (changed == 0) {
      throw const CatalogCategoryNotFoundException();
    }
  }

  CatalogCategory _mapCategory(StoredCatalogCategory record) =>
      CatalogCategory.fromValues(
        id: record.id,
        name: record.name,
        isActive: record.isActive,
      );

  void _validateIdentifier(int id) {
    if (id <= 0) {
      throw const CatalogCategoryNotFoundException();
    }
  }
}
