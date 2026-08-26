import 'dart:async';

import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/catalog/categories/store/drift_catalog_categories_store.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

void main() {
  late ApplicationDatabase database;
  late DriftCatalogCategoriesStore store;

  setUp(() {
    database = ApplicationDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    store = DriftCatalogCategoriesStore(dao: database.catalogCategoriesDao);
  });

  tearDown(() => database.close());

  test('an active watch receives category mutations', () async {
    final snapshots = StreamIterator(store.watchCategories());
    addTearDown(snapshots.cancel);

    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current, isEmpty);

    final id = await store.insertCategory('Hardware');
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.name, 'Hardware');
    expect(snapshots.current.single.isActive, isTrue);

    expect(await store.setCategoryActive(id: id, isActive: false), 1);
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.isActive, isFalse);

    expect((await store.getCategory(id))?.name, 'Hardware');
    expect(await store.getCategory(404), isNull);
  });

  test('database constraints reject invalid category values', () async {
    await expectLater(
      store.insertCategory(''),
      throwsA(
        isA<SqliteException>().having(
          (error) => error.resultCode,
          'resultCode',
          SqlError.SQLITE_CONSTRAINT,
        ),
      ),
    );

    await expectLater(
      database.customStatement(
        "INSERT INTO catalog_categories(name, is_active) VALUES ('Invalid', 2)",
      ),
      throwsA(
        isA<SqliteException>().having(
          (error) => error.resultCode,
          'resultCode',
          SqlError.SQLITE_CONSTRAINT,
        ),
      ),
    );
  });
}
