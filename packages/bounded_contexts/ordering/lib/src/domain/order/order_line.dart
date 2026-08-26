import 'package:ordering/src/domain/order/value_objects/catalog_offer_revision.dart';
import 'package:ordering/src/domain/order/value_objects/catalog_product_reference.dart';
import 'package:ordering/src/domain/order/value_objects/order_currency.dart';
import 'package:ordering/src/domain/order/value_objects/order_line_quantity.dart';
import 'package:ordering/src/domain/order/value_objects/order_product_title.dart';
import 'package:ordering/src/domain/order/value_objects/order_unit_price.dart';

/// Immutable product snapshot owned by an Order aggregate.
final class const OrderLine._({
  /// External Catalog product reference.
  required final CatalogProductReference product,

  /// Product title at [catalogRevision].
  required final OrderProductTitle title,

  /// Positive unit price at [catalogRevision].
  required final OrderUnitPrice unitPrice,

  /// Currency shared by the aggregate.
  required final OrderCurrency currency,

  /// Positive ordered quantity.
  required final OrderLineQuantity quantity,

  /// Catalog item revision represented by this point-in-time snapshot.
  ///
  /// This is traceability data, not a freshness lease or cross-context lock.
  required final CatalogOfferRevision catalogRevision,
}) {
  /// Creates a line from already validated Ordering-owned offer values.
  factory OrderLine.fromOffer({
    required CatalogProductReference product,
    required OrderProductTitle title,
    required OrderUnitPrice unitPrice,
    required OrderCurrency currency,
    required OrderLineQuantity quantity,
    required CatalogOfferRevision catalogRevision,
  }) => OrderLine._(
    product: product,
    title: title,
    unitPrice: unitPrice,
    currency: currency,
    quantity: quantity,
    catalogRevision: catalogRevision,
  );

  /// Reconstitutes a persisted line without repairing its values.
  factory OrderLine.fromStored({
    required int productId,
    required String title,
    required int unitPriceMinorUnits,
    required String currencyCode,
    required int quantity,
    required int catalogRevision,
  }) => OrderLine._(
    product: CatalogProductReference.fromExternal(productId),
    title: OrderProductTitle.fromStored(title),
    unitPrice: OrderUnitPrice.fromStored(unitPriceMinorUnits),
    currency: OrderCurrency.fromStored(currencyCode),
    quantity: OrderLineQuantity.fromStored(quantity),
    catalogRevision: CatalogOfferRevision.fromExternal(catalogRevision),
  );

  /// Checked line total in minor currency units.
  int get totalMinorUnits => unitPrice.totalFor(quantity);
}
