import 'dart:collection';

import 'package:catalog/catalog_product_offers.dart';
import 'package:ordering/src/application/product_offers/order_product_offer.dart';
import 'package:ordering/src/application/product_offers/product_offer_provider.dart';
import 'package:ordering/src/domain/order/value_objects/catalog_offer_revision.dart';
import 'package:ordering/src/domain/order/value_objects/catalog_product_reference.dart';
import 'package:ordering/src/domain/order/value_objects/order_currency.dart';
import 'package:ordering/src/domain/order/value_objects/order_product_title.dart';
import 'package:ordering/src/domain/order/value_objects/order_unit_price.dart';
import 'package:ordering/src/domain/ordering_exception.dart';

/// Ordering-owned Anti-Corruption Layer over Catalog's Product Offers API.
///
/// The Context Map classifies that inter-context contract as a Published
/// Language. This adapter immediately translates its DTOs into Ordering's own
/// ubiquitous language. The direct request returns point-in-time data and does
/// not join the later Ordering write into a cross-context transaction.
final class CatalogProductOfferAdapter implements ProductOfferProvider {
  /// Creates the adapter over a borrowed Catalog application port.
  const CatalogProductOfferAdapter(this._reader);

  final CatalogProductOfferReader _reader;

  @override
  Future<Map<CatalogProductReference, OrderProductOffer>> loadOffers(
    Set<CatalogProductReference> products,
  ) async {
    final copiedProducts = Set<CatalogProductReference>.unmodifiable(products);
    final requestedIds = Set<int>.unmodifiable(
      copiedProducts.map((product) => product.value),
    );
    Map<int, CatalogProductOfferSnapshot> upstream;
    try {
      upstream = await _reader.findPublishedOffers(requestedIds);
    } on CatalogOfferUnavailableException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const OrderingCatalogUnavailableException(),
        stackTrace,
      );
    } on CatalogOfferRequestException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const OrderingDataIntegrityException(),
        stackTrace,
      );
    }

    for (final entry in upstream.entries) {
      if (!requestedIds.contains(entry.key) ||
          entry.value.productId != entry.key) {
        throw const OrderingDataIntegrityException();
      }
    }
    if (upstream.length != copiedProducts.length) {
      throw const OrderingProductUnavailableException();
    }
    final offers = <CatalogProductReference, OrderProductOffer>{};
    for (final product in copiedProducts) {
      final offer = upstream[product.value];
      if (offer == null) {
        throw const OrderingProductUnavailableException();
      }
      offers[product] = OrderProductOffer(
        product: product,
        title: OrderProductTitle.fromExternal(offer.title),
        unitPrice: OrderUnitPrice.fromExternal(offer.priceMinorUnits),
        currency: OrderCurrency.fromExternal(offer.currencyCode),
        catalogRevision: CatalogOfferRevision.fromExternal(
          offer.catalogRevision,
        ),
      );
    }

    return UnmodifiableMapView<CatalogProductReference, OrderProductOffer>(
      offers,
    );
  }
}
