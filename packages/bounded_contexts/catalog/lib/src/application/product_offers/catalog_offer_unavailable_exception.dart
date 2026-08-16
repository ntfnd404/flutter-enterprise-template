/// The Catalog product-offer query capability is temporarily unavailable.
///
/// This describes availability of the query as a whole. It never means that a
/// particular product is absent: missing, draft, and archived products are
/// omitted from an otherwise successful result.
final class CatalogOfferUnavailableException implements Exception {
  /// Creates a sanitized capability-availability failure.
  const CatalogOfferUnavailableException();

  @override
  String toString() =>
      'CatalogOfferUnavailableException(catalog offers unavailable)';
}
