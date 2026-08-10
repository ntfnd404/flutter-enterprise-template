// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_items_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogItemsDaoMixin on DatabaseAccessor<ApplicationDatabase> {
  CatalogItems get catalogItems => attachedDatabase.catalogItems;
  CatalogItemsDaoManager get managers => CatalogItemsDaoManager(this);
}

class CatalogItemsDaoManager {
  final _$CatalogItemsDaoMixin _db;
  CatalogItemsDaoManager(this._db);
  $CatalogItemsTableManager get catalogItems =>
      $CatalogItemsTableManager(_db.attachedDatabase, _db.catalogItems);
}
