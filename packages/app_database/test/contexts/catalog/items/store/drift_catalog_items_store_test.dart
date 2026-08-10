import 'dart:async';

import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/contexts/catalog/items/store/drift_catalog_items_store.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

void main() {
  late ApplicationDatabase database;
  late DriftCatalogItemsStore store;

  setUp(() {
    database = ApplicationDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    store = DriftCatalogItemsStore(dao: database.catalogItemsDao);
  });

  tearDown(() => database.close());

  test('an active watch receives every mutation', () async {
    final snapshots = StreamIterator(store.watchItems());
    addTearDown(snapshots.cancel);

    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current, isEmpty);

    final firstId = await store.insertItem('First item');
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.title, 'First item');

    expect(
      await store.setItemCompleted(id: firstId, isCompleted: true),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.completionValue, 1);

    expect(await store.deleteItem(firstId), 1);
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current, isEmpty);
  });

  test('returns records in stable insertion order', () async {
    final firstId = await store.insertItem('First item');
    final secondId = await store.insertItem('Second item');

    final stored = await store.watchItems().first;
    expect(stored.map((item) => item.id), <int>[firstId, secondId]);
  });

  test('database constraints reject invalid persistence values', () async {
    await expectLater(
      store.insertItem(''),
      throwsA(
        isA<SqliteException>().having(
          (error) => error.resultCode,
          'resultCode',
          SqlError.SQLITE_CONSTRAINT,
        ),
      ),
    );

    for (final parameters in <List<Object>>[
      <Object>[-1, 'Item', 0],
      <Object>[1, 'Item', 2],
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO catalog_items (id, title, is_completed) '
          'VALUES (?, ?, ?)',
          parameters,
        ),
        throwsA(
          isA<SqliteException>().having(
            (error) => error.resultCode,
            'resultCode',
            SqlError.SQLITE_CONSTRAINT,
          ),
        ),
      );
    }
  });
}
