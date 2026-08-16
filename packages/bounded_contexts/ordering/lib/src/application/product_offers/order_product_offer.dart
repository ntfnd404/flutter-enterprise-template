import 'package:ordering/src/domain/order/value_objects/catalog_offer_revision.dart';
import 'package:ordering/src/domain/order/value_objects/catalog_product_reference.dart';
import 'package:ordering/src/domain/order/value_objects/order_currency.dart';
import 'package:ordering/src/domain/order/value_objects/order_product_title.dart';
import 'package:ordering/src/domain/order/value_objects/order_unit_price.dart';

/// Immutable Ordering-owned snapshot translated from an upstream product source.
final class const OrderProductOffer({
  /// Product reference requested by Ordering.
  required final CatalogProductReference product,

  /// Ordering-owned title snapshot.
  required final OrderProductTitle title,

  /// Ordering-owned positive unit price.
  required final OrderUnitPrice unitPrice,

  /// Ordering-owned concrete currency.
  required final OrderCurrency currency,

  /// Upstream version represented by the offer.
  required final CatalogOfferRevision catalogRevision,
});
