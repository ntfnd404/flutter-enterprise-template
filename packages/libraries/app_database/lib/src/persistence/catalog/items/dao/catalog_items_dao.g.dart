// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_items_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogItemsDaoMixin on DatabaseAccessor<ApplicationDatabase> {
  CatalogCategories get catalogCategories => attachedDatabase.catalogCategories;
  CatalogItems get catalogItems => attachedDatabase.catalogItems;
  CatalogItemsDaoManager get managers => CatalogItemsDaoManager(this);
}

class CatalogItemsDaoManager {
  final _$CatalogItemsDaoMixin _db;
  CatalogItemsDaoManager(this._db);
  $CatalogCategoriesTableManager get catalogCategories =>
      $CatalogCategoriesTableManager(
        _db.attachedDatabase,
        _db.catalogCategories,
      );
  $CatalogItemsTableManager get catalogItems =>
      $CatalogItemsTableManager(_db.attachedDatabase, _db.catalogItems);
}
