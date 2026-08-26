import 'package:app_database/stores/catalog.dart';
import 'package:catalog/catalog.dart';
import 'package:catalog/src/infrastructure/persistence/store_catalog_category_repository.dart';
import 'package:catalog/src/infrastructure/persistence/store_catalog_item_repository.dart';
import 'package:test/test.dart';

void main() {
  late _ItemsStore itemsStore;
  late _CategoriesStore categoriesStore;
  late StoreCatalogItemRepository itemRepository;
  late StoreCatalogCategoryRepository categoryRepository;

  setUp(() {
    itemsStore = _ItemsStore();
    categoriesStore = _CategoriesStore();
    itemRepository = StoreCatalogItemRepository(itemsStore);
    categoryRepository = StoreCatalogCategoryRepository(categoriesStore);
  });

  test(
    'maps all product and category fields into immutable snapshots',
    () async {
      itemsStore.items = <StoredCatalogItem>[_storedItem()];
      categoriesStore.categories = <StoredCatalogCategory>[_storedCategory()];

      final items = await itemRepository.watchItems().first;
      final categories = await categoryRepository.watchCategories().first;

      expect(items.single.id, 1);
      expect(items.single.title.value, 'Product');
      expect(items.single.description.value, 'Description');
      expect(items.single.price.minorUnits, 2500);
      expect(items.single.price.currencyCode, 'USD');
      expect(items.single.status, CatalogItemStatus.draft);
      expect(items.single.categoryId, 7);
      expect(items.single.revision.value, 0);
      expect(categories.single.name.value, 'Hardware');
      expect(categories.single.isActive, isTrue);
      expect(() => items.add(_item()), throwsUnsupportedError);
      expect(() => categories.add(_category()), throwsUnsupportedError);
    },
  );

  test('strictly rejects corrupt persisted representations', () async {
    itemsStore.items = <StoredCatalogItem>[
      _storedItem(statusValue: 99),
    ];
    await expectLater(
      itemRepository.watchItems().first,
      throwsA(isA<CatalogDataIntegrityException>()),
    );

    itemsStore.items = <StoredCatalogItem>[_storedItem(revision: -1)];
    await expectLater(
      itemRepository.watchItems().first,
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });

  test('loads entities and preserves missing-category semantics', () async {
    itemsStore.items = <StoredCatalogItem>[_storedItem()];
    categoriesStore.categories = <StoredCatalogCategory>[_storedCategory()];

    expect((await itemRepository.getItem(1)).title.value, 'Product');
    expect((await categoryRepository.getCategory(7))?.name.value, 'Hardware');
    expect(await categoryRepository.getCategory(404), isNull);
    await expectLater(
      itemRepository.getItem(404),
      throwsA(isA<CatalogItemNotFoundException>()),
    );
  });

  test('delegates validated draft and category values', () async {
    await itemRepository.createDraft(
      title: CatalogItemTitle.fromUserInput('Product'),
      description: CatalogItemDescription.fromUserInput('Description'),
      price: CatalogItemPrice.fromUserInput(
        minorUnits: 2500,
        currencyCode: 'USD',
      ),
      categoryId: 7,
    );
    await categoryRepository.createCategory(
      CatalogCategoryName.fromUserInput('Hardware'),
    );
    await categoryRepository.setCategoryActive(id: 7, isActive: false);

    expect(itemsStore.inserted.single.title, 'Product');
    expect(itemsStore.inserted.single.priceMinorUnits, 2500);
    expect(categoriesStore.insertedNames, <String>['Hardware']);
    expect(categoriesStore.activationChanges, <(int, bool)>[(7, false)]);
  });

  test('uses intent-specific optimistic transitions', () async {
    await itemRepository.publishDraft(
      id: 1,
      expectedRevision: CatalogItemRevision.fromStored(0),
      requiredActiveCategoryId: 7,
    );
    await itemRepository.archivePublished(
      id: 1,
      expectedRevision: CatalogItemRevision.fromStored(1),
    );
    await itemRepository.deleteDraft(
      id: 2,
      expectedRevision: CatalogItemRevision.fromStored(3),
    );

    expect(itemsStore.publishChanges.single, (1, 0, 7));
    expect(itemsStore.archiveChanges.single, (1, 1));
    expect(itemsStore.deleteChanges.single, (2, 3));

    itemsStore.affectedRows = 0;
    await expectLater(
      itemRepository.publishDraft(
        id: 1,
        expectedRevision: CatalogItemRevision.fromStored(0),
        requiredActiveCategoryId: 7,
      ),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.concurrentStateChange,
        ),
      ),
    );
    await expectLater(
      itemRepository.deleteDraft(
        id: 2,
        expectedRevision: CatalogItemRevision.fromStored(3),
      ),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.concurrentStateChange,
        ),
      ),
    );
  });

  test(
    'updates validated draft details with an optimistic condition',
    () async {
      await itemRepository.updateDraft(
        id: 1,
        expectedRevision: CatalogItemRevision.fromStored(0),
        title: CatalogItemTitle.fromUserInput('Revised'),
        description: CatalogItemDescription.fromUserInput('New description'),
        price: CatalogItemPrice.fromUserInput(
          minorUnits: 3000,
          currencyCode: 'EUR',
        ),
        categoryId: 7,
      );

      final update = itemsStore.draftUpdates.single;
      expect(update.id, 1);
      expect(update.expectedRevision, 0);
      expect(update.title, 'Revised');
      expect(update.description, 'New description');
      expect(update.priceMinorUnits, 3000);
      expect(update.currencyCode, 'EUR');
      expect(update.categoryId, 7);

      itemsStore.affectedRows = 0;
      await expectLater(
        itemRepository.updateDraft(
          id: 1,
          expectedRevision: CatalogItemRevision.fromStored(0),
          title: CatalogItemTitle.fromUserInput('Revised'),
          description: CatalogItemDescription.fromUserInput('New description'),
          price: CatalogItemPrice.fromUserInput(
            minorUnits: 3000,
            currencyCode: 'EUR',
          ),
          categoryId: 7,
        ),
        throwsA(isA<CatalogItemTransitionException>()),
      );
    },
  );

  test('rejects invalid identifiers before store access', () async {
    await expectLater(
      itemRepository.getItem(0),
      throwsA(isA<CatalogItemNotFoundException>()),
    );
    await expectLater(
      categoryRepository.getCategory(0),
      throwsA(isA<CatalogCategoryNotFoundException>()),
    );
    await expectLater(
      itemRepository.deleteDraft(
        id: -1,
        expectedRevision: CatalogItemRevision.fromStored(0),
      ),
      throwsA(isA<CatalogItemNotFoundException>()),
    );
    await expectLater(
      itemRepository.publishDraft(
        id: 1,
        expectedRevision: CatalogItemRevision.fromStored(0),
        requiredActiveCategoryId: 0,
      ),
      throwsA(isA<CatalogCategoryNotFoundException>()),
    );

    expect(itemsStore.readCount, 0);
    expect(categoriesStore.readCount, 0);
    expect(itemsStore.deleteChanges, isEmpty);
    expect(itemsStore.publishChanges, isEmpty);
  });

  test(
    'maps expected store failures and preserves their catch stack',
    () async {
      final stackTrace = StackTrace.fromString('catalog-store-stack');
      itemsStore.failure = const CatalogStoreException();
      itemsStore.failureStack = stackTrace;

      final caught = await _capture(itemRepository.getItem(1));

      expect(caught.error, isA<CatalogPersistenceException>());
      expect(caught.stackTrace.toString(), stackTrace.toString());
    },
  );

  test('preserves unexpected store error identity and stack', () async {
    final error = StateError('unexpected');
    final stackTrace = StackTrace.fromString('unexpected-stack');
    categoriesStore.failure = error;
    categoriesStore.failureStack = stackTrace;

    final caught = await _capture(categoryRepository.getCategory(1));

    expect(caught.error, same(error));
    expect(caught.stackTrace.toString(), stackTrace.toString());
  });
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

final class _ItemsStore implements CatalogItemsStore {
  List<StoredCatalogItem> items = <StoredCatalogItem>[];
  final List<
    ({
      String title,
      String description,
      int priceMinorUnits,
      String currencyCode,
      int? categoryId,
    })
  >
  inserted = [];
  final List<(int, int, int)> publishChanges = [];
  final List<(int, int)> archiveChanges = [];
  final List<
    ({
      int id,
      int expectedRevision,
      String title,
      String description,
      int priceMinorUnits,
      String currencyCode,
      int? categoryId,
    })
  >
  draftUpdates = [];
  final List<(int, int)> deleteChanges = [];
  int affectedRows = 1;
  int readCount = 0;
  Object? failure;
  StackTrace? failureStack;

  @override
  Future<int> deleteDraft({
    required int id,
    required int expectedRevision,
  }) async {
    _throwIfNeeded();
    deleteChanges.add((id, expectedRevision));
    return affectedRows;
  }

  @override
  Future<StoredCatalogItem?> getItem(int id) async {
    _throwIfNeeded();
    readCount += 1;
    return items.where((item) => item.id == id).firstOrNull;
  }

  @override
  Future<List<StoredCatalogItem>> findItemsByIds(Set<int> ids) async {
    _throwIfNeeded();
    readCount += 1;
    return items.where((item) => ids.contains(item.id)).toList();
  }

  @override
  Future<int> insertItem({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) async {
    _throwIfNeeded();
    inserted.add((
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ));
    return 1;
  }

  @override
  Future<int> publishDraft({
    required int id,
    required int expectedRevision,
    required int requiredActiveCategoryId,
  }) async {
    _throwIfNeeded();
    publishChanges.add((id, expectedRevision, requiredActiveCategoryId));
    return affectedRows;
  }

  @override
  Future<int> archivePublished({
    required int id,
    required int expectedRevision,
  }) async {
    _throwIfNeeded();
    archiveChanges.add((id, expectedRevision));
    return affectedRows;
  }

  @override
  Future<int> updateDraft({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int? categoryId,
  }) async {
    _throwIfNeeded();
    draftUpdates.add((
      id: id,
      expectedRevision: expectedRevision,
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ));
    return affectedRows;
  }

  @override
  Future<int> updatePublishedOffer({
    required int id,
    required int expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  }) async {
    _throwIfNeeded();
    return affectedRows;
  }

  @override
  Stream<List<StoredCatalogItem>> watchItems() {
    _throwIfNeeded();
    return Stream<List<StoredCatalogItem>>.value(items);
  }

  void _throwIfNeeded() {
    final error = failure;
    if (error == null) {
      return;
    }
    Error.throwWithStackTrace(error, failureStack ?? StackTrace.current);
  }
}

final class _CategoriesStore implements CatalogCategoriesStore {
  List<StoredCatalogCategory> categories = <StoredCatalogCategory>[];
  final List<String> insertedNames = [];
  final List<(int, bool)> activationChanges = [];
  int affectedRows = 1;
  int readCount = 0;
  Object? failure;
  StackTrace? failureStack;

  @override
  Future<StoredCatalogCategory?> getCategory(int id) async {
    _throwIfNeeded();
    readCount += 1;
    return categories.where((category) => category.id == id).firstOrNull;
  }

  @override
  Future<int> insertCategory(String name) async {
    _throwIfNeeded();
    insertedNames.add(name);
    return 1;
  }

  @override
  Future<int> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    _throwIfNeeded();
    activationChanges.add((id, isActive));
    return affectedRows;
  }

  @override
  Stream<List<StoredCatalogCategory>> watchCategories() {
    _throwIfNeeded();
    return Stream<List<StoredCatalogCategory>>.value(categories);
  }

  void _throwIfNeeded() {
    final error = failure;
    if (error == null) {
      return;
    }
    Error.throwWithStackTrace(error, failureStack ?? StackTrace.current);
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => this.isEmpty ? null : first;
}

StoredCatalogItem _storedItem({int statusValue = 0, int revision = 0}) =>
    StoredCatalogItem(
      id: 1,
      title: 'Product',
      description: 'Description',
      priceMinorUnits: 2500,
      currencyCode: 'USD',
      statusValue: statusValue,
      categoryId: 7,
      revision: revision,
    );

StoredCatalogCategory _storedCategory({bool isActive = true}) =>
    StoredCatalogCategory(
      id: 7,
      name: 'Hardware',
      isActive: isActive,
    );

CatalogItem _item() => CatalogItem.fromValues(
  id: 1,
  title: 'Product',
  description: 'Description',
  priceMinorUnits: 2500,
  currencyCode: 'USD',
  statusValue: 0,
  categoryId: 7,
  revision: 0,
);

CatalogCategory _category() => CatalogCategory.fromValues(
  id: 7,
  name: 'Hardware',
  isActive: true,
);
