/// Immutable provider-neutral Catalog category persistence record.
final class StoredCatalogCategory {
  /// Creates a raw stored category record.
  const StoredCatalogCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });

  /// Database-assigned identifier.
  final int id;

  /// Raw persisted name validated by the owning context.
  final String name;

  /// Whether the category currently accepts publication and offer changes.
  final bool isActive;
}
