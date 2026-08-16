/// Immutable provider-neutral Catalog category persistence record.
final class const StoredCatalogCategory({
  /// Database-assigned identifier.
  required final int id,

  /// Raw persisted name validated by the owning context.
  required final String name,

  /// Whether the category currently accepts publication and offer changes.
  required final bool isActive,
}) {
  /// Creates a raw stored category record.
  this;
}
