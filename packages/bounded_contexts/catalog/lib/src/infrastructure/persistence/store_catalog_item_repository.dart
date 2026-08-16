import 'package:app_database/stores/catalog.dart';
import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/item/catalog_item.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_description.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_price.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_revision.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_title.dart';
import 'package:catalog/src/domain/repository/catalog_item_repository.dart';
import 'package:catalog/src/infrastructure/persistence/catalog_persistence_failure_mapper.dart';

/// Catalog item repository backed by a borrowed application-database store.
final class StoreCatalogItemRepository implements CatalogItemRepository {
  /// Creates the adapter over the narrow [store].
  const StoreCatalogItemRepository(this._store);

  final CatalogItemsStore _store;

  @override
  Stream<List<CatalogItem>> watchItems() async* {
    try {
      await for (final records in _store.watchItems()) {
        yield List<CatalogItem>.unmodifiable(records.map(_mapItem));
      }
    } on CatalogStoreException catch (_, stackTrace) {
      throwCatalogPersistence(stackTrace);
    }
  }

  @override
  Future<CatalogItem> getItem(int id) async {
    _validateIdentifier(id);
    final record = await guardCatalogPersistence(() => _store.getItem(id));
    if (record == null) {
      throw const CatalogItemNotFoundException();
    }

    return _mapItem(record);
  }

  @override
  Future<List<CatalogItem>> findItemsByIds(Set<int> ids) async {
    final records = await guardCatalogPersistence(
      () => _store.findItemsByIds(ids),
    );

    return List<CatalogItem>.unmodifiable(records.map(_mapItem));
  }

  @override
  Future<void> createDraft({
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) => guardCatalogPersistence(
    () => _store.insertItem(
      title: title.value,
      description: description.value,
      priceMinorUnits: price.minorUnits,
      currencyCode: price.currencyCode,
      categoryId: categoryId,
    ),
  );

  @override
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) async {
    _validateIdentifier(id);
    final changed = await guardCatalogPersistence(
      () => _store.updateDraft(
        id: id,
        expectedRevision: expectedRevision.value,
        title: title.value,
        description: description.value,
        priceMinorUnits: price.minorUnits,
        currencyCode: price.currencyCode,
        categoryId: categoryId,
      ),
    );
    _requireChanged(changed);
  }

  @override
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int categoryId,
  }) async {
    _validateIdentifier(id);
    _validateCategoryIdentifier(categoryId);
    final changed = await guardCatalogPersistence(
      () => _store.updatePublishedOffer(
        id: id,
        expectedRevision: expectedRevision.value,
        title: title.value,
        description: description.value,
        priceMinorUnits: price.minorUnits,
        currencyCode: price.currencyCode,
        categoryId: categoryId,
      ),
    );
    _requireChanged(changed);
  }

  @override
  Future<void> publishDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required int requiredActiveCategoryId,
  }) async {
    _validateIdentifier(id);
    _validateCategoryIdentifier(requiredActiveCategoryId);
    final changed = await guardCatalogPersistence(
      () => _store.publishDraft(
        id: id,
        expectedRevision: expectedRevision.value,
        requiredActiveCategoryId: requiredActiveCategoryId,
      ),
    );
    _requireChanged(changed);
  }

  @override
  Future<void> archivePublished({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    _validateIdentifier(id);
    final changed = await guardCatalogPersistence(
      () => _store.archivePublished(
        id: id,
        expectedRevision: expectedRevision.value,
      ),
    );
    _requireChanged(changed);
  }

  @override
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    _validateIdentifier(id);
    final changed = await guardCatalogPersistence(
      () => _store.deleteDraft(
        id: id,
        expectedRevision: expectedRevision.value,
      ),
    );
    _requireChanged(changed);
  }

  CatalogItem _mapItem(StoredCatalogItem record) => CatalogItem.fromValues(
    id: record.id,
    title: record.title,
    description: record.description,
    priceMinorUnits: record.priceMinorUnits,
    currencyCode: record.currencyCode,
    statusValue: record.statusValue,
    categoryId: record.categoryId,
    revision: record.revision,
  );

  void _validateIdentifier(int id) {
    if (id <= 0) {
      throw const CatalogItemNotFoundException();
    }
  }

  void _validateCategoryIdentifier(int id) {
    if (id <= 0) {
      throw const CatalogCategoryNotFoundException();
    }
  }

  void _requireChanged(int changed) {
    if (changed == 0) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.concurrentStateChange,
      );
    }
  }
}
