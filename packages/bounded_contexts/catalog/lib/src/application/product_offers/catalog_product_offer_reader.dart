import 'package:catalog/src/application/product_offers/catalog_product_offer_snapshot.dart';

/// Read-only Product Offers capability for downstream bounded contexts.
///
/// The Context Map classifies this inter-context contract as a Published
/// Language. Consumers translate its snapshots into their own model.
abstract interface class CatalogProductOfferReader {
  /// Largest product set accepted by one application-level batch query.
  static const int maxBatchSize = 100;

  /// Returns immutable snapshots for existing published products in
  /// [productIds].
  ///
  /// The request is copied before asynchronous work starts. IDs must be
  /// positive and the batch must not exceed [maxBatchSize]. Draft, archived,
  /// and missing products are omitted from a successful result; their absence
  /// is not a query failure. Map keys have stable ascending product-ID order.
  /// An empty request returns an immutable empty map without reading
  /// persistence.
  ///
  /// Invalid batches throw `CatalogOfferRequestException`. Temporary
  /// capability-wide unavailability throws `CatalogOfferUnavailableException`.
  /// The reader does not retry or cache results.
  Future<Map<int, CatalogProductOfferSnapshot>> findPublishedOffers(
    Set<int> productIds,
  );
}
