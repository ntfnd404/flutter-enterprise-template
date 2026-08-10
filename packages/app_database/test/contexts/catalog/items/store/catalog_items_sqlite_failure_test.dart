import 'package:app_database/src/contexts/catalog/items/store/catalog_items_sqlite_failure.dart';
import 'package:app_database/src/contexts/catalog/items/store/catalog_items_store_exception.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

void main() {
  test('maps busy and locked extended codes with the original stack', () {
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
      final originalStack = StackTrace.fromString('original-sqlite-stack');

      try {
        throwCatalogItemsSqliteFailure(
          error: vendor,
          sqliteError: vendor,
          stackTrace: originalStack,
        );
      } catch (error, stackTrace) {
        expect(error, isA<CatalogItemsStoreException>());
        expect(identical(stackTrace, originalStack), isTrue);
        expect(error.toString(), isNot(contains('private vendor message')));
      }
    }
  });

  test('preserves unexpected SQLite failures and original stacks', () {
    for (final code in <int>[
      SqlError.SQLITE_CONSTRAINT,
      SqlError.SQLITE_CORRUPT,
      SqlError.SQLITE_READONLY,
      SqlError.SQLITE_FULL,
      SqlError.SQLITE_IOERR,
    ]) {
      final vendor = SqliteException(
        extendedResultCode: code,
        message: 'private vendor message',
      );
      final originalStack = StackTrace.fromString('original-sqlite-stack');

      try {
        throwCatalogItemsSqliteFailure(
          error: vendor,
          sqliteError: vendor,
          stackTrace: originalStack,
        );
      } catch (error, stackTrace) {
        expect(identical(error, vendor), isTrue);
        expect(identical(stackTrace, originalStack), isTrue);
      }
    }
  });

  test('preserves an original wrapper without a SQLite cause', () {
    final wrapper = StateError('remote wrapper sentinel');
    final originalStack = StackTrace.fromString('original-remote-stack');

    try {
      throwCatalogItemsSqliteFailure(
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
