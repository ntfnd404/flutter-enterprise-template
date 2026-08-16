import 'dart:collection';

import 'package:catalog/src/application/product_offers/catalog_offer_request_exception.dart';
import 'package:catalog/src/application/product_offers/catalog_offer_unavailable_exception.dart';
import 'package:catalog/src/application/product_offers/catalog_product_offer_reader.dart';
import 'package:catalog/src/application/product_offers/catalog_product_offer_snapshot.dart';
import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/item/catalog_item.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_status.dart';
import 'package:catalog/src/domain/repository/catalog_item_repository.dart';

/// Default implementation of Catalog's downstream Product Offers query.
final class CatalogProductOfferService implements CatalogProductOfferReader {
  /// Creates the query service over Catalog's item repository.
  const CatalogProductOfferService(this._items);

  final CatalogItemRepository _items;

  @override
  Future<Map<int, CatalogProductOfferSnapshot>> findPublishedOffers(
    Set<int> productIds,
  ) async {
    final copiedIds = Set<int>.unmodifiable(productIds);
    if (copiedIds.length > CatalogProductOfferReader.maxBatchSize) {
      throw const CatalogOfferRequestException(
        CatalogOfferRequestFailure.batchTooLarge,
      );
    }
    if (copiedIds.any((id) => id <= 0)) {
      throw const CatalogOfferRequestException(
        CatalogOfferRequestFailure.invalidProductIdentifier,
      );
    }
    if (copiedIds.isEmpty) {
      return const <int, CatalogProductOfferSnapshot>{};
    }

    List<CatalogItem> items;
    try {
      items = await _items.findItemsByIds(copiedIds);
    } on CatalogPersistenceException catch (_, stackTrace) {
      Error.throwWithStackTrace(
        const CatalogOfferUnavailableException(),
        stackTrace,
      );
    }

    final seenIds = <int>{};
    final publishedItems = <CatalogItem>[];
    for (final item in items) {
      if (!copiedIds.contains(item.id) || !seenIds.add(item.id)) {
        throw const CatalogDataIntegrityException();
      }
      if (item.status == CatalogItemStatus.published) {
        publishedItems.add(item);
      }
    }
    publishedItems.sort((left, right) => left.id.compareTo(right.id));

    final offers = <int, CatalogProductOfferSnapshot>{};
    for (final item in publishedItems) {
      offers[item.id] = CatalogProductOfferSnapshot(
        productId: item.id,
        title: item.title.value,
        priceMinorUnits: item.price.minorUnits,
        currencyCode: item.price.currencyCode,
        catalogRevision: item.revision.value,
      );
    }

    return UnmodifiableMapView<int, CatalogProductOfferSnapshot>(offers);
  }
}
