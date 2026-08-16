/// Stable reason why a Catalog product-offer request was rejected.
enum CatalogOfferRequestFailure {
  /// Every requested product identity must be positive.
  invalidProductIdentifier,

  /// One request exceeded the documented batch limit.
  batchTooLarge,
}

/// A Catalog product-offer request violates its public input contract.
///
/// The rejected identifiers and other request values are intentionally not
/// retained by this privacy-safe failure.
final class CatalogOfferRequestException implements Exception {
  /// Creates a sanitized request failure.
  const CatalogOfferRequestException(this.failure);

  /// Stable rejected rule without the original request.
  final CatalogOfferRequestFailure failure;

  @override
  String toString() => 'CatalogOfferRequestException(${failure.name})';
}
