import 'package:app_database/src/application_database.dart';
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';

import '../drift/application_database/generated/schema.dart';

void main() {
  test(
    'current runtime schema matches the latest committed snapshot',
    () async {
      final latestSnapshotVersion = GeneratedHelper.versions.last;
      final verifier = SchemaVerifier(GeneratedHelper());
      final database = ApplicationDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      expect(database.schemaVersion, latestSnapshotVersion);
      await verifier.migrateAndValidate(
        database,
        latestSnapshotVersion,
        options: const ValidationOptions(validateDropped: true),
      );
    },
  );
}
