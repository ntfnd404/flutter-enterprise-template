import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/category/value_objects/catalog_category_name.dart';

/// Immutable category entity used by Catalog publication policy.
final class const CatalogCategory._({
  /// Stable database-assigned identity.
  required final int id,

  /// Canonical category name.
  required final CatalogCategoryName name,

  /// Whether products may currently be published in this category.
  required final bool isActive,
}) {
  /// Reconstitutes a category after validating persisted values.
  factory CatalogCategory.fromValues({
    required int id,
    required String name,
    required bool isActive,
  }) {
    if (id <= 0) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogCategory._(
      id: id,
      name: CatalogCategoryName.fromStored(name),
      isActive: isActive,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatalogCategory && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
