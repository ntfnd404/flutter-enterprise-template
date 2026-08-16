import 'package:catalog/src/application/catalog_facade.dart';
import 'package:catalog/src/application/product_offers/catalog_product_offer_reader.dart';

/// Lifecycle-free composition result exposing Catalog's independent ports.
///
/// App-owned composition immediately narrows [facade] to presentation and
/// [productOffers] to an authorized downstream integration. This holder is not
/// an application dependency and owns no persistence resource.
final class const CatalogApplication({
  /// Public application boundary intended for presentation.
  required final CatalogFacade facade,

  /// Product Offers Published Language query intended for downstream ACLs.
  required final CatalogProductOfferReader productOffers,
}) {
  /// Creates the immutable result of Catalog composition.
  this;
}
