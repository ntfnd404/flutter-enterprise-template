import 'package:app_database/src/persistence/ordering/orders/store/ordering_store_exception.dart';
import 'package:app_database/src/sqlite/sqlite_failure_translation.dart';
import 'package:sqlite3/common.dart';

/// Translates only temporary SQLite contention for Ordering stores.
Never throwOrderingSqliteFailure({
  required Object error,
  required SqliteException? sqliteError,
  required StackTrace stackTrace,
}) => throwSqliteFailure(
  error: error,
  sqliteError: sqliteError,
  stackTrace: stackTrace,
  contentionFailure: OrderingStoreException.new,
);
