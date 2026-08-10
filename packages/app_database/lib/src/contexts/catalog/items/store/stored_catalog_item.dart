/// Immutable provider-neutral Catalog item persistence record.
///
/// This type is deliberately independent of generated Drift rows and of the
/// Catalog domain model. The Catalog repository owns the boundary mapping.
final class StoredCatalogItem {
  /// Creates a stored Catalog item record.
  const StoredCatalogItem({
    required this.id,
    required this.title,
    required this.completionValue,
  });

  /// Database-assigned identifier.
  final int id;

  /// Raw persisted title; the owning context validates it during rehydration.
  final String title;

  /// Raw persisted flag; the owning context accepts only `0` and `1`.
  final int completionValue;
}
