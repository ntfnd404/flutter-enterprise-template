import 'package:ordering/src/application/product_offers/order_product_offer.dart';
import 'package:ordering/src/domain/order/value_objects/catalog_product_reference.dart';

/// Application port for loading current product offers in one batch.
abstract interface class ProductOfferProvider {
  /// Loads a complete map for [products] or throws an Ordering-owned failure.
  Future<Map<CatalogProductReference, OrderProductOffer>> loadOffers(
    Set<CatalogProductReference> products,
  );
}
