import 'dart:async';

import 'package:catalog/catalog_product_offers.dart';
import 'package:ordering/ordering.dart';
import 'package:ordering/src/infrastructure/integration/catalog/catalog_product_offer_adapter.dart';
import 'package:test/test.dart';

void main() {
  test(
    'translates Published Language DTOs into Ordering-owned values',
    () async {
      final reader = _CatalogReader(<int, CatalogProductOfferSnapshot>{
        1: const CatalogProductOfferSnapshot(
          productId: 1,
          title: 'Product',
          priceMinorUnits: 125,
          currencyCode: 'USD',
          catalogRevision: 7,
        ),
      });
      final adapter = CatalogProductOfferAdapter(reader);
      final product = CatalogProductReference.fromInput(1);

      final result = await adapter.loadOffers(<CatalogProductReference>{
        product,
      });

      expect(reader.calls, 1);
      expect(result[product]!.title.value, 'Product');
      expect(result[product]!.unitPrice.minorUnits, 125);
      expect(result[product]!.catalogRevision.value, 7);
      expect(() => result.clear(), throwsUnsupportedError);
    },
  );

  test('rejects an incomplete response as product unavailable', () async {
    final adapter = CatalogProductOfferAdapter(
      _CatalogReader(const <int, CatalogProductOfferSnapshot>{}),
    );

    await expectLater(
      adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      }),
      throwsA(isA<OrderingProductUnavailableException>()),
    );
  });

  test('snapshots the requested products before awaiting Catalog', () async {
    final gate = Completer<void>();
    final reader = _CatalogReader.deferred(
      <int, CatalogProductOfferSnapshot>{
        1: const CatalogProductOfferSnapshot(
          productId: 1,
          title: 'Product',
          priceMinorUnits: 125,
          currencyCode: 'USD',
          catalogRevision: 7,
        ),
      },
      gate,
    );
    final adapter = CatalogProductOfferAdapter(reader);
    final requested = <CatalogProductReference>{
      CatalogProductReference.fromInput(1),
    };

    final result = adapter.loadOffers(requested);
    requested.clear();
    gate.complete();
    await result;

    expect(reader.receivedIds, <int>{1});
  });

  test('rejects unrequested upstream records as data integrity', () async {
    final adapter = CatalogProductOfferAdapter(
      _CatalogReader.raw(<int, CatalogProductOfferSnapshot>{
        1: const CatalogProductOfferSnapshot(
          productId: 1,
          title: 'Requested',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          catalogRevision: 1,
        ),
        2: const CatalogProductOfferSnapshot(
          productId: 2,
          title: 'Unrequested',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          catalogRevision: 1,
        ),
      }),
    );

    await expectLater(
      adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      }),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
  });

  test('rejects an upstream key and snapshot identity mismatch', () async {
    final adapter = CatalogProductOfferAdapter(
      _CatalogReader(<int, CatalogProductOfferSnapshot>{
        1: const CatalogProductOfferSnapshot(
          productId: 2,
          title: 'Wrong product',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          catalogRevision: 1,
        ),
      }),
    );

    await expectLater(
      adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      }),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
  });

  test('maps Catalog contention and preserves its catch stack', () async {
    final reader = _CatalogReader.failure(
      const CatalogOfferUnavailableException(),
    );
    final adapter = CatalogProductOfferAdapter(reader);

    try {
      await adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      });
      fail('Expected OrderingCatalogUnavailableException.');
    } on OrderingCatalogUnavailableException catch (_, stackTrace) {
      expect(
        stackTrace.toString(),
        contains('_CatalogReader.findPublishedOffers'),
      );
    }
  });

  test('maps an impossible upstream request rejection to integrity', () async {
    final reader = _CatalogReader.failure(
      const CatalogOfferRequestException(
        CatalogOfferRequestFailure.batchTooLarge,
      ),
    );
    final adapter = CatalogProductOfferAdapter(reader);

    try {
      await adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      });
      fail('Expected OrderingDataIntegrityException.');
    } on OrderingDataIntegrityException catch (_, stackTrace) {
      expect(
        stackTrace.toString(),
        contains('_CatalogReader.findPublishedOffers'),
      );
    }
  });

  test('rejects invalid upstream values as data-integrity failures', () async {
    final adapter = CatalogProductOfferAdapter(
      _CatalogReader(<int, CatalogProductOfferSnapshot>{
        1: const CatalogProductOfferSnapshot(
          productId: 1,
          title: 'Product',
          priceMinorUnits: 0,
          currencyCode: 'XXX',
          catalogRevision: 0,
        ),
      }),
    );

    await expectLater(
      adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      }),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
  });

  test('preserves unexpected upstream error identity and stack', () async {
    final failure = StateError('unexpected');
    final adapter = CatalogProductOfferAdapter(
      _CatalogReader.failure(failure),
    );

    try {
      await adapter.loadOffers(<CatalogProductReference>{
        CatalogProductReference.fromInput(1),
      });
      fail('Expected the original failure.');
    } on Object catch (error, stackTrace) {
      expect(error, same(failure));
      expect(
        stackTrace.toString(),
        contains('_CatalogReader.findPublishedOffers'),
      );
    }
  });
}

final class _CatalogReader implements CatalogProductOfferReader {
  _CatalogReader(this.values) : failure = null, gate = null, returnAll = false;

  _CatalogReader.deferred(this.values, this.gate)
    : failure = null,
      returnAll = false;

  _CatalogReader.raw(this.values)
    : failure = null,
      gate = null,
      returnAll = true;

  _CatalogReader.failure(this.failure)
    : values = const <int, CatalogProductOfferSnapshot>{},
      gate = null,
      returnAll = false;

  final Map<int, CatalogProductOfferSnapshot> values;
  final Object? failure;
  final Completer<void>? gate;
  final bool returnAll;
  int calls = 0;
  Set<int>? receivedIds;

  @override
  Future<Map<int, CatalogProductOfferSnapshot>> findPublishedOffers(
    Set<int> ids,
  ) async {
    calls += 1;
    receivedIds = ids;
    await gate?.future;
    final currentFailure = failure;
    if (currentFailure != null) {
      Error.throwWithStackTrace(currentFailure, StackTrace.current);
    }
    if (returnAll) {
      return values;
    }

    return <int, CatalogProductOfferSnapshot>{
      for (final id in ids) id: ?values[id],
    };
  }
}
