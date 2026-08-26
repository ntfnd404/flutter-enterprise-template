/// Immutable provider-neutral Catalog item persistence record.
///
/// This type is deliberately independent of generated Drift rows and of the
/// Catalog domain model. The Catalog repository owns the boundary mapping.
final class StoredCatalogItem {
  /// Creates a stored Catalog item record.
  const StoredCatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priceMinorUnits,
    required this.currencyCode,
    required this.statusValue,
    required this.categoryId,
    required this.revision,
  });

  /// Database-assigned identifier.
  final int id;

  /// Raw persisted title; the owning context validates it during rehydration.
  final String title;

  /// Raw persisted description validated by the owning context.
  final String description;

  /// Raw integer amount in minor currency units.
  final int priceMinorUnits;

  /// Raw persisted currency representation.
  final String currencyCode;

  /// Raw lifecycle representation parsed by the owning context.
  final int statusValue;

  /// Raw optional category identity.
  final int? categoryId;

  /// Raw optimistic concurrency token.
  final int revision;
}
