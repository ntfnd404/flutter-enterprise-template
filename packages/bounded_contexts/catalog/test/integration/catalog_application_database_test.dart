import 'dart:io';

import 'package:app_database/app_database_composition.dart';
import 'package:catalog/catalog.dart';
import 'package:catalog/catalog_composition.dart';
import 'package:test/test.dart';

void main() {
  test('Catalog commands enforce caller revision through SQLite', () async {
    final directory = await Directory.systemTemp.createTemp(
      'catalog-application-database-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final database = createAppDatabaseModule(
      configuration: AppDatabaseConfiguration(
        databaseName: 'catalog_application_database_test',
        nativePath: '${directory.path}/catalog.sqlite',
        webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
      ),
    );
    addTearDown(database.dispose);
    await database.initialize();
    final catalog = createCatalogApplication(
      itemsStore: database.stores.catalog.items,
      categoriesStore: database.stores.catalog.categories,
    );

    await catalog.facade.createCategory('Hardware');
    final category = (await catalog.facade.watchCategories().first).single;
    await catalog.facade.createDraft(
      title: 'Product',
      description: 'Initial description',
      priceMinorUnits: 100,
      currencyCode: 'USD',
      categoryId: category.id,
    );
    final draft = (await catalog.facade.watchItems().first).single;

    await catalog.facade.updateDraft(
      id: draft.id,
      expectedRevision: draft.revision,
      title: 'Revised product',
      description: 'Revised description',
      priceMinorUnits: 250,
      currencyCode: 'EUR',
      categoryId: category.id,
    );
    final revised = (await catalog.facade.watchItems().first).single;
    expect(revised.title.value, 'Revised product');
    expect(revised.revision.value, 1);

    await expectLater(
      catalog.facade.updateDraft(
        id: draft.id,
        expectedRevision: draft.revision,
        title: 'Stale overwrite',
        description: 'Must not commit',
        priceMinorUnits: 999,
        currencyCode: 'USD',
        categoryId: category.id,
      ),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.concurrentStateChange,
        ),
      ),
    );
    final afterStaleWrite = (await catalog.facade.watchItems().first).single;
    expect(afterStaleWrite.title.value, 'Revised product');
    expect(afterStaleWrite.revision.value, 1);

    await catalog.facade.publishItem(
      id: revised.id,
      expectedRevision: revised.revision,
    );
    final published = (await catalog.facade.watchItems().first).single;
    expect(published.status, CatalogItemStatus.published);
    expect(published.revision.value, 2);
    final offer = (await catalog.productOffers.findPublishedOffers(<int>{
      published.id,
    }))[published.id];
    expect(offer, isNotNull);
    expect(offer!.title, 'Revised product');
    expect(offer.catalogRevision, 2);

    await catalog.facade.archiveItem(
      id: published.id,
      expectedRevision: published.revision,
    );
    final archived = (await catalog.facade.watchItems().first).single;
    expect(archived.status, CatalogItemStatus.archived);
    expect(archived.revision.value, 3);
    expect(
      await catalog.productOffers.findPublishedOffers(<int>{archived.id}),
      isEmpty,
    );
  });
}
