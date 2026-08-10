import 'package:app_database/src/contexts/catalog/items/dao/catalog_items_dao.dart';
import 'package:drift/drift.dart';

part 'application_database.g.dart';

/// Internal shared physical Drift database owned by the database module.
@DriftDatabase(
  include: <String>{'tables.drift'},
  daos: <Type>[CatalogItemsDao],
)
final class ApplicationDatabase extends _$ApplicationDatabase {
  /// Creates a database over an explicitly supplied executor.
  ApplicationDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
  );
}
