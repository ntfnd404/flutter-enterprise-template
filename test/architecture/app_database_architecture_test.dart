import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('workspace packages follow the enterprise package taxonomy', () {
    final packageGroups =
        Directory('packages')
            .listSync()
            .whereType<Directory>()
            .map((directory) => directory.path)
            .toList()
          ..sort();
    final packageManifests =
        Directory('packages')
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('/pubspec.yaml'))
            .map((file) => file.path)
            .toList()
          ..sort();

    expect(packageGroups, <String>[
      'packages/bounded_contexts',
      'packages/libraries',
    ]);
    expect(packageManifests, isNotEmpty);
    expect(
      packageManifests.where(
        (path) =>
            !path.startsWith('packages/bounded_contexts/') &&
            !path.startsWith('packages/libraries/'),
      ),
      isEmpty,
    );
    expect(Directory('packages/app_database').existsSync(), isFalse);
    expect(Directory('packages/catalog').existsSync(), isFalse);
    expect(Directory('packages/ordering').existsSync(), isFalse);
  });

  test('application database public APIs hide provider internals', () {
    final contextContents = <String>[
      'packages/libraries/app_database/lib/stores/catalog.dart',
      'packages/libraries/app_database/lib/stores/ordering.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');
    final compositionContents = File(
      'packages/libraries/app_database/lib/app_database_composition.dart',
    ).readAsStringSync();
    final publicContents = '$compositionContents\n$contextContents';

    expect(publicContents, contains('catalog_items_store.dart'));
    expect(publicContents, contains('stored_catalog_item.dart'));
    expect(publicContents, contains('app_database_module.dart'));
    expect(publicContents, contains('app_database_stores.dart'));
    expect(contextContents, contains('catalog_database_stores.dart'));
    expect(publicContents, contains('ordering_orders_store.dart'));
    expect(contextContents, contains('ordering_database_stores.dart'));
    expect(publicContents, contains('stored_order.dart'));
    expect(publicContents, isNot(contains('application_database.dart')));
    expect(publicContents, isNot(contains('/dao/')));
    expect(contextContents, isNot(contains('/connection/')));
    expect(publicContents, isNot(contains('.g.dart')));
  });

  test('public store entrypoints are grouped by persistence owner', () {
    final storeEntrypoints = Directory(
      'packages/libraries/app_database/lib/stores',
    ).listSync().whereType<File>().map((file) => file.path).toList()..sort();

    expect(storeEntrypoints, <String>[
      'packages/libraries/app_database/lib/stores/catalog.dart',
      'packages/libraries/app_database/lib/stores/ordering.dart',
    ]);
    expect(
      Directory('packages/libraries/app_database/lib/contexts').existsSync(),
      isFalse,
    );
    expect(
      Directory(
        'packages/libraries/app_database/lib/src/contexts',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/libraries/app_database/lib/app_database_catalog.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/libraries/app_database/lib/app_database_ordering.dart',
      ).existsSync(),
      isFalse,
    );
  });

  test('application database remains app and Flutter neutral', () {
    const forbidden = <String>[
      "import 'dart:ui'",
      'package:catalog/',
      'package:drift_flutter/',
      'package:flutter/',
      'package:template/',
    ];
    final offenders = dartFiles('packages/libraries/app_database/lib')
        .where((file) {
          final contents = file.readAsStringSync();

          return forbidden.any(contents.contains);
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('application database does not import another package src API', () {
    final offenders = <String>[];
    final packageImport = RegExp(r'package:([^/]+)/src/');

    for (final file in dartFiles('packages/libraries/app_database/lib')) {
      final contents = file.readAsStringSync();
      for (final match in packageImport.allMatches(contents)) {
        if (match.group(1) != 'app_database') {
          offenders.add(file.path);
          break;
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('only application DI imports the database composition API', () {
    final offenders = dartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains(
            'package:app_database/app_database_composition.dart',
          ),
        )
        .where((file) => !file.path.startsWith('lib/app/di/'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('database module publishes typed lifecycle-free context stores', () {
    final module = File(
      'packages/libraries/app_database/lib/src/app_database_module.dart',
    ).readAsStringSync();
    final rootStores = File(
      'packages/libraries/app_database/lib/src/app_database_stores.dart',
    ).readAsStringSync();
    final catalogStores = File(
      'packages/libraries/app_database/lib/src/persistence/catalog/'
      'catalog_database_stores.dart',
    ).readAsStringSync();
    final orderingStores = File(
      'packages/libraries/app_database/lib/src/persistence/ordering/'
      'ordering_database_stores.dart',
    ).readAsStringSync();
    final compositionEntrypoint = File(
      'packages/libraries/app_database/lib/app_database_composition.dart',
    ).readAsStringSync();
    final catalogEntrypoint = File(
      'packages/libraries/app_database/lib/stores/catalog.dart',
    ).readAsStringSync();
    final orderingEntrypoint = File(
      'packages/libraries/app_database/lib/stores/ordering.dart',
    ).readAsStringSync();
    final databaseSources = dartFiles(
      'packages/libraries/app_database/lib',
    ).map((file) => file.readAsStringSync()).join('\n');
    final acceptedContextSources = dartFiles(
      'packages/bounded_contexts/catalog/lib',
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(module, contains('AppDatabaseStores? _stores'));
    expect(module, contains('AppDatabaseStores get stores'));
    expect(module, contains('createAppDatabaseStores(database)'));
    expect(module, isNot(contains('CatalogItemsStore')));
    expect(module, isNot(contains('CatalogCategoriesStore')));
    expect(module, isNot(contains('OrderingOrdersStore')));
    expect(module, isNot(contains('DriftCatalog')));
    expect(module, isNot(contains('DriftOrdering')));
    expect(databaseSources, isNot(contains('catalogItemsStore')));
    expect(databaseSources, isNot(contains('catalogCategoriesStore')));
    expect(databaseSources, isNot(contains('orderingOrdersStore')));

    expect(rootStores, contains('final CatalogDatabaseStores catalog'));
    expect(rootStores, contains('final OrderingDatabaseStores ordering'));
    expect(catalogStores, contains('final CatalogItemsStore items'));
    expect(catalogStores, contains('final CatalogCategoriesStore categories'));
    expect(orderingStores, contains('final OrderingOrdersStore orders'));
    for (final source in <String>[
      rootStores,
      catalogStores,
      orderingStores,
    ]) {
      expect(source, isNot(contains('Map<Type')));
      expect(source, isNot(contains('operator []')));
      expect(source, isNot(contains('get<T>')));
      expect(source, isNot(contains('dispose(')));
      expect(source, isNot(contains('ChangeNotifier')));
      expect(source, isNot(contains('ValueNotifier')));
    }

    expect(
      compositionEntrypoint,
      contains('show AppDatabaseStores'),
    );
    expect(
      compositionEntrypoint,
      isNot(contains('createAppDatabaseStores')),
    );
    expect(catalogEntrypoint, contains('show CatalogDatabaseStores'));
    expect(
      catalogEntrypoint,
      isNot(contains('createCatalogDatabaseStores')),
    );
    expect(orderingEntrypoint, contains('show OrderingDatabaseStores'));
    expect(
      orderingEntrypoint,
      isNot(contains('createOrderingDatabaseStores')),
    );
    expect(acceptedContextSources, isNot(contains('AppDatabaseStores')));
    expect(acceptedContextSources, isNot(contains('CatalogDatabaseStores')));
    expect(acceptedContextSources, isNot(contains('OrderingDatabaseStores')));
  });

  test('owned persistence slices use the declared cluster structure', () {
    const persistenceRoot =
        'packages/libraries/app_database/lib/src/persistence';
    const allowedKinds = <String>{'tables', 'queries', 'dao', 'store'};
    final offenders = Directory(persistenceRoot)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final relativePath = file.path.substring(persistenceRoot.length + 1);
          final segments = relativePath.split('/');
          final isContextFailure =
              segments.length == 3 && segments[1] == 'failures';
          final isContextAssembly =
              segments.length == 2 &&
              segments[1] == '${segments[0]}_database_stores.dart';

          return !isContextFailure &&
              !isContextAssembly &&
              (segments.length < 4 || !allowedKinds.contains(segments[2]));
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
    expect(
      Directory('packages/libraries/app_database/lib/src/catalog').existsSync(),
      isFalse,
    );
  });

  test('root schema contains only versioned migration snapshots', () {
    const schemaRoot = 'packages/libraries/app_database/lib/src/schema';
    final offenders = Directory(schemaRoot)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => !file.path.endsWith('.json'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('migration tooling separates authored and Drift-owned tests', () {
    final buildConfiguration = File(
      'packages/libraries/app_database/build.yaml',
    ).readAsStringSync();
    expect(
      File(
        'packages/libraries/app_database/test/migrations/application_database/'
        'schema_consistency_test.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        'packages/libraries/app_database/test/migrations/drift/application_database/'
        'generated',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/libraries/app_database/test/migrations/drift/application_database/'
        'migration_test.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      buildConfiguration,
      contains('test_dir: test/migrations/drift'),
    );
    expect(
      Directory(
        'packages/libraries/app_database/test/migrations/application_database/generated',
      ).existsSync(),
      isFalse,
    );
  });

  test('authored migrations are isolated from the current schema', () {
    const migrationsRoot = 'packages/libraries/app_database/lib/src/migrations';
    final migrationFiles = dartFiles(migrationsRoot).toList();
    final applicationDatabase = File(
      'packages/libraries/app_database/lib/src/application_database.dart',
    ).readAsStringSync();
    final contextMigrationDirectories =
        Directory(
              'packages/libraries/app_database/lib/src/persistence',
            )
            .listSync(recursive: true)
            .whereType<Directory>()
            .where((directory) => directory.path.endsWith('/migrations'))
            .map((directory) => directory.path)
            .toList();

    expect(
      migrationFiles.map((file) => file.path),
      unorderedEquals(<String>[
        '$migrationsRoot/application_database_migrations.dart',
        '$migrationsRoot/v1_to_v2_catalog_products.dart',
        '$migrationsRoot/v2_to_v3_ordering_orders.dart',
      ]),
    );
    expect(
      migrationFiles
          .where(
            (file) => file.readAsStringSync().contains(
              'src/application_database.dart',
            ),
          )
          .map((file) => file.path),
      isEmpty,
    );
    expect(applicationDatabase, isNot(contains('from1To2:')));
    expect(applicationDatabase, isNot(contains('from2To3:')));
    expect(applicationDatabase, contains('schemaVersion => 3'));
    expect(applicationDatabase, contains('OrderingOrdersDao'));
    expect(contextMigrationDirectories, isEmpty);
  });

  test('database package has no duplicate DAO ports or direct logging', () {
    final daoPorts = <String>[];
    final logging = <String>[];
    final daoPort = RegExp(r'abstract\s+interface\s+class\s+\w*Dao\b');

    for (final file in dartFiles('packages/libraries/app_database/lib')) {
      final contents = file.readAsStringSync();
      if (daoPort.hasMatch(contents)) {
        daoPorts.add(file.path);
      }
      if (contents.contains("import 'dart:developer'") ||
          contents.contains("import 'package:logging/") ||
          contents.contains("import 'package:logger/") ||
          contents.contains("import 'package:talker/")) {
        logging.add(file.path);
      }
    }

    expect(daoPorts, isEmpty);
    expect(logging, isEmpty);
  });

  test('Catalog persistence exposes intent-specific lifecycle commands', () {
    final store = File(
      'packages/libraries/app_database/lib/src/persistence/catalog/items/store/'
      'catalog_items_store.dart',
    ).readAsStringSync();
    final catalogSources = dartFiles(
      'packages/libraries/app_database/lib/src/persistence/catalog',
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(store, contains('publishDraft'));
    expect(store, contains('archivePublished'));
    expect(store, contains('deleteDraft'));
    expect(store, contains('required int expectedRevision'));
    expect(catalogSources, isNot(contains('setItemStatus')));
    expect(catalogSources, isNot(contains('deleteItem')));
    expect(catalogSources, isNot(contains('expectedStatusValue')));
  });

  test('Ordering persistence has no cross-context SQL foreign key', () {
    final lines = File(
      'packages/libraries/app_database/lib/src/persistence/ordering/orders/tables/'
      'order_lines.drift',
    ).readAsStringSync();

    expect(lines, contains('REFERENCES ordering_orders(id)'));
    expect(lines, isNot(contains('REFERENCES catalog_')));
    expect(lines, isNot(contains('JOIN catalog_')));
  });

  test('Ordering persistence exposes intent-specific conditional writes', () {
    final store = File(
      'packages/libraries/app_database/lib/src/persistence/ordering/orders/store/'
      'ordering_orders_store.dart',
    ).readAsStringSync();
    final storedLine = File(
      'packages/libraries/app_database/lib/src/persistence/ordering/orders/store/'
      'stored_order_line.dart',
    ).readAsStringSync();
    final orderingSources = dartFiles(
      'packages/libraries/app_database/lib/src/persistence/ordering',
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(store, contains('replaceDraftLines'));
    expect(store, contains('placeOrder'));
    expect(store, contains('cancelOrder'));
    expect(store, contains('required int expectedRevision'));
    expect(store, isNot(contains('expectedStatusValue')));
    expect(storedLine, isNot(contains('final int orderId')));
    expect(orderingSources, isNot(contains('setOrderStatus')));
    expect(orderingSources, isNot(contains('deleteOrder')));
  });
}
