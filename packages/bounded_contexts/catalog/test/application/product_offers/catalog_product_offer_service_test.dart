import 'dart:async';

import 'package:catalog/catalog.dart';
import 'package:catalog/catalog_product_offers.dart';
import 'package:catalog/src/application/product_offers/catalog_product_offer_service.dart';
import 'package:catalog/src/domain/repository/catalog_item_repository.dart';
import 'package:test/test.dart';

void main() {
  late _RecordingItemRepository repository;
  late CatalogProductOfferService service;

  setUp(() {
    repository = _RecordingItemRepository();
    service = CatalogProductOfferService(repository);
  });

  test(
    'batches once, filters lifecycle, and returns stable immutable data',
    () async {
      repository.items = <CatalogItem>[
        _item(id: 5, status: CatalogItemStatus.published),
        _item(id: 2),
        _item(id: 3, status: CatalogItemStatus.archived),
        _item(status: CatalogItemStatus.published),
      ];

      final offers = await service.findPublishedOffers(<int>{5, 1, 2, 3, 404});

      expect(repository.batchReads, 1);
      expect(offers.keys, orderedEquals(<int>[1, 5]));
      expect(offers[1]!.title, 'Product');
      expect(offers[1]!.catalogRevision, 0);
      expect(() => offers.clear(), throwsUnsupportedError);
    },
  );

  test(
    'validates deterministic request precedence before persistence',
    () async {
      expect(await service.findPublishedOffers(const <int>{}), isEmpty);
      await expectLater(
        service.findPublishedOffers(<int>{0}),
        throwsA(
          isA<CatalogOfferRequestException>().having(
            (error) => error.failure,
            'failure',
            CatalogOfferRequestFailure.invalidProductIdentifier,
          ),
        ),
      );
      final oversizedWithInvalidId = Set<int>.from(
        List<int>.generate(
          CatalogProductOfferReader.maxBatchSize + 1,
          (index) => index,
        ),
      );
      await expectLater(
        service.findPublishedOffers(oversizedWithInvalidId),
        throwsA(
          isA<CatalogOfferRequestException>().having(
            (error) => error.failure,
            'failure',
            CatalogOfferRequestFailure.batchTooLarge,
          ),
        ),
      );
      expect(repository.batchReads, 0);
    },
  );

  test('copies the request before awaiting repository work', () async {
    repository.items = <CatalogItem>[
      _item(status: CatalogItemStatus.published),
    ];
    repository.gate = Completer<void>();
    final requested = <int>{1};

    final future = service.findPublishedOffers(requested);
    requested
      ..clear()
      ..add(404);
    repository.gate!.complete();
    await future;

    expect(repository.lastBatchIds, <int>{1});
  });

  test('rejects duplicate and unrequested repository records', () async {
    repository.items = <CatalogItem>[
      _item(status: CatalogItemStatus.published),
      _item(status: CatalogItemStatus.published),
    ];
    await expectLater(
      service.findPublishedOffers(<int>{1}),
      throwsA(isA<CatalogDataIntegrityException>()),
    );

    repository.items = <CatalogItem>[
      _item(id: 2, status: CatalogItemStatus.published),
    ];
    await expectLater(
      service.findPublishedOffers(<int>{1}),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });

  test('maps temporary unavailability with the original catch stack', () async {
    final stackTrace = StackTrace.fromString('catalog-offer-stack');
    repository.failure = const CatalogPersistenceException();
    repository.failureStack = stackTrace;

    final caught = await _capture(service.findPublishedOffers(<int>{1}));

    expect(caught.error, isA<CatalogOfferUnavailableException>());
    expect(caught.stackTrace.toString(), stackTrace.toString());
  });

  test('preserves unexpected failure identity and stack', () async {
    final error = StateError('unexpected');
    final stackTrace = StackTrace.fromString('catalog-offer-unexpected-stack');
    repository.failure = error;
    repository.failureStack = stackTrace;

    final caught = await _capture(service.findPublishedOffers(<int>{1}));

    expect(caught.error, same(error));
    expect(caught.stackTrace.toString(), stackTrace.toString());
  });
}

final class _RecordingItemRepository implements CatalogItemRepository {
  List<CatalogItem> items = <CatalogItem>[];
  int batchReads = 0;
  Set<int>? lastBatchIds;
  Completer<void>? gate;
  Object? failure;
  StackTrace? failureStack;

  @override
  Future<List<CatalogItem>> findItemsByIds(Set<int> ids) async {
    batchReads += 1;
    lastBatchIds = Set<int>.of(ids);
    await gate?.future;
    final controlledFailure = failure;
    if (controlledFailure != null) {
      Error.throwWithStackTrace(
        controlledFailure,
        failureStack ?? StackTrace.current,
      );
    }
    return items;
  }

  @override
  Future<void> archivePublished({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {}

  @override
  Future<void> createDraft({
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) async {}

  @override
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {}

  @override
  Future<CatalogItem> getItem(int id) async => throw UnimplementedError();

  @override
  Future<void> publishDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required int requiredActiveCategoryId,
  }) async {}

  @override
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) async {}

  @override
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int categoryId,
  }) async {}

  @override
  Stream<List<CatalogItem>> watchItems() => const Stream.empty();
}

Future<({Object error, StackTrace stackTrace})> _capture(
  Future<Object?> future,
) async {
  try {
    await future;
  } on Object catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }
  fail('The operation must fail.');
}

CatalogItem _item({
  int id = 1,
  CatalogItemStatus status = CatalogItemStatus.draft,
}) => CatalogItem.fromValues(
  id: id,
  title: 'Product',
  description: 'Description',
  priceMinorUnits: 100,
  currencyCode: 'USD',
  statusValue: status.value,
  categoryId: 7,
  revision: 0,
);
