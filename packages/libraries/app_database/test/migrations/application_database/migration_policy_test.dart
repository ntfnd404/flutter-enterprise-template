import 'package:app_database/src/application_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';

import '../drift/application_database/generated/schema.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('fresh database enables foreign-key enforcement', () async {
    final database = ApplicationDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    await database.customSelect('SELECT 1').getSingle();

    expect(await _pragmaInt(database, 'foreign_keys'), 1);
  });

  for (final oldVersion in <int>[1, 2]) {
    test('successful v$oldVersion upgrade enables foreign keys', () async {
      final schema = await verifier.schemaAt(oldVersion);
      addTearDown(schema.close);
      final database = ApplicationDatabase(schema.newConnection());
      addTearDown(database.close);

      await database.customSelect('SELECT 1').getSingle();

      expect(await _pragmaInt(database, 'foreign_keys'), 1);
      expect(await _pragmaInt(database, 'user_version'), 3);
    });
  }

  test('a stale binary fails closed against a newer schema', () async {
    final schema = await verifier.schemaAt(3);
    addTearDown(schema.close);
    schema.rawDatabase.userVersion = 4;
    final database = ApplicationDatabase(schema.newConnection());
    addTearDown(database.close);

    await expectLater(
      database.customSelect('SELECT 1').getSingle(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Application database schema downgrade is unsupported.',
        ),
      ),
    );

    expect(schema.rawDatabase.userVersion, 4);
  });

  test(
    'foreign-key violation rolls back the complete v2 to v3 upgrade',
    () async {
      final schema = await verifier.schemaAt(2);
      addTearDown(schema.close);
      schema.rawDatabase.execute(
        'INSERT INTO catalog_items ('
        'id, title, description, price_minor_units, currency_code, '
        'status_value, category_id, revision'
        ") VALUES (1, 'Orphan', '', 0, 'XXX', 0, 404, 0)",
      );
      final database = ApplicationDatabase(schema.newConnection());
      addTearDown(database.close);

      await expectLater(
        database.customSelect('SELECT 1').getSingle(),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Application database foreign-key validation failed.',
          ),
        ),
      );

      expect(schema.rawDatabase.userVersion, 2);
      expect(
        schema.rawDatabase.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('ordering_orders', 'ordering_order_lines')",
        ),
        isEmpty,
      );
    },
  );
}

Future<int> _pragmaInt(ApplicationDatabase database, String pragma) async {
  final result = await database.customSelect('PRAGMA $pragma').getSingle();

  return result.read<int>(pragma);
}
