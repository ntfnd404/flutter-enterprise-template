import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/migrations/application_database_migrations.dart';
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

  test('successful upgrade enables foreign-key enforcement', () async {
    final schema = await verifier.schemaAt(1);
    addTearDown(schema.close);
    final database = ApplicationDatabase(schema.newConnection());
    addTearDown(database.close);

    await database.customSelect('SELECT 1').getSingle();

    expect(await _pragmaInt(database, 'foreign_keys'), 1);
    expect(await _pragmaInt(database, 'user_version'), 2);
  });

  test('downgrade is rejected without changing schema version', () async {
    final database = ApplicationDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    await database.customSelect('SELECT 1').getSingle();
    final before = await _pragmaInt(database, 'user_version');

    await expectLater(
      applicationDatabaseOnUpgrade(Migrator(database), 2, 1),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Application database schema downgrade is unsupported.',
        ),
      ),
    );

    expect(await _pragmaInt(database, 'user_version'), before);
    expect(await _pragmaInt(database, 'foreign_keys'), 1);
  });
}

Future<int> _pragmaInt(ApplicationDatabase database, String pragma) async {
  final result = await database.customSelect('PRAGMA $pragma').getSingle();

  return result.read<int>(pragma);
}
