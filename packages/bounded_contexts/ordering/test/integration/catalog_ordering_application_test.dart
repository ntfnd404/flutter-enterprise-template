import 'dart:io';

import 'package:app_database/app_database_composition.dart';
import 'package:catalog/catalog.dart';
import 'package:catalog/catalog_composition.dart';
import 'package:ordering/ordering.dart';
import 'package:ordering/ordering_composition.dart';
import 'package:test/test.dart';

void main() {
  test(
    'public composition refreshes Catalog offers before placing an Order',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'catalog-ordering-application-',
      );
      final database = createAppDatabaseModule(
        configuration: AppDatabaseConfiguration(
          databaseName: 'catalog_ordering_application_test',
          nativePath: '${directory.path}/application.sqlite',
          webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
        ),
      );
      var disposed = false;
      addTearDown(() async {
        if (!disposed) {
          await database.dispose();
        }
        await directory.delete(recursive: true);
      });

      await database.initialize();
      final catalog = createCatalogApplication(
        itemsStore: database.stores.catalog.items,
        categoriesStore: database.stores.catalog.categories,
      );
      final ordering = createOrderingFacade(
        store: database.stores.ordering.orders,
        productOffers: CatalogProductOfferAdapter(catalog.productOffers),
        utcNow: () => DateTime.utc(2026, 1, 2, 3, 4, 5),
      );

      await catalog.facade.createCategory('Hardware');
      final category = (await catalog.facade.watchCategories().first).single;
      await _createPublishedProduct(
        catalog.facade,
        categoryId: category.id,
        title: 'First product',
        priceMinorUnits: 100,
      );
      await _createPublishedProduct(
        catalog.facade,
        categoryId: category.id,
        title: 'Second product',
        priceMinorUnits: 200,
      );
      final published = await catalog.facade.watchItems().first;

      final orderId = await ordering.createDraft();
      await ordering.replaceDraftLines(
        orderId: orderId,
        lines: <OrderLineInput>[
          OrderLineInput(productId: published[0].id, quantity: 2),
          OrderLineInput(productId: published[1].id, quantity: 1),
        ],
      );
      await catalog.facade.updatePublishedOffer(
        id: published[0].id,
        expectedRevision: published[0].revision,
        title: 'First product revised',
        description: 'Current description',
        priceMinorUnits: 300,
        currencyCode: 'USD',
        categoryId: category.id,
      );

      await ordering.placeOrder(orderId);
      final placed = await ordering.watchOrder(orderId).first;
      expect(placed.status, OrderStatus.placed);
      expect(placed.money!.minorUnits, 800);
      expect(placed.lines.first.title.value, 'First product revised');
      expect(placed.lines.first.catalogRevision.value, 2);
      expect(placed.placedAt, DateTime.utc(2026, 1, 2, 3, 4, 5));

      final revisedProduct = (await catalog.facade.watchItems().first)
          .firstWhere((item) => item.id == published[0].id);
      await catalog.facade.updatePublishedOffer(
        id: revisedProduct.id,
        expectedRevision: revisedProduct.revision,
        title: 'Changed after placement',
        description: 'Later description',
        priceMinorUnits: 900,
        currencyCode: 'USD',
        categoryId: category.id,
      );
      final unchanged = await ordering.watchOrder(orderId).first;
      expect(unchanged.lines.first.title.value, 'First product revised');
      expect(unchanged.money!.minorUnits, 800);

      await ordering.cancelOrder(orderId);
      final cancelled = await ordering.watchOrder(orderId).first;
      expect(cancelled.status, OrderStatus.cancelled);

      await database.dispose();
      disposed = true;
      await expectLater(ordering.watchOrders().first, throwsA(anything));
    },
  );
}

Future<void> _createPublishedProduct(
  CatalogFacade catalog, {
  required int categoryId,
  required String title,
  required int priceMinorUnits,
}) async {
  final idsBefore = (await catalog.watchItems().first)
      .map((item) => item.id)
      .toSet();
  await catalog.createDraft(
    title: title,
    description: '$title description',
    priceMinorUnits: priceMinorUnits,
    currencyCode: 'USD',
    categoryId: categoryId,
  );
  final draft = (await catalog.watchItems().first).singleWhere(
    (item) => !idsBefore.contains(item.id),
  );
  await catalog.publishItem(id: draft.id, expectedRevision: draft.revision);
}
