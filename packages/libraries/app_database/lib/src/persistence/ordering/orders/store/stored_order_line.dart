/// Provider-neutral persisted Ordering line snapshot.
final class const StoredOrderLine({
  /// External Catalog product reference without a cross-context foreign key.
  required final int catalogProductId,

  /// Product title copied at the Catalog revision used by the order.
  required final String productTitleSnapshot,

  /// Unit price in minor currency units.
  required final int unitPriceMinorUnits,

  /// Canonical currency code of this line.
  required final String currencyCode,

  /// Positive ordered quantity.
  required final int quantity,

  /// Catalog revision represented by this snapshot.
  required final int catalogRevision,
}) {
  /// Creates an immutable raw persistence record.
  this;
}
