import 'package:app_database/src/application_database.steps.dart';
import 'package:drift/drift.dart';

/// Adds the persistent Ordering aggregate schema.
Future<void> migrateV2ToV3OrderingOrders(
  Migrator migrator,
  Schema3 schema,
) async {
  await migrator.createTable(schema.orderingOrders);
  await migrator.createTable(schema.orderingOrderLines);
}
