/// Immutable point-in-time product-offer snapshot published by Catalog.
///
/// This is a Published Language DTO, not a Catalog entity or value object. It
/// exposes only provider-neutral data authorized for downstream bounded
/// contexts. A downstream Anti-Corruption Layer must translate the snapshot
/// into that context's own model instead of retaining Catalog types. It is not
/// a domain event, integration event, persisted message, or downstream domain
/// object.
final class const CatalogProductOfferSnapshot({
  /// Stable Catalog product identity.
  required final int productId,

  /// Product title at [catalogRevision].
  required final String title,

  /// Unit price at [catalogRevision], expressed in minor currency units.
  required final int priceMinorUnits,

  /// Canonical three-letter currency code.
  required final String currencyCode,

  /// Catalog item revision represented by this snapshot.
  ///
  /// This value supports traceability. It is not a contract version, lease,
  /// cross-context optimistic lock, or freshness guarantee at downstream
  /// commit time.
  required final int catalogRevision,
}) {
  /// Creates a snapshot produced by the Catalog application boundary.
  this;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogProductOfferSnapshot &&
          productId == other.productId &&
          title == other.title &&
          priceMinorUnits == other.priceMinorUnits &&
          currencyCode == other.currencyCode &&
          catalogRevision == other.catalogRevision;

  @override
  int get hashCode => Object.hash(
    productId,
    title,
    priceMinorUnits,
    currencyCode,
    catalogRevision,
  );
}
