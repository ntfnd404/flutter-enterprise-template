import 'package:app_database/src/persistence/catalog/failures/catalog_store_exception.dart';
import 'package:app_database/src/sqlite/sqlite_failure_translation.dart';
import 'package:sqlite3/common.dart';

/// Translates only temporary SQLite contention into an expected store failure.
///
/// Every other SQLite failure remains unexpected and is rethrown as the same
/// object with its original stack. Constraint, corruption, read-only,
/// disk-full, and I/O failures are never ordinary temporary unavailability.
Never throwCatalogSqliteFailure({
  required Object error,
  required SqliteException? sqliteError,
  required StackTrace stackTrace,
}) {
  throwSqliteFailure(
    error: error,
    sqliteError: sqliteError,
    stackTrace: stackTrace,
    contentionFailure: CatalogStoreException.new,
  );
}
