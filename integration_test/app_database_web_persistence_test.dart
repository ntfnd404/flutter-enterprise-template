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
    await first.catalogItemsStore.insertItem(title);
    await first.dispose();

    final reopened = createAppDatabaseModule(
      configuration: configuration.value,
    );
    addTearDown(reopened.dispose);
    await reopened.initialize();

    final items = await reopened.catalogItemsStore.watchItems().first;
    expect(items.any((item) => item.title == title), isTrue);

    for (final item in items) {
      await reopened.catalogItemsStore.deleteItem(item.id);
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
