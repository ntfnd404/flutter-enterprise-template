import 'package:app_database/src/contexts/catalog/categories/dao/catalog_categories_dao.dart';
import 'package:app_database/src/contexts/catalog/items/dao/catalog_items_dao.dart';
import 'package:app_database/src/migrations/application_database_migrations.dart';
import 'package:drift/drift.dart';

part 'application_database.g.dart';

/// Internal shared physical Drift database owned by the database module.
@DriftDatabase(
  include: <String>{'tables.drift'},
  daos: <Type>[
    CatalogCategoriesDao,
    CatalogItemsDao,
  ],
)
final class ApplicationDatabase extends _$ApplicationDatabase {
  /// Creates a database over an explicitly supplied executor.
  ApplicationDatabase(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: applicationDatabaseOnUpgrade,
    beforeOpen: (_) => _enableAndVerifyForeignKeys(),
  );

  Future<void> _enableAndVerifyForeignKeys() async {
    await customStatement('PRAGMA foreign_keys = ON');
    final result = await customSelect('PRAGMA foreign_keys').get();
    final isEnabled =
        result.length == 1 && result.single.read<int>('foreign_keys') == 1;

    if (!isEnabled) {
      throw StateError(
        'Application database foreign-key enforcement is unavailable.',
      );
    }
  }
}
