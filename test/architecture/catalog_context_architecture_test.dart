import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('catalog domain remains pure and independent of outer layers', () {
    const forbidden = <String>[
      'package:app_database/',
      'package:drift/',
      'package:flutter/',
      'package:sqlite3/',
      'package:template/',
      '/src/application/',
      '/src/composition/',
      '/src/infrastructure/',
    ];
    final offenders =
        dartFiles('packages/bounded_contexts/catalog/lib/src/domain')
            .where((file) {
              final contents = file.readAsStringSync();

              return forbidden.any(contents.contains);
            })
            .map((file) => file.path)
            .toList();

    expect(offenders, isEmpty);
  });

  test('catalog application does not import infrastructure or composition', () {
    const forbidden = <String>[
      'package:app_database/',
      'package:drift/',
      'package:flutter/',
      'package:sqlite3/',
      'package:template/',
      '/src/composition/',
      '/src/infrastructure/',
    ];
    final offenders =
        dartFiles('packages/bounded_contexts/catalog/lib/src/application')
            .where((file) {
              final contents = file.readAsStringSync();

              return forbidden.any(contents.contains);
            })
            .map((file) => file.path)
            .toList();

    expect(offenders, isEmpty);
  });

  test('database access is isolated in infrastructure and composition', () {
    final offenders = dartFiles('packages/bounded_contexts/catalog/lib')
        .where(
          (file) =>
              !file.path.contains('/src/infrastructure/') &&
              !file.path.contains('/src/composition/'),
        )
        .where(
          (file) => file.readAsStringSync().contains('package:app_database/'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('catalog production code does not import another package src API', () {
    final offenders = <String>[];
    final packageImport = RegExp(r'package:([^/]+)/src/');

    for (final file in dartFiles('packages/bounded_contexts/catalog/lib')) {
      final contents = file.readAsStringSync();
      for (final match in packageImport.allMatches(contents)) {
        if (match.group(1) != 'catalog') {
          offenders.add(file.path);
          break;
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('Catalog does not depend on downstream Ordering', () {
    final offenders = dartFiles('packages/bounded_contexts/catalog/lib')
        .where(
          (file) => file.readAsStringSync().contains('package:ordering/'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('catalog has no Flutter, provider, or logging dependency', () {
    const forbiddenImports = <String>[
      "import 'dart:developer'",
      "import 'package:drift/",
      "import 'package:flutter/",
      "import 'package:logger/",
      "import 'package:logging/",
      "import 'package:sqlite3/",
      "import 'package:talker/",
      "import 'package:template/",
    ];
    final offenders = dartFiles('packages/bounded_contexts/catalog/lib')
        .where((file) {
          final contents = file.readAsStringSync();

          return forbiddenImports.any(contents.contains);
        })
        .map((file) => file.path)
        .toList();
    final manifest = File(
      'packages/bounded_contexts/catalog/pubspec.yaml',
    ).readAsStringSync();

    expect(offenders, isEmpty);
    expect(
      RegExp(r'^  flutter:\s*$', multiLine: true).hasMatch(manifest),
      isFalse,
    );
    expect(
      RegExp(r'^  (drift|sqlite3):', multiLine: true).hasMatch(manifest),
      isFalse,
    );
  });

  test('catalog public API hides repository and persistence details', () {
    final publicApi = File(
      'packages/bounded_contexts/catalog/lib/catalog.dart',
    ).readAsStringSync();
    final exports = RegExp(
      "export '([^']+)'",
    ).allMatches(publicApi).map((match) => match.group(1)).toSet();

    expect(exports, <String>{
      'src/application/catalog_facade.dart',
      'src/domain/catalog_exception.dart',
      'src/domain/category/catalog_category.dart',
      'src/domain/category/value_objects/catalog_category_name.dart',
      'src/domain/item/catalog_item.dart',
      'src/domain/item/value_objects/catalog_item_description.dart',
      'src/domain/item/value_objects/catalog_item_price.dart',
      'src/domain/item/value_objects/catalog_item_revision.dart',
      'src/domain/item/value_objects/catalog_item_status.dart',
      'src/domain/item/value_objects/catalog_item_title.dart',
    });
    expect(publicApi, contains("export 'src/domain/catalog_exception.dart'"));
    expect(publicApi, isNot(contains('catalog_repository.dart')));
    expect(publicApi, isNot(contains('catalog_item_publication_policy.dart')));
    expect(publicApi, isNot(contains('CatalogProductOffer')));
    expect(publicApi, isNot(contains('CatalogOffer')));
    expect(publicApi, isNot(contains('/infrastructure/')));
    expect(publicApi, isNot(contains('/composition/')));
  });

  test('catalog composition exports only its factory entrypoint', () {
    final compositionApi = File(
      'packages/bounded_contexts/catalog/lib/catalog_composition.dart',
    ).readAsStringSync();
    final exports = RegExp(
      "export '([^']+)'",
    ).allMatches(compositionApi).map((match) => match.group(1)).toList();
    final factory = File(
      'packages/bounded_contexts/catalog/lib/src/composition/catalog_factory.dart',
    ).readAsStringSync();

    expect(exports, <String>[
      'src/composition/catalog_application.dart',
      'src/composition/catalog_factory.dart',
    ]);
    expect(compositionApi, contains('show CatalogApplication'));
    expect(compositionApi, contains('show createCatalogApplication'));
    expect(factory, contains('CatalogApplication createCatalogApplication'));
    expect(factory, contains('StoreCatalogItemRepository'));
    expect(factory, contains('StoreCatalogCategoryRepository'));
    expect(factory, contains('CatalogService'));
    expect(factory, contains('CatalogProductOfferService'));
    expect(factory, isNot(contains('implements CatalogFacade')));
  });

  test('Catalog Product Offers is a separate narrow entrypoint', () {
    final productOffersApi = File(
      'packages/bounded_contexts/catalog/lib/catalog_product_offers.dart',
    ).readAsStringSync();

    final exports = RegExp(
      "export '([^']+)'",
    ).allMatches(productOffersApi).map((match) => match.group(1)).toSet();
    expect(exports, <String>{
      'src/application/product_offers/catalog_offer_request_exception.dart',
      'src/application/product_offers/catalog_offer_unavailable_exception.dart',
      'src/application/product_offers/catalog_product_offer_reader.dart',
      'src/application/product_offers/catalog_product_offer_snapshot.dart',
    });
    expect(productOffersApi, isNot(contains('catalog_item.dart')));
    expect(productOffersApi, isNot(contains('catalog_repository.dart')));
    expect(productOffersApi, isNot(contains('CatalogPersistenceException')));
    expect(productOffersApi, isNot(contains('app_database')));
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/catalog_integration.dart',
      ).existsSync(),
      isFalse,
    );

    final offerSources = dartFiles(
      'packages/bounded_contexts/catalog/lib/src/application/product_offers',
    );
    final eventOffenders = offerSources
        .where((file) => file.readAsStringSync().contains('extends AppEvent'))
        .map((file) => file.path)
        .toList();
    expect(eventOffenders, isEmpty);
  });

  test('Catalog capabilities and repository ports use owning layers', () {
    expect(
      Directory(
        'packages/bounded_contexts/catalog/lib/src/product_offers',
      ).existsSync(),
      isFalse,
    );
    expect(
      Directory(
        'packages/bounded_contexts/catalog/lib/src/integration',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/application/product_offers/'
        'catalog_product_offer_reader.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/domain/catalog_repository.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/domain/repository/'
        'catalog_item_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/domain/repository/'
        'catalog_category_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory('packages/bounded_contexts/catalog/lib/src/data').existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/infrastructure/persistence/'
        'store_catalog_item_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/infrastructure/persistence/'
        'store_catalog_category_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/bounded_contexts/catalog/lib/src/infrastructure/persistence/'
        'catalog_persistence_failure_mapper.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test('root production imports catalog composition only from app DI', () {
    final offenders = dartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains(
            'package:catalog/catalog_composition.dart',
          ),
        )
        .where((file) => !file.path.startsWith('lib/app/di/'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
