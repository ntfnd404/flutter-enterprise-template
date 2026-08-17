import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ordering/ordering.dart';
import 'package:template/app/di/app_dependencies_factory.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/environment/storage/app_storage_configuration.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test('wires Database, Catalog, and Ordering in one owned graph', () async {
    final databaseDirectory = await Directory.systemTemp.createTemp(
      'template-catalog-test-',
    );
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProvider,
      (call) async => switch (call.method) {
        'getTemporaryDirectory' => databaseDirectory.path,
        'getApplicationDocumentsDirectory' => databaseDirectory.path,
        'getApplicationSupportDirectory' => databaseDirectory.path,
        _ => null,
      },
    );
    addTearDown(() async {
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProvider,
        null,
      );
      await databaseDirectory.delete(recursive: true);
    });

    final graph = await buildAppDependencyGraph(
      dependenciesFactory: (resources) => buildAppDependencies(
        resources,
        storageConfiguration: AppStorageConfiguration.fromValues(
          namespace: 'test',
        ),
      ),
      captureRollbackFailure: (_, _) {},
    );
    addTearDown(graph.dispose);

    await graph.dependencies.catalog.createCategory('Hardware');
    final category =
        (await graph.dependencies.catalog.watchCategories().first).single;
    await graph.dependencies.catalog.createDraft(
      title: 'First product',
      description: 'First description',
      priceMinorUnits: 100,
      currencyCode: 'USD',
      categoryId: category.id,
    );
    await graph.dependencies.catalog.createDraft(
      title: 'Second product',
      description: 'Second description',
      priceMinorUnits: 200,
      currencyCode: 'USD',
      categoryId: category.id,
    );
    final products = await graph.dependencies.catalog.watchItems().first;
    expect(products, hasLength(2));
    for (final product in products) {
      await graph.dependencies.catalog.publishItem(
        id: product.id,
        expectedRevision: product.revision,
      );
    }
    final publishedProducts = await graph.dependencies.catalog
        .watchItems()
        .first;

    final orderId = await graph.dependencies.ordering.createDraft();
    await graph.dependencies.ordering.replaceDraftLines(
      orderId: orderId,
      lines: <OrderLineInput>[
        OrderLineInput(productId: publishedProducts[0].id, quantity: 2),
        OrderLineInput(productId: publishedProducts[1].id, quantity: 1),
      ],
    );
    await graph.dependencies.catalog.updatePublishedOffer(
      id: publishedProducts[0].id,
      expectedRevision: publishedProducts[0].revision,
      title: 'First product revised',
      description: 'Current description',
      priceMinorUnits: 300,
      currencyCode: 'USD',
      categoryId: category.id,
    );

    await graph.dependencies.ordering.placeOrder(orderId);
    final placed = await graph.dependencies.ordering.watchOrder(orderId).first;
    expect(placed.money!.minorUnits, 800);
    expect(placed.lines.first.title.value, 'First product revised');
    expect(placed.lines.first.catalogRevision.value, 2);

    final revisedProduct = (await graph.dependencies.catalog.watchItems().first)
        .firstWhere((item) => item.id == publishedProducts[0].id);
    await graph.dependencies.catalog.updatePublishedOffer(
      id: revisedProduct.id,
      expectedRevision: revisedProduct.revision,
      title: 'Changed after placement',
      description: 'Later description',
      priceMinorUnits: 900,
      currencyCode: 'USD',
      categoryId: category.id,
    );
    final unchanged = await graph.dependencies.ordering
        .watchOrder(orderId)
        .first;
    expect(unchanged.lines.first.title.value, 'First product revised');
    expect(unchanged.money!.minorUnits, 800);

    await graph.dependencies.ordering.cancelOrder(orderId);
    final cancelled = await graph.dependencies.ordering
        .watchOrder(orderId)
        .first;
    expect(cancelled.status, OrderStatus.cancelled);
  });
}
