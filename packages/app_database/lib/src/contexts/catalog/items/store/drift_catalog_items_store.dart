import 'package:app_database/src/contexts/catalog/items/dao/catalog_items_dao.dart';
import 'package:app_database/src/contexts/catalog/items/store/catalog_items_sqlite_failure.dart';
import 'package:app_database/src/contexts/catalog/items/store/catalog_items_store.dart';
import 'package:app_database/src/contexts/catalog/items/store/stored_catalog_item.dart';
import 'package:drift/isolate.dart';
import 'package:sqlite3/common.dart';

/// Drift-backed implementation of the narrow Catalog items store.
final class DriftCatalogItemsStore implements CatalogItemsStore {
  /// Creates a store over the internal DAO.
  const DriftCatalogItemsStore({required this._dao});

  final CatalogItemsDao _dao;

  @override
  Stream<List<StoredCatalogItem>> watchItems() async* {
    try {
      await for (final records in _dao.watchItems()) {
        yield List<StoredCatalogItem>.unmodifiable(
          records.map(
            (record) => StoredCatalogItem(
              id: record.id,
              title: record.title,
              completionValue: record.isCompleted,
            ),
          ),
        );
      }
    } on SqliteException catch (error, stackTrace) {
      throwCatalogItemsSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwCatalogItemsSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<int> insertItem(String title) =>
      _guardPersistence(() => _dao.insertItem(title));

  @override
  Future<int> setItemCompleted({
    required int id,
    required bool isCompleted,
  }) => _guardPersistence(
    () => _dao.setItemCompleted(id: id, isCompleted: isCompleted),
  );

  @override
  Future<int> deleteItem(int id) =>
      _guardPersistence(() => _dao.deleteItem(id));

  Future<T> _guardPersistence<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on SqliteException catch (error, stackTrace) {
      throwCatalogItemsSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwCatalogItemsSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }
}
