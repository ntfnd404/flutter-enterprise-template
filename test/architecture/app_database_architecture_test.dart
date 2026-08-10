import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('application database public APIs hide provider internals', () {
    final publicContents = <String>[
      'packages/app_database/lib/app_database_catalog.dart',
      'packages/app_database/lib/app_database_composition.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    expect(publicContents, contains('catalog_items_store.dart'));
    expect(publicContents, contains('stored_catalog_item.dart'));
    expect(publicContents, contains('app_database_module.dart'));
    expect(publicContents, isNot(contains('application_database.dart')));
    expect(publicContents, isNot(contains('/dao/')));
    expect(publicContents, isNot(contains('/connection/')));
    expect(publicContents, isNot(contains('.g.dart')));
  });

  test('application database remains app and Flutter neutral', () {
    const forbidden = <String>[
      "import 'dart:ui'",
      'package:catalog/',
      'package:drift_flutter/',
      'package:flutter/',
      'package:template/',
    ];
    final offenders = dartFiles('packages/app_database/lib')
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

    for (final file in dartFiles('packages/app_database/lib')) {
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

  test('context persistence uses the declared cluster structure', () {
    const contextsRoot = 'packages/app_database/lib/src/contexts';
    const allowedKinds = <String>{'tables', 'queries', 'dao', 'store'};
    final offenders = Directory(contextsRoot)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) {
          final relativePath = file.path.substring(contextsRoot.length + 1);
          final segments = relativePath.split('/');

          return segments.length < 4 || !allowedKinds.contains(segments[2]);
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
    expect(
      Directory('packages/app_database/lib/src/catalog').existsSync(),
      isFalse,
    );
  });

  test('root schema contains only versioned migration snapshots', () {
    const schemaRoot = 'packages/app_database/lib/src/schema';
    final offenders = Directory(schemaRoot)
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => !file.path.endsWith('.json'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('migration tooling uses one generated verifier path', () {
    expect(
      File(
        'packages/app_database/test/migrations/application_database/'
        'schema_consistency_test.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        'packages/app_database/test/migrations/application_database/generated',
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory('packages/app_database/test/migrations/generated').existsSync(),
      isFalse,
    );
  });

  test('database package has no duplicate DAO ports or direct logging', () {
    final daoPorts = <String>[];
    final logging = <String>[];
    final daoPort = RegExp(r'abstract\s+interface\s+class\s+\w*Dao\b');

    for (final file in dartFiles('packages/app_database/lib')) {
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
}
