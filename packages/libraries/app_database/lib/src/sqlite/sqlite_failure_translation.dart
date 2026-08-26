import 'package:sqlite3/common.dart';

bool _isSqliteContention(SqliteException? error) => switch (error?.resultCode) {
  SqlError.SQLITE_BUSY || SqlError.SQLITE_LOCKED => true,
  _ => false,
};

/// Preserves unexpected vendor failures and translates only contention.
Never throwSqliteFailure({
  required Object error,
  required SqliteException? sqliteError,
  required StackTrace stackTrace,
  required Exception Function() contentionFailure,
}) {
  if (_isSqliteContention(sqliteError)) {
    Error.throwWithStackTrace(contentionFailure(), stackTrace);
  }
  Error.throwWithStackTrace(error, stackTrace);
}
