import 'package:app_database/src/application_database.dart';
import 'package:drift/drift.dart';

part 'catalog_items_dao.g.dart';

/// Internal Drift DAO for the Catalog items persistence cluster.
@DriftAccessor(include: <String>{'../tables/catalog_items.drift'})
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

  /// Inserts a caller-validated canonical title.
  Future<int> insertItem(String title) => into(
    catalogItems,
  ).insert(CatalogItemsCompanion.insert(title: title));

  /// Changes completion state.
  Future<int> setItemCompleted({
    required int id,
    required bool isCompleted,
  }) => (update(catalogItems)..where((table) => table.id.equals(id))).write(
    CatalogItemsCompanion(
      isCompleted: Value<int>(isCompleted ? 1 : 0),
    ),
  );

  /// Deletes one stored item.
  Future<int> deleteItem(int id) =>
      (delete(catalogItems)..where((table) => table.id.equals(id))).go();
}
