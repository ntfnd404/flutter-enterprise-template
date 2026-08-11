import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/contexts/catalog/categories/dao/catalog_categories_dao.dart';
import 'package:app_database/src/contexts/catalog/categories/store/catalog_categories_store.dart';
import 'package:app_database/src/contexts/catalog/categories/store/stored_catalog_category.dart';
import 'package:app_database/src/contexts/catalog/failures/catalog_sqlite_failure.dart';
import 'package:drift/isolate.dart';
import 'package:sqlite3/common.dart';

/// Drift-backed implementation of the narrow Catalog categories store.
final class DriftCatalogCategoriesStore implements CatalogCategoriesStore {
  /// Creates a store over the internal DAO.
  const DriftCatalogCategoriesStore({required this._dao});

  final CatalogCategoriesDao _dao;

  @override
  Stream<List<StoredCatalogCategory>> watchCategories() async* {
    try {
      await for (final records in _dao.watchCategories()) {
        yield List<StoredCatalogCategory>.unmodifiable(
          records.map(_mapRecord),
        );
      }
    } on SqliteException catch (error, stackTrace) {
      throwCatalogSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwCatalogSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<StoredCatalogCategory?> getCategory(int id) =>
      _guardPersistence(() async {
        final record = await _dao.getCategory(id);
        return record == null ? null : _mapRecord(record);
      });

  @override
  Future<int> insertCategory(String name) =>
      _guardPersistence(() => _dao.insertCategory(name));

  @override
  Future<int> setCategoryActive({
    required int id,
    required bool isActive,
  }) => _guardPersistence(
    () => _dao.setCategoryActive(id: id, isActive: isActive),
  );

  Future<T> _guardPersistence<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on SqliteException catch (error, stackTrace) {
      throwCatalogSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwCatalogSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }

  StoredCatalogCategory _mapRecord(CatalogCategory record) =>
      StoredCatalogCategory(
        id: record.id,
        name: record.name,
        activeValue: record.isActive,
      );
}
