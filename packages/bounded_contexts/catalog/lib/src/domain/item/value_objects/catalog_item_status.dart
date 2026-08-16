import 'package:catalog/src/domain/catalog_exception.dart';

/// Stable lifecycle state of a catalog product.
enum CatalogItemStatus(
  /// Explicit persistence value independent of enum declaration order.
  final int value,
) {
  /// Product data may still be incomplete and is not publicly available.
  draft(0),

  /// Product passed publication policy and is publicly available.
  published(1),

  /// Product was withdrawn after publication.
  archived(2);

  /// Parses a persisted value without using enum ordinal indices.
  static CatalogItemStatus fromStored(int value) => switch (value) {
    0 => draft,
    1 => published,
    2 => archived,
    _ => throw const CatalogDataIntegrityException(),
  };
}
