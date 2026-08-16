import 'package:app_database/src/application_database.dart';
import 'package:drift/drift.dart';

part 'catalog_categories_dao.g.dart';

/// Internal Drift DAO for the Catalog categories persistence cluster.
@DriftAccessor(include: <String>{'../tables/catalog_categories.drift'})
final class CatalogCategoriesDao extends DatabaseAccessor<ApplicationDatabase>
    with _$CatalogCategoriesDaoMixin {
  /// Attaches Catalog category queries to the application database.
  CatalogCategoriesDao(super.attachedDatabase);

  /// Watches categories in stable database-assigned ID order.
  Stream<List<CatalogCategory>> watchCategories() =>
      (select(catalogCategories)
            ..orderBy(<OrderingTerm Function(CatalogCategories)>[
              (table) => OrderingTerm.asc(table.id),
            ]))
          .watch();

  /// Loads one generated row by its stable identifier.
  Future<CatalogCategory?> getCategory(int id) => (select(
    catalogCategories,
  )..where((table) => table.id.equals(id))).getSingleOrNull();

  /// Inserts a caller-validated canonical category name.
  Future<int> insertCategory(String name) => into(
    catalogCategories,
  ).insert(CatalogCategoriesCompanion.insert(name: name));

  /// Changes category activation and returns the affected row count.
  Future<int> setCategoryActive({required int id, required bool isActive}) =>
      (update(catalogCategories)..where((table) => table.id.equals(id))).write(
        CatalogCategoriesCompanion(isActive: Value<bool>(isActive)),
      );
}
