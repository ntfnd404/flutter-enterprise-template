import 'package:app_database/src/application_database.dart';
import 'package:drift/drift.dart';

part 'catalog_items_dao.g.dart';

const _draftStatusValue = 0;
const _publishedStatusValue = 1;
const _archivedStatusValue = 2;

/// Internal Drift DAO for the Catalog items persistence cluster.
@DriftAccessor(
  include: <String>{
    '../../categories/tables/catalog_categories.drift',
    '../tables/catalog_items.drift',
  },
)
final class CatalogItemsDao extends DatabaseAccessor<ApplicationDatabase>
    with _$CatalogItemsDaoMixin {
  /// Attaches Catalog item queries to the application database.
  CatalogItemsDao(super.attachedDatabase);

  /// Watches generated rows in stable insertion order.
  Stream<List<CatalogItem>> watchItems() =>
      (select(catalogItems)..orderBy(<OrderingTerm Function(CatalogItems)>[
            (table) => OrderingTerm.asc(table.id),
          ]))
          .watch();

  /// Loads one generated row by its stable identifier.
  Future<CatalogItem?> getItem(int id) => (select(
    catalogItems,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  /// Loads existing generated rows for [ids] in stable identifier order.
  Future<List<CatalogItem>> findItemsByIds(Set<int> ids) {
    if (ids.isEmpty) {
      return Future<List<CatalogItem>>.value(const <CatalogItem>[]);
    }

    return (select(catalogItems)
          ..where((table) => table.id.isIn(ids))
          ..orderBy(<OrderingTerm Function(CatalogItems)>[
            (table) => OrderingTerm.asc(table.id),
          ]))
        .get();
  }

  /// Inserts a caller-validated product draft.
  Future<int> insertItem({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) => into(catalogItems).insert(
    CatalogItemsCompanion.insert(
      title: title,
      description: Value<String>(description),
      priceMinorUnits: Value<int>(priceMinorUnits),
      currencyCode: Value<String>(currencyCode),
      categoryId: Value<int?>(categoryId),
    ),
  );

  /// Replaces product details only while the item is still a draft.
  Future<int> updateDraft({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) =>
      (update(catalogItems)..where(
            (table) =>
                table.id.equals(id) &
                table.statusValue.equals(_draftStatusValue) &
                table.revision.equals(expectedRevision),
          ))
          .write(
            CatalogItemsCompanion.custom(
              title: Variable<String>(title),
              description: Variable<String>(description),
              priceMinorUnits: Variable<int>(priceMinorUnits),
              currencyCode: Variable<String>(currencyCode),
              categoryId: Variable<int>(categoryId),
              revision: catalogItems.revision + const Constant<int>(1),
            ),
          );

  /// Replaces a published offer if its category is still active.
  Future<int> updatePublishedOffer({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  }) {
    final activeCategory = select(catalogCategories)
      ..where(
        (category) =>
            category.id.equals(categoryId) & category.isActive.equals(1),
      );

    return (update(catalogItems)..where(
          (table) =>
              table.id.equals(id) &
              table.statusValue.equals(_publishedStatusValue) &
              table.revision.equals(expectedRevision) &
              existsQuery(activeCategory),
        ))
        .write(
          CatalogItemsCompanion.custom(
            title: Variable<String>(title),
            description: Variable<String>(description),
            priceMinorUnits: Variable<int>(priceMinorUnits),
            currencyCode: Variable<String>(currencyCode),
            categoryId: Variable<int>(categoryId),
            revision: catalogItems.revision + const Constant<int>(1),
          ),
        );
  }

  /// Publishes a draft if its assigned category is still active.
  Future<int> publishDraft({
    required int id,
    required int expectedRevision,
    required int requiredActiveCategoryId,
  }) {
    final activeCategory = select(catalogCategories)
      ..where(
        (category) =>
            category.id.equals(requiredActiveCategoryId) &
            category.isActive.equals(1),
      );

    return (update(catalogItems)..where(
          (table) =>
              table.id.equals(id) &
              table.statusValue.equals(_draftStatusValue) &
              table.revision.equals(expectedRevision) &
              table.categoryId.equals(requiredActiveCategoryId) &
              existsQuery(activeCategory),
        ))
        .write(
          CatalogItemsCompanion.custom(
            statusValue: const Variable<int>(_publishedStatusValue),
            revision: catalogItems.revision + const Constant<int>(1),
          ),
        );
  }

  /// Archives an item only while it remains published at the expected revision.
  Future<int> archivePublished({
    required int id,
    required int expectedRevision,
  }) =>
      (update(catalogItems)..where(
            (table) =>
                table.id.equals(id) &
                table.statusValue.equals(_publishedStatusValue) &
                table.revision.equals(expectedRevision),
          ))
          .write(
            CatalogItemsCompanion.custom(
              statusValue: const Variable<int>(_archivedStatusValue),
              revision: catalogItems.revision + const Constant<int>(1),
            ),
          );

  /// Deletes one stored item.
  Future<int> deleteItem(int id) =>
      (delete(catalogItems)..where((table) => table.id.equals(id))).go();
}
