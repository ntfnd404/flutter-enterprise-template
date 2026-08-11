/// Immutable provider-neutral Catalog category persistence record.
final class StoredCatalogCategory {
  /// Creates a raw stored category record.
  const StoredCatalogCategory({
    required this.id,
    required this.name,
    required this.activeValue,
  });

  /// Database-assigned identifier.
  final int id;

  /// Raw persisted name validated by the owning context.
  final String name;

  /// Raw persisted activation flag.
  final int activeValue;
}
