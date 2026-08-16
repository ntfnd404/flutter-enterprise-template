import 'dart:async';

import 'package:app_database/stores/catalog.dart';
import 'package:catalog/catalog.dart';
import 'package:catalog/src/infrastructure/persistence/store_catalog_category_repository.dart';
import 'package:catalog/src/infrastructure/persistence/store_catalog_item_repository.dart';
import 'package:test/test.dart';

void main() {
  test('one subscription receives the current snapshot and updates', () async {
    final store = _RecordingObservationStore();
    addTearDown(store.close);
    final repository = StoreCatalogItemRepository(store);
    final iterator = StreamIterator<List<CatalogItem>>(
      repository.watchItems(),
    );
    addTearDown(iterator.cancel);

    expect(await iterator.moveNext(), isTrue);
    final initial = iterator.current;
    store.controllers.single.add(const <StoredCatalogItem>[
      StoredCatalogItem(
        id: 1,
        title: 'Item',
        description: 'Description',
        priceMinorUnits: 100,
        currencyCode: 'USD',
        statusValue: 1,
        categoryId: 7,
        revision: 0,
      ),
    ]);
    expect(await iterator.moveNext(), isTrue);
    final updated = iterator.current;

    expect(store.watchCount, 1);
    expect(initial, isEmpty);
    expect(updated.single.id, 1);
    expect(updated.single.title.value, 'Item');
    expect(updated.single.status, CatalogItemStatus.published);
    await iterator.cancel();
  });

  test('caller cancellation reaches the underlying store stream', () async {
    final store = _RecordingObservationStore();
    addTearDown(store.close);
    final repository = StoreCatalogItemRepository(store);
    final subscription = repository.watchItems().listen((_) {});

    await store.firstListener;
    await subscription.cancel();

    expect(store.cancelCount, 1);
  });

  test('normal completion does not create a hidden resubscription', () async {
    final store = _RecordingObservationStore();
    addTearDown(store.close);
    final repository = StoreCatalogItemRepository(store);
    final firstDone = Completer<void>();
    final firstSubscription = repository.watchItems().listen(
      (_) {},
      onDone: firstDone.complete,
    );
    addTearDown(firstSubscription.cancel);

    await store.firstListener;
    await store.controllers.single.close();
    await firstDone.future;

    expect(store.watchCount, 1);

    final secondSubscription = repository.watchItems().listen((_) {});
    addTearDown(secondSubscription.cancel);
    await store.listenerCount(2);

    expect(store.watchCount, 2);
    expect(store.controllers, hasLength(2));
    await secondSubscription.cancel();
  });

  test('independent facade streams do not share a subscription', () async {
    final store = _RecordingObservationStore();
    addTearDown(store.close);
    final repository = StoreCatalogItemRepository(store);
    final first = StreamIterator<List<CatalogItem>>(repository.watchItems());
    final second = StreamIterator<List<CatalogItem>>(repository.watchItems());
    addTearDown(first.cancel);
    addTearDown(second.cancel);

    expect(await first.moveNext(), isTrue);
    expect(await second.moveNext(), isTrue);

    expect(store.watchCount, 2);
    expect(store.controllers, hasLength(2));
    await first.cancel();
    await second.cancel();
  });

  test('one returned stream accepts only one listener', () async {
    final store = _RecordingObservationStore();
    addTearDown(store.close);
    final repository = StoreCatalogItemRepository(store);
    final stream = repository.watchItems();
    final first = stream.listen((_) {});
    addTearDown(first.cancel);

    await store.firstListener;

    expect(() => stream.listen((_) {}), throwsStateError);
    await first.cancel();
  });

  test('maps an expected watch failure with its boundary stack', () async {
    final stackTrace = StackTrace.fromString('catalog-watch-stack');
    final store = _RecordingObservationStore(
      failure: const CatalogStoreException(),
      failureStack: stackTrace,
    );
    final repository = StoreCatalogItemRepository(store);

    final caught = await _captureStreamFailure(repository.watchItems());

    expect(caught.error, isA<CatalogPersistenceException>());
    expect(caught.stackTrace.toString(), stackTrace.toString());
  });

  test('preserves an unexpected watch failure and stack', () async {
    final error = StateError('unexpected-watch');
    final stackTrace = StackTrace.fromString('unexpected-watch-stack');
    final store = _RecordingObservationStore(
      failure: error,
      failureStack: stackTrace,
    );
    final repository = StoreCatalogItemRepository(store);

    final caught = await _captureStreamFailure(repository.watchItems());

    expect(caught.error, same(error));
    expect(caught.stackTrace.toString(), stackTrace.toString());
  });

  test(
    'category observation maps updates and propagates cancellation',
    () async {
      final categoriesStore = _RecordingCategoryObservationStore();
      addTearDown(categoriesStore.close);
      final repository = StoreCatalogCategoryRepository(categoriesStore);
      final iterator = StreamIterator<List<CatalogCategory>>(
        repository.watchCategories(),
      );
      addTearDown(iterator.cancel);

      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);
      categoriesStore.controller.add(
        const <StoredCatalogCategory>[
          StoredCatalogCategory(id: 7, name: 'Hardware', isActive: false),
        ],
      );
      expect(await iterator.moveNext(), isTrue);

      expect(iterator.current.single.id, 7);
      expect(iterator.current.single.name.value, 'Hardware');
      expect(iterator.current.single.isActive, isFalse);
      await iterator.cancel();
      expect(categoriesStore.cancelCount, 1);
    },
  );

  test(
    'maps an expected category watch failure with its boundary stack',
    () async {
      final stackTrace = StackTrace.fromString('category-watch-stack');
      final categoriesStore = _RecordingCategoryObservationStore(
        failure: const CatalogStoreException(),
        failureStack: stackTrace,
      );
      final repository = StoreCatalogCategoryRepository(categoriesStore);

      final caught = await _captureStreamFailure(repository.watchCategories());

      expect(caught.error, isA<CatalogPersistenceException>());
      expect(caught.stackTrace.toString(), stackTrace.toString());
    },
  );
}

final class _RecordingObservationStore implements CatalogItemsStore {
  _RecordingObservationStore({this.failure, this.failureStack});

  final Object? failure;
  final StackTrace? failureStack;
  final List<StreamController<List<StoredCatalogItem>>> controllers =
      <StreamController<List<StoredCatalogItem>>>[];
  final Completer<void> _firstListener = Completer<void>();
  final List<Completer<void>> _listenerCounts = <Completer<void>>[];
  int watchCount = 0;
  int cancelCount = 0;

  Future<void> get firstListener => _firstListener.future;

  Future<void> listenerCount(int count) {
    if (watchCount >= count) {
      return Future<void>.value();
    }
    while (_listenerCounts.length < count) {
      _listenerCounts.add(Completer<void>());
    }

    return _listenerCounts[count - 1].future;
  }

  Future<void> close() async {
    for (final controller in controllers) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
  }

  @override
  Future<int> deleteDraft({
    required int id,
    required int expectedRevision,
  }) async => 0;

  @override
  Future<StoredCatalogItem?> getItem(int id) async => null;

  @override
  Future<List<StoredCatalogItem>> findItemsByIds(Set<int> ids) async =>
      const <StoredCatalogItem>[];

  @override
  Future<int> insertItem({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) async => 1;

  @override
  Future<int> publishDraft({
    required int id,
    required int expectedRevision,
    required int requiredActiveCategoryId,
  }) async => 0;

  @override
  Future<int> archivePublished({
    required int id,
    required int expectedRevision,
  }) async => 0;

  @override
  Future<int> updateDraft({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) async => 0;

  @override
  Future<int> updatePublishedOffer({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  }) async => 0;

  @override
  Stream<List<StoredCatalogItem>> watchItems() {
    watchCount += 1;
    final controlledFailure = failure;
    if (controlledFailure != null) {
      return Stream<List<StoredCatalogItem>>.error(
        controlledFailure,
        failureStack,
      );
    }
    late final StreamController<List<StoredCatalogItem>> controller;
    controller = StreamController<List<StoredCatalogItem>>(
      sync: true,
      onListen: () {
        if (!_firstListener.isCompleted) {
          _firstListener.complete();
        }
        for (var index = 0; index < watchCount; index += 1) {
          if (index < _listenerCounts.length &&
              !_listenerCounts[index].isCompleted) {
            _listenerCounts[index].complete();
          }
        }
        controller.add(const <StoredCatalogItem>[]);
      },
      onCancel: () {
        cancelCount += 1;
      },
    );
    controllers.add(controller);

    return controller.stream;
  }
}

Future<({Object error, StackTrace stackTrace})> _captureStreamFailure<T>(
  Stream<T> stream,
) async {
  try {
    await stream.drain<void>();
  } on Object catch (error, stackTrace) {
    return (error: error, stackTrace: stackTrace);
  }

  fail('The observation must fail.');
}

final class _RecordingCategoryObservationStore
    implements CatalogCategoriesStore {
  _RecordingCategoryObservationStore({this.failure, this.failureStack});

  final Object? failure;
  final StackTrace? failureStack;
  late final StreamController<List<StoredCatalogCategory>> controller =
      StreamController<List<StoredCatalogCategory>>(
        sync: true,
        onListen: () {
          final controlledFailure = failure;
          if (controlledFailure == null) {
            controller.add(const <StoredCatalogCategory>[]);
          } else {
            controller.addError(controlledFailure, failureStack);
          }
        },
        onCancel: () {
          cancelCount += 1;
        },
      );
  int cancelCount = 0;

  Future<void> close() async {
    if (!controller.isClosed) {
      await controller.close();
    }
  }

  @override
  Future<StoredCatalogCategory?> getCategory(int id) async => null;

  @override
  Future<int> insertCategory(String name) async => 1;

  @override
  Future<int> setCategoryActive({
    required int id,
    required bool isActive,
  }) async => 0;

  @override
  Stream<List<StoredCatalogCategory>> watchCategories() => controller.stream;
}
