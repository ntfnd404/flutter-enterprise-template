import 'package:app_database/app_database_composition.dart';
import 'package:app_database/stores/ordering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Web database survives module recreation', (tester) async {
    const configuration = _WebDatabaseConfiguration();
    final title = 'Persistence probe ${DateTime.now().microsecondsSinceEpoch}';

    final first = createAppDatabaseModule(
      configuration: configuration.value,
    );
    addTearDown(first.dispose);
    await first.initialize();
    final itemId = await first.stores.catalog.items.insertItem(
      title: title,
      description: 'Web persistence description',
      priceMinorUnits: 100,
      currencyCode: 'USD',
      categoryId: null,
    );
    expect(
      await first.stores.catalog.items.updateDraft(
        id: itemId,
        expectedRevision: 0,
        title: title,
        description: 'Revised Web persistence description',
        priceMinorUnits: 200,
        currencyCode: 'EUR',
        categoryId: null,
      ),
      1,
    );
    final orderId = await first.stores.ordering.orders.insertDraft(
      createdAtUtcMilliseconds: 1700000000000,
    );
    expect(
      await first.stores.ordering.orders.replaceDraftLines(
        id: orderId,
        expectedRevision: 0,
        totalMinorUnits: 400,
        currencyCode: 'EUR',
        lines: <StoredOrderLine>[
          StoredOrderLine(
            catalogProductId: itemId,
            productTitleSnapshot: title,
            unitPriceMinorUnits: 200,
            currencyCode: 'EUR',
            quantity: 2,
            catalogRevision: 1,
          ),
        ],
      ),
      1,
    );
    await first.dispose();

    final reopened = createAppDatabaseModule(
      configuration: configuration.value,
    );
    addTearDown(reopened.dispose);
    await reopened.initialize();

    final items = await reopened.stores.catalog.items.watchItems().first;
    final persisted = items.singleWhere((item) => item.id == itemId);
    expect(persisted.title, title);
    expect(persisted.description, 'Revised Web persistence description');
    expect(persisted.priceMinorUnits, 200);
    expect(persisted.currencyCode, 'EUR');
    expect(persisted.revision, 1);
    final persistedOrder = await reopened.stores.ordering.orders.getOrder(
      orderId,
    );
    expect(persistedOrder, isNotNull);
    expect(persistedOrder!.revision, 1);
    expect(persistedOrder.totalMinorUnits, 400);
    expect(persistedOrder.lines.single.catalogProductId, itemId);
    expect(persistedOrder.lines.single.productTitleSnapshot, title);

    expect(
      await reopened.stores.ordering.orders.cancelOrder(
        id: orderId,
        expectedRevision: 1,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      1,
    );
    final cancelledOrder = await reopened.stores.ordering.orders.getOrder(
      orderId,
    );
    expect(cancelledOrder!.statusValue, 2);
    expect(cancelledOrder.revision, 2);
    expect(cancelledOrder.cancelledAtUtcMilliseconds, 1700000001000);

    for (final item in items) {
      await reopened.stores.catalog.items.deleteDraft(
        id: item.id,
        expectedRevision: item.revision,
      );
    }
  });
}

final class _WebDatabaseConfiguration {
  const _WebDatabaseConfiguration();

  AppDatabaseConfiguration get value => AppDatabaseConfiguration(
    databaseName: 'template_web_persistence_test',
    webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
  );
}
