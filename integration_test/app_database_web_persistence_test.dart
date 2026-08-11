import 'package:app_database/app_database_composition.dart';
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

    for (final item in items) {
      await reopened.stores.catalog.items.deleteItem(item.id);
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
