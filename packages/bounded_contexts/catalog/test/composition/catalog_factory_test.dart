import 'package:app_database/stores/catalog.dart';
import 'package:catalog/catalog.dart';
import 'package:catalog/catalog_composition.dart';
import 'package:test/test.dart';

void main() {
  test('public composition builds a lifecycle-free product catalog', () async {
    final itemsStore = _BorrowedItemsStore();
    final categoriesStore = _BorrowedCategoriesStore();
    final catalog = createCatalogApplication(
      itemsStore: itemsStore,
      categoriesStore: categoriesStore,
    );

    await catalog.facade.createCategory('Hardware');
    await catalog.facade.createDraft(
      title: 'Product',
      description: 'Description',
      priceMinorUnits: 2500,
      currencyCode: 'USD',
      categoryId: 7,
    );
    await catalog.facade.updateDraft(
      id: 1,
      expectedRevision: CatalogItemRevision.fromStored(0),
      title: 'Revised product',
      description: 'Revised description',
      priceMinorUnits: 3000,
      currencyCode: 'EUR',
      categoryId: 7,
    );
    final offers = await catalog.productOffers.findPublishedOffers(<int>{1});
    expect(offers, isEmpty);
    await catalog.facade.publishItem(
      id: 1,
      expectedRevision: CatalogItemRevision.fromStored(1),
    );
    await catalog.facade.archiveItem(
      id: 1,
      expectedRevision: CatalogItemRevision.fromStored(2),
    );

    expect(itemsStore.statusValues, <int>[1, 2]);
    expect(itemsStore.disposeCount, 0);
    expect(categoriesStore.disposeCount, 0);
  });

  test(
    'composition exposes draft deletion without taking store ownership',
    () async {
      final itemsStore = _BorrowedItemsStore();
      final categoriesStore = _BorrowedCategoriesStore();
      final catalog = createCatalogApplication(
        itemsStore: itemsStore,
        categoriesStore: categoriesStore,
      );

      await catalog.facade.deleteDraft(
        id: 1,
        expectedRevision: CatalogItemRevision.fromStored(0),
      );

      expect(itemsStore.deletedDrafts, <(int, int)>[(1, 0)]);
      expect(itemsStore.disposeCount, 0);
      expect(categoriesStore.disposeCount, 0);
    },
  );
}

final class _BorrowedItemsStore implements CatalogItemsStore {
  int statusValue = 0;
  int revision = 0;
  final List<int> statusValues = [];
  final List<(int, int)> deletedDrafts = [];
  int disposeCount = 0;

  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  Future<int> deleteDraft({
    required int id,
    required int expectedRevision,
  }) async {
    if (statusValue != 0 || expectedRevision != revision) {
      return 0;
    }
    deletedDrafts.add((id, expectedRevision));
    return 1;
  }

  @override
  Future<StoredCatalogItem?> getItem(int id) async => StoredCatalogItem(
    id: id,
    title: 'Product',
    description: 'Description',
    priceMinorUnits: 2500,
    currencyCode: 'USD',
    statusValue: statusValue,
    categoryId: 7,
    revision: revision,
  );

  @override
  Future<List<StoredCatalogItem>> findItemsByIds(Set<int> ids) async => ids
      .map(
        (id) => StoredCatalogItem(
          id: id,
          title: 'Product',
          description: 'Description',
          priceMinorUnits: 2500,
          currencyCode: 'USD',
          statusValue: statusValue,
          categoryId: 7,
          revision: revision,
        ),
      )
      .toList(growable: false);

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
  }) async {
    if (statusValue != 0 || expectedRevision != revision) {
      return 0;
    }
    statusValue = 1;
    revision += 1;
    statusValues.add(statusValue);
    return 1;
  }

  @override
  Future<int> archivePublished({
    required int id,
    required int expectedRevision,
  }) async {
    if (statusValue != 1 || expectedRevision != revision) {
      return 0;
    }
    statusValue = 2;
    revision += 1;
    statusValues.add(statusValue);
    return 1;
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
    if (statusValue != 0 || expectedRevision != revision) {
      return 0;
    }
    revision += 1;
    return 1;
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
    if (statusValue != 1 || expectedRevision != revision) {
      return 0;
    }
    revision += 1;
    return 1;
  }

  @override
  Stream<List<StoredCatalogItem>> watchItems() =>
      const Stream<List<StoredCatalogItem>>.empty();
}

final class _BorrowedCategoriesStore implements CatalogCategoriesStore {
  int disposeCount = 0;

  Future<void> dispose() async {
    disposeCount += 1;
  }

  @override
  Future<StoredCatalogCategory?> getCategory(int id) async =>
      StoredCatalogCategory(id: id, name: 'Hardware', isActive: true);

  @override
  Future<int> insertCategory(String name) async => 7;

  @override
  Future<int> setCategoryActive({
    required int id,
    required bool isActive,
  }) async => 1;

  @override
  Stream<List<StoredCatalogCategory>> watchCategories() =>
      const Stream<List<StoredCatalogCategory>>.empty();
}
