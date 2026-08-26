import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/catalog/failures/catalog_sqlite_failure.dart';
import 'package:app_database/src/persistence/catalog/items/dao/catalog_items_dao.dart';
import 'package:app_database/src/persistence/catalog/items/store/catalog_items_store.dart';
import 'package:app_database/src/persistence/catalog/items/store/stored_catalog_item.dart';
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
  Future<StoredCatalogItem?> getItem(int id) => _guardPersistence(() async {
    final record = await _dao.getItem(id);
    return record == null ? null : _mapRecord(record);
  });

  @override
  Future<List<StoredCatalogItem>> findItemsByIds(Set<int> ids) {
    final copiedIds = Set<int>.unmodifiable(ids);
    if (copiedIds.isEmpty) {
      return Future<List<StoredCatalogItem>>.value(
        const <StoredCatalogItem>[],
      );
    }

    return _guardPersistence(() async {
      final records = await _dao.findItemsByIds(copiedIds);
      return List<StoredCatalogItem>.unmodifiable(records.map(_mapRecord));
    });
  }

  @override
  Future<int> insertItem({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) => _guardPersistence(
    () => _dao.insertItem(
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ),
  );

  @override
  Future<int> updateDraft({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) => _guardPersistence(
    () => _dao.updateDraft(
      id: id,
      expectedRevision: expectedRevision,
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ),
  );

  @override
  Future<int> updatePublishedOffer({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  }) => _guardPersistence(
    () => _dao.updatePublishedOffer(
      id: id,
      expectedRevision: expectedRevision,
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ),
  );

  @override
  Future<int> publishDraft({
    required int id,
    required int expectedRevision,
    required int requiredActiveCategoryId,
  }) => _guardPersistence(
    () => _dao.publishDraft(
      id: id,
      expectedRevision: expectedRevision,
      requiredActiveCategoryId: requiredActiveCategoryId,
    ),
  );

  @override
  Future<int> archivePublished({
    required int id,
    required int expectedRevision,
  }) => _guardPersistence(
    () => _dao.archivePublished(
      id: id,
      expectedRevision: expectedRevision,
    ),
  );

  @override
  Future<int> deleteDraft({
    required int id,
    required int expectedRevision,
  }) => _guardPersistence(
    () => _dao.deleteDraft(id: id, expectedRevision: expectedRevision),
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

  StoredCatalogItem _mapRecord(CatalogItem record) => StoredCatalogItem(
    id: record.id,
    title: record.title,
    description: record.description,
    priceMinorUnits: record.priceMinorUnits,
    currencyCode: record.currencyCode,
    statusValue: record.statusValue,
    categoryId: record.categoryId,
    revision: record.revision,
  );
}
