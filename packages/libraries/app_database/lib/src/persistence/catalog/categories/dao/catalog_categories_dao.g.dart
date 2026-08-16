// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_categories_dao.dart';

// ignore_for_file: type=lint
mixin _$CatalogCategoriesDaoMixin on DatabaseAccessor<ApplicationDatabase> {
  CatalogCategories get catalogCategories => attachedDatabase.catalogCategories;
  CatalogCategoriesDaoManager get managers => CatalogCategoriesDaoManager(this);
}

class CatalogCategoriesDaoManager {
  final _$CatalogCategoriesDaoMixin _db;
  CatalogCategoriesDaoManager(this._db);
  $CatalogCategoriesTableManager get catalogCategories =>
      $CatalogCategoriesTableManager(
        _db.attachedDatabase,
        _db.catalogCategories,
      );
}
