import 'package:app_database/src/persistence/catalog/items/store/stored_catalog_item.dart';

/// Narrow Catalog items persistence contract exposed across package boundaries.
///
/// Implementations keep Drift rows and DAOs private and return
/// provider-neutral records.
abstract interface class CatalogItemsStore {
  /// Watches all stored Catalog items in stable insertion order.
  Stream<List<StoredCatalogItem>> watchItems();

  /// Loads one raw record, or `null` when [id] is absent.
  Future<StoredCatalogItem?> getItem(int id);

  /// Loads existing records for [ids] in stable identifier order.
  ///
  /// Business status is intentionally not interpreted at this persistence
  /// boundary. An empty set returns an empty list without querying SQLite.
  Future<List<StoredCatalogItem>> findItemsByIds(Set<int> ids);

  /// Inserts a caller-validated draft and returns its generated ID.
  Future<int> insertItem({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  });

  /// Replaces draft details conditionally and returns affected row count.
  Future<int> updateDraft({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  });

  /// Replaces a published offer while its category remains active.
  Future<int> updatePublishedOffer({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  });

  /// Publishes a draft while its assigned category remains active.
  Future<int> publishDraft({
    required int id,
    required int expectedRevision,
    required int requiredActiveCategoryId,
  });

  /// Archives a published item conditionally and returns affected row count.
  Future<int> archivePublished({
    required int id,
    required int expectedRevision,
  });

  /// Deletes a draft at [expectedRevision] and returns affected row count.
  ///
  /// A missing item, a stale revision, or a non-draft lifecycle state returns
  /// zero. This persistence boundary does not interpret those domain reasons.
  Future<int> deleteDraft({
    required int id,
    required int expectedRevision,
  });
}
