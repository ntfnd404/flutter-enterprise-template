import 'package:app_database/src/persistence/ordering/orders/store/ordering_sqlite_failure.dart';
import 'package:app_database/src/persistence/ordering/orders/store/ordering_store_exception.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

void main() {
  test('maps busy and locked codes to an Ordering-owned failure', () {
    for (final code in <int>[
      SqlError.SQLITE_BUSY,
      SqlExtendedError.SQLITE_BUSY_RECOVERY,
      SqlExtendedError.SQLITE_BUSY_SNAPSHOT,
      SqlError.SQLITE_LOCKED,
      SqlExtendedError.SQLITE_LOCKED_SHAREDCACHE,
    ]) {
      final vendor = SqliteException(
        extendedResultCode: code,
        message: 'private vendor message',
      );
      final originalStack = StackTrace.fromString('ordering-sqlite-stack');

      try {
        throwOrderingSqliteFailure(
          error: vendor,
          sqliteError: vendor,
          stackTrace: originalStack,
        );
      } catch (error, stackTrace) {
        expect(error, isA<OrderingStoreException>());
        expect(identical(stackTrace, originalStack), isTrue);
        expect(error.toString(), isNot(contains('private vendor message')));
      }
    }
  });

  test('preserves unexpected SQLite failure identity and stack', () {
    final vendor = SqliteException(
      extendedResultCode: SqlError.SQLITE_CONSTRAINT,
      message: 'private vendor message',
    );
    final originalStack = StackTrace.fromString('ordering-sqlite-stack');

    try {
      throwOrderingSqliteFailure(
        error: vendor,
        sqliteError: vendor,
        stackTrace: originalStack,
      );
    } catch (error, stackTrace) {
      expect(identical(error, vendor), isTrue);
      expect(identical(stackTrace, originalStack), isTrue);
    }
  });

  test('preserves an unexpected wrapper without a SQLite cause', () {
    final wrapper = StateError('remote wrapper sentinel');
    final originalStack = StackTrace.fromString('ordering-remote-stack');

    try {
      throwOrderingSqliteFailure(
        error: wrapper,
        sqliteError: null,
        stackTrace: originalStack,
      );
    } catch (error, stackTrace) {
      expect(identical(error, wrapper), isTrue);
      expect(identical(stackTrace, originalStack), isTrue);
    }
  });
}
