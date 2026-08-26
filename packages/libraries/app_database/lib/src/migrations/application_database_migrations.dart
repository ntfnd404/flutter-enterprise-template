import 'package:app_database/src/application_database.steps.dart';
import 'package:app_database/src/migrations/v1_to_v2_catalog_products.dart';
import 'package:app_database/src/migrations/v2_to_v3_ordering_orders.dart';
import 'package:drift/drift.dart';

/// Applies the ordered migration chain for the shared physical database.
///
/// Each authored step uses the generated schema for its target version. The
/// whole requested upgrade is atomic, and foreign-key integrity is checked
/// before the transaction can commit.
Future<void> applicationDatabaseOnUpgrade(
  Migrator migrator,
  int from,
  int to,
) async {
  if (from > to) {
    throw StateError(
      'Application database schema downgrade is unsupported.',
    );
  }

  final database = migrator.database;

  // Run migration steps without foreign keys and re-enable them later
  // (https://drift.simonbinder.eu/docs/advanced-features/migrations/#tips)
  await database.customStatement('PRAGMA foreign_keys = OFF');
  await database.transaction<void>(() async {
    await migrator.runMigrationSteps(
      from: from,
      to: to,
      steps: migrationSteps(
        from1To2: migrateV1ToV2CatalogProducts,
        from2To3: migrateV2ToV3OrderingOrders,
      ),
    );

    final violations = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    if (violations.isNotEmpty) {
      throw StateError(
        'Application database foreign-key validation failed.',
      );
    }
  });
}
