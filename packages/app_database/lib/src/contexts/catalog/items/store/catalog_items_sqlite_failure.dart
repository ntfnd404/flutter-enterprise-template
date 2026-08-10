import 'package:app_database/src/contexts/catalog/items/store/catalog_items_store_exception.dart';
import 'package:sqlite3/common.dart';

/// Translates only temporary SQLite contention into an expected store failure.
///
/// Every other SQLite failure remains unexpected and is rethrown as the same
/// object with its original stack. Constraint, corruption, read-only,
/// disk-full, and I/O failures are never ordinary temporary unavailability.
Never throwCatalogItemsSqliteFailure({
  required Object error,
  required SqliteException? sqliteError,
  required StackTrace stackTrace,
}) {
  switch (sqliteError?.resultCode) {
    case SqlError.SQLITE_BUSY:
    case SqlError.SQLITE_LOCKED:
      Error.throwWithStackTrace(
        const CatalogItemsStoreException(),
        stackTrace,
      );
    default:
      Error.throwWithStackTrace(error, stackTrace);
  }
}
