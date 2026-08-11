import 'package:app_database/src/contexts/catalog/failures/catalog_store_exception.dart';
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
  final isContention = switch (sqliteError?.resultCode) {
    SqlError.SQLITE_BUSY || SqlError.SQLITE_LOCKED => true,
    _ => false,
  };
  if (isContention) {
    Error.throwWithStackTrace(const CatalogStoreException(), stackTrace);
  }
  Error.throwWithStackTrace(error, stackTrace);
}
