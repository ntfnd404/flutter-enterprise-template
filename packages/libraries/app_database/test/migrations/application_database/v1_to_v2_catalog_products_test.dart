// dart format width=80
import 'package:app_database/src/application_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

import '../drift/application_database/generated/schema.dart';
import '../drift/application_database/generated/schema_v1.dart' as v1;
import '../drift/application_database/generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('v1 items become incomplete v2 product drafts', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: ApplicationDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.catalogItems, const <v1.CatalogItemsData>[
          v1.CatalogItemsData(
            id: 1,
            title: 'Legacy draft',
            isCompleted: 0,
          ),
          v1.CatalogItemsData(
            id: 2,
            title: 'Legacy completed item',
            isCompleted: 1,
          ),
        ]);
      },
      validateItems: (newDb) async {
        final items = await newDb
            .customSelect(
              'SELECT id, title, description, price_minor_units, '
              'currency_code, status_value, category_id, revision '
              'FROM catalog_items ORDER BY id',
            )
            .get();

        expect(items, hasLength(2));
        expect(
          items.map(_catalogItemValues).toList(),
          <Map<String, Object?>>[
            <String, Object?>{
              'id': 1,
              'title': 'Legacy draft',
              'description': '',
              'price_minor_units': 0,
              'currency_code': 'XXX',
              'status_value': 0,
              'category_id': null,
              'revision': 0,
            },
            <String, Object?>{
              'id': 2,
              'title': 'Legacy completed item',
              'description': '',
              'price_minor_units': 0,
              'currency_code': 'XXX',
              'status_value': 0,
              'category_id': null,
              'revision': 0,
            },
          ],
        );
        expect(await newDb.select(newDb.catalogCategories).get(), isEmpty);
      },
    );
  });

  test('normalizes recoverable legacy title whitespace', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 2,
      createOld: v1.DatabaseAtV1.new,
      createNew: v2.DatabaseAtV2.new,
      openTestedDatabase: ApplicationDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.catalogItems,
          const v1.CatalogItemsData(
            id: 1,
            title: '\u2003Legacy product\u2003',
            isCompleted: 0,
          ),
        );
      },
      validateItems: (newDb) async {
        final title = await newDb
            .customSelect('SELECT title FROM catalog_items WHERE id = 1')
            .getSingle()
            .then((row) => row.read<String>('title'));

        expect(title, 'Legacy product');
      },
    );
  });

  for (final fixture in <(String, String)>[
    ('whitespace-only', '   '),
    ('over-120-grapheme', List<String>.filled(121, '🧑🏽‍💻').join()),
  ]) {
    test('rejects ${fixture.$1} legacy titles atomically', () async {
      await _expectLegacyTitleMigrationRejected(
        verifier: verifier,
        title: fixture.$2,
      );
    });
  }

  test('continues an uninterrupted AUTOINCREMENT sequence', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
    await oldDatabase.batch((batch) {
      batch.insertAll(oldDatabase.catalogItems, const <v1.CatalogItemsData>[
        v1.CatalogItemsData(id: 1, title: 'First', isCompleted: 0),
        v1.CatalogItemsData(id: 2, title: 'Second', isCompleted: 0),
      ]);
    });
    await oldDatabase.close();

    final migratedDatabase = ApplicationDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migratedDatabase, 2);
    await migratedDatabase.close();

    final currentDatabase = v2.DatabaseAtV2(schema.newConnection());
    addTearDown(currentDatabase.close);
    final nextId = await currentDatabase
        .into(currentDatabase.catalogItems)
        .insert(
          v2.CatalogItemsCompanion.insert(title: 'After migration'),
        );

    expect(nextId, 3);
  });

  test('does not reuse a deleted maximum AUTOINCREMENT ID', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
    await oldDatabase.batch((batch) {
      batch.insertAll(oldDatabase.catalogItems, const <v1.CatalogItemsData>[
        v1.CatalogItemsData(id: 1, title: 'First', isCompleted: 0),
        v1.CatalogItemsData(id: 2, title: 'Second', isCompleted: 0),
        v1.CatalogItemsData(id: 3, title: 'Deleted', isCompleted: 0),
      ]);
    });
    await (oldDatabase.delete(
      oldDatabase.catalogItems,
    )..where((table) => table.id.equals(3))).go();
    expect(await _sequence(oldDatabase), 3);
    await oldDatabase.close();

    final migratedDatabase = ApplicationDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migratedDatabase, 2);
    await migratedDatabase.close();

    final currentDatabase = v2.DatabaseAtV2(schema.newConnection());
    addTearDown(currentDatabase.close);
    final nextId = await currentDatabase
        .into(currentDatabase.catalogItems)
        .insert(
          v2.CatalogItemsCompanion.insert(title: 'After deletion'),
        );

    expect(nextId, 4);
  });

  test('preserves AUTOINCREMENT history after every row was deleted', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    final oldDatabase = v1.DatabaseAtV1(schema.newConnection());
    await oldDatabase.batch((batch) {
      batch.insertAll(oldDatabase.catalogItems, const <v1.CatalogItemsData>[
        v1.CatalogItemsData(id: 1, title: 'First', isCompleted: 0),
        v1.CatalogItemsData(id: 2, title: 'Second', isCompleted: 0),
      ]);
    });
    await oldDatabase.delete(oldDatabase.catalogItems).go();
    expect(await _sequence(oldDatabase), 2);
    await oldDatabase.close();

    final migratedDatabase = ApplicationDatabase(schema.newConnection());
    await verifier.migrateAndValidate(migratedDatabase, 2);
    await migratedDatabase.close();

    final currentDatabase = v2.DatabaseAtV2(schema.newConnection());
    addTearDown(currentDatabase.close);
    final nextId = await currentDatabase
        .into(currentDatabase.catalogItems)
        .insert(
          v2.CatalogItemsCompanion.insert(title: 'After complete deletion'),
        );

    expect(nextId, 3);
  });

  test(
    'does not invent sequence metadata for an unused legacy table',
    () async {
      final schema = await verifier.schemaAt(1);
      addTearDown(schema.close);
      expect(
        schema.rawDatabase.select(
          "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
        ),
        isEmpty,
      );

      final migratedDatabase = ApplicationDatabase(schema.newConnection());
      await verifier.migrateAndValidate(migratedDatabase, 2);
      await migratedDatabase.close();

      expect(
        schema.rawDatabase.select(
          "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
        ),
        isEmpty,
      );
    },
  );

  test('rolls back the complete v1 to v2 transition on copy failure', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    schema.rawDatabase
      ..execute('PRAGMA ignore_check_constraints = ON')
      ..execute(
        "INSERT INTO catalog_items(id, title, is_completed) VALUES (1, 'Valid', 0)",
      )
      ..execute(
        "INSERT INTO catalog_items(id, title, is_completed) VALUES (-1, 'Invalid ID', 0)",
      )
      ..execute('PRAGMA ignore_check_constraints = OFF');
    final sequenceBefore = schema.rawDatabase
        .select(
          "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
        )
        .single['seq'];
    final database = ApplicationDatabase(schema.newConnection());

    Object? migrationError;
    StackTrace? migrationStackTrace;
    try {
      await verifier.migrateAndValidate(database, 2);
      fail('Expected the invalid legacy row to abort the table migration.');
    } on Object catch (error, stackTrace) {
      migrationError = error;
      migrationStackTrace = stackTrace;
    } finally {
      await database.close();
    }

    expect(
      migrationError,
      isA<SqliteException>().having(
        (error) => error.resultCode,
        'resultCode',
        SqlError.SQLITE_CONSTRAINT,
      ),
    );
    expect(migrationStackTrace, isNotNull);
    expect(schema.rawDatabase.userVersion, 1);
    expect(
      schema.rawDatabase.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name = 'catalog_categories'",
      ),
      isEmpty,
    );
    final columnNames = schema.rawDatabase
        .select("PRAGMA table_info('catalog_items')")
        .map((row) => row['name'])
        .toList();
    expect(columnNames, contains('is_completed'));
    expect(columnNames, isNot(contains('description')));
    expect(
      schema.rawDatabase
          .select(
            'SELECT id, title, is_completed FROM catalog_items',
          )
          .map((row) => row['id']),
      contains(-1),
    );
    expect(
      schema.rawDatabase
          .select(
            "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
          )
          .single['seq'],
      sequenceBefore,
    );
  });
}

Future<void> _expectLegacyTitleMigrationRejected({
  required SchemaVerifier verifier,
  required String title,
}) async {
  final schema = await verifier.schemaAt(1);
  try {
    schema.rawDatabase.execute(
      'INSERT INTO catalog_items(id, title, is_completed) VALUES (?, ?, 0)',
      <Object?>[1, title],
    );
    final sequenceBefore = schema.rawDatabase
        .select(
          "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
        )
        .single['seq'];
    final database = ApplicationDatabase(schema.newConnection());

    try {
      await expectLater(
        verifier.migrateAndValidate(database, 2),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Legacy catalog data is incompatible with schema version 2.',
          ),
        ),
      );
    } finally {
      await database.close();
    }

    expect(schema.rawDatabase.userVersion, 1);
    expect(
      schema.rawDatabase.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' "
        "AND name = 'catalog_categories'",
      ),
      isEmpty,
    );
    expect(
      schema.rawDatabase
          .select('SELECT title FROM catalog_items WHERE id = 1')
          .single['title'],
      title,
    );
    expect(
      schema.rawDatabase
          .select(
            "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
          )
          .single['seq'],
      sequenceBefore,
    );
  } finally {
    schema.close();
  }
}

Future<int?> _sequence(GeneratedDatabase database) async {
  final rows = await database
      .customSelect(
        "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
      )
      .get();

  return rows.isEmpty ? null : rows.single.read<int>('seq');
}

Map<String, Object?> _catalogItemValues(QueryRow row) => <String, Object?>{
  'id': row.read<int>('id'),
  'title': row.read<String>('title'),
  'description': row.read<String>('description'),
  'price_minor_units': row.read<int>('price_minor_units'),
  'currency_code': row.read<String>('currency_code'),
  'status_value': row.read<int>('status_value'),
  'category_id': row.readNullable<int>('category_id'),
  'revision': row.read<int>('revision'),
};
