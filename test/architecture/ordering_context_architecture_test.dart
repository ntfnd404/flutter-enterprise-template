import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test(
    'Ordering domain and application do not depend on upstream contexts',
    () {
      const forbidden = <String>[
        'package:app_database/',
        'package:catalog/',
        'package:drift/',
        'package:flutter/',
        'package:sqlite3/',
        'package:template/',
      ];
      final roots = <String>[
        'packages/bounded_contexts/ordering/lib/src/domain',
        'packages/bounded_contexts/ordering/lib/src/application',
      ];
      final offenders = roots
          .expand(dartFiles)
          .where((file) {
            final contents = file.readAsStringSync();

            return forbidden.any(contents.contains);
          })
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    },
  );

  test('only Ordering Catalog ACL imports Published Language', () {
    final offenders = dartFiles('packages/bounded_contexts/ordering/lib')
        .where(
          (file) => file.readAsStringSync().contains(
            'package:catalog/catalog_product_offers.dart',
          ),
        )
        .where(
          (file) => !file.path.contains(
            '/src/infrastructure/integration/catalog/',
          ),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('database seam is isolated to infrastructure and composition', () {
    final offenders = dartFiles('packages/bounded_contexts/ordering/lib')
        .where(
          (file) => file.readAsStringSync().contains(
            'package:app_database/stores/ordering.dart',
          ),
        )
        .where(
          (file) =>
              !file.path.contains('/src/infrastructure/') &&
              !file.path.contains('/src/composition/'),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('Ordering keeps ports and upstream adapters in their owning layers', () {
    expect(
      File(
        'packages/bounded_contexts/ordering/lib/src/domain/order_repository.dart',
      ).existsSync(),
      isFalse,
    );
    expect(
      File(
        'packages/bounded_contexts/ordering/lib/src/domain/repository/order_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/bounded_contexts/ordering/lib/src/infrastructure/persistence/'
        'store_order_repository.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'packages/bounded_contexts/ordering/lib/src/infrastructure/integration/'
        'catalog/'
        'catalog_product_offer_adapter.dart',
      ).existsSync(),
      isTrue,
    );
  });

  test('Ordering production code imports no foreign package src API', () {
    final offenders = <String>[];
    final packageImport = RegExp(r'package:([^/]+)/src/');
    for (final file in dartFiles('packages/bounded_contexts/ordering/lib')) {
      for (final match in packageImport.allMatches(file.readAsStringSync())) {
        if (match.group(1) != 'ordering') {
          offenders.add(file.path);
          break;
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('Ordering remains Flutter-free and exposes an exact public API', () {
    final manifest = File(
      'packages/bounded_contexts/ordering/pubspec.yaml',
    ).readAsStringSync();
    final publicApi = File(
      'packages/bounded_contexts/ordering/lib/ordering.dart',
    ).readAsStringSync();
    final exports = RegExp(
      "export '([^']+)'",
    ).allMatches(publicApi).map((match) => match.group(1)).toSet();
    final offenders = dartFiles('packages/bounded_contexts/ordering/lib')
        .where((file) {
          final contents = file.readAsStringSync();

          return contents.contains("import 'dart:developer'") ||
              contents.contains("import 'package:flutter/") ||
              contents.contains("import 'package:drift/") ||
              contents.contains("import 'package:logger/") ||
              contents.contains("import 'package:logging/") ||
              contents.contains("import 'package:talker/");
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
    expect(
      RegExp(r'^  flutter:\s*$', multiLine: true).hasMatch(manifest),
      isFalse,
    );
    expect(exports, <String>{
      'src/application/order_line_input.dart',
      'src/application/ordering_facade.dart',
      'src/domain/order/order.dart',
      'src/domain/order/order_line.dart',
      'src/domain/order/value_objects/catalog_offer_revision.dart',
      'src/domain/order/value_objects/catalog_product_reference.dart',
      'src/domain/order/value_objects/order_currency.dart',
      'src/domain/order/value_objects/order_id.dart',
      'src/domain/order/value_objects/order_line_quantity.dart',
      'src/domain/order/value_objects/order_money.dart',
      'src/domain/order/value_objects/order_product_title.dart',
      'src/domain/order/value_objects/order_revision.dart',
      'src/domain/order/value_objects/order_status.dart',
      'src/domain/order/value_objects/order_unit_price.dart',
      'src/domain/ordering_exception.dart',
    });
    expect(publicApi, isNot(contains('order_repository.dart')));
    expect(publicApi, isNot(contains('/infrastructure/')));
    expect(publicApi, isNot(contains('/composition/')));
  });

  test('Ordering composition exposes only required construction seams', () {
    final compositionApi = File(
      'packages/bounded_contexts/ordering/lib/ordering_composition.dart',
    ).readAsStringSync();
    final exports = RegExp(
      "export '([^']+)'",
    ).allMatches(compositionApi).map((match) => match.group(1)).toSet();

    expect(exports, <String>{
      'src/application/ordering_utc_now.dart',
      'src/application/product_offers/order_product_offer.dart',
      'src/application/product_offers/product_offer_provider.dart',
      'src/composition/ordering_factory.dart',
      'src/infrastructure/integration/catalog/catalog_product_offer_adapter.dart',
    });
    expect(compositionApi, contains('show OrderProductOffer'));
    expect(compositionApi, contains('show ProductOfferProvider'));
    expect(compositionApi, isNot(contains('StoreOrderRepository')));
    expect(compositionApi, isNot(contains('OrderingService')));
    expect(compositionApi, isNot(contains('OrderingOrdersStore')));
  });

  test('accepted Context Map records the actual Catalog relationship', () {
    final contextMap = File(
      'architecture/context_map.yaml',
    ).readAsStringSync();

    expect(contextMap, contains('name: ordering'));
    expect(contextMap, contains('upstream: catalog'));
    expect(contextMap, contains('downstream: ordering'));
    expect(contextMap, contains('relationship: customer_supplier'));
    expect(contextMap, contains('public_contract: catalog_product_offers'));
    expect(contextMap, contains('contract_pattern: published_language'));
    expect(
      contextMap,
      contains('downstream_translation: anti_corruption_layer'),
    );
    expect(contextMap, contains('integration_mode: synchronous_query'));
    expect(contextMap, contains('cross_context_atomicity: none'));
    expect(contextMap, contains('consistency_model: point_in_time_snapshot'));
  });

  test('root production imports Ordering composition only from app DI', () {
    final offenders = dartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains(
            'package:ordering/ordering_composition.dart',
          ),
        )
        .where((file) => !file.path.startsWith('lib/app/di/'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
