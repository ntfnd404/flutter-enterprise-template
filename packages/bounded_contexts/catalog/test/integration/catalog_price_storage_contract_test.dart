import 'dart:io';

import 'package:app_database/app_database_composition.dart';
import 'package:app_database/stores/catalog.dart';
import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('Catalog safe price range fits the SQLite storage envelope', () async {
    final directory = await Directory.systemTemp.createTemp(
      'catalog-price-storage-contract-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final module = createAppDatabaseModule(
      configuration: AppDatabaseConfiguration(
        databaseName: 'catalog_price_storage_contract',
        nativePath: '${directory.path}/catalog.sqlite',
        webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
      ),
    );
    addTearDown(module.dispose);
    await module.initialize();
    final store = module.stores.catalog.items;
    final maximumPrice = CatalogItemPrice.fromUserInput(
      minorUnits: CatalogItemPrice.maxSafeMinorUnits,
      currencyCode: 'USD',
    );

    final itemId = await store.insertItem(
      title: 'Maximum safe price',
      description: 'Cross-boundary contract fixture',
      priceMinorUnits: maximumPrice.minorUnits,
      currencyCode: maximumPrice.currencyCode,
      categoryId: null,
    );
    final persisted = await store.getItem(itemId);

    expect(persisted?.priceMinorUnits, maximumPrice.minorUnits);
    expect(
      CatalogItemPrice.fromStored(
        minorUnits: persisted!.priceMinorUnits,
        currencyCode: persisted.currencyCode,
      ),
      maximumPrice,
    );
    expect(
      () => CatalogItemPrice.fromUserInput(
        minorUnits: CatalogItemPrice.maxSafeMinorUnits + 1,
        currencyCode: 'USD',
      ),
      throwsA(isA<CatalogInvalidPriceException>()),
    );
    await expectLater(
      store.insertItem(
        title: 'Unsafe price',
        description: 'Cross-boundary contract fixture',
        priceMinorUnits: CatalogItemPrice.maxSafeMinorUnits + 1,
        currencyCode: 'USD',
        categoryId: null,
      ),
      throwsA(isNot(isA<CatalogStoreException>())),
    );
  });
}
