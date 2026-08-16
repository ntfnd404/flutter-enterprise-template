import 'dart:async';

import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/catalog/items/store/drift_catalog_items_store.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart';
import 'package:test/test.dart';

const _maxSafeInteger = 9007199254740991;

void main() {
  late ApplicationDatabase database;
  late DriftCatalogItemsStore store;
  late _SelectRecorder selectRecorder;

  setUp(() {
    selectRecorder = _SelectRecorder();
    database = ApplicationDatabase(
      DatabaseConnection(
        NativeDatabase.memory().interceptWith(selectRecorder),
        closeStreamsSynchronously: true,
      ),
    );
    store = DriftCatalogItemsStore(dao: database.catalogItemsDao);
  });

  tearDown(() => database.close());

  test('an active watch receives every product mutation', () async {
    final snapshots = StreamIterator(store.watchItems());
    addTearDown(snapshots.cancel);

    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current, isEmpty);

    final categoryId = await database.catalogCategoriesDao.insertCategory(
      'Hardware',
    );
    final firstId = await _insertProduct(
      store,
      title: 'First item',
      categoryId: categoryId,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.title, 'First item');

    expect(
      await store.updateDraft(
        id: firstId,
        expectedRevision: 0,
        title: 'Revised item',
        description: 'Revised description',
        priceMinorUnits: 200,
        currencyCode: 'EUR',
        categoryId: categoryId,
      ),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.title, 'Revised item');
    expect(snapshots.current.single.priceMinorUnits, 200);
    expect(snapshots.current.single.revision, 1);

    expect(
      await store.publishDraft(
        id: firstId,
        expectedRevision: 0,
        requiredActiveCategoryId: categoryId,
      ),
      0,
    );
    expect(
      await store.publishDraft(
        id: firstId,
        expectedRevision: 1,
        requiredActiveCategoryId: categoryId,
      ),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.statusValue, 1);
    expect(snapshots.current.single.revision, 2);

    expect(
      await store.updateDraft(
        id: firstId,
        expectedRevision: 2,
        title: 'Forbidden revision',
        description: 'Revised description',
        priceMinorUnits: 200,
        currencyCode: 'EUR',
        categoryId: null,
      ),
      0,
    );

    expect(
      await store.deleteDraft(id: firstId, expectedRevision: 2),
      0,
    );
  });

  test('deletes only a draft at its expected revision', () async {
    final snapshots = StreamIterator(store.watchItems());
    addTearDown(snapshots.cancel);
    expect(await snapshots.moveNext(), isTrue);

    final draftId = await _insertProduct(store, title: 'Draft');
    expect(await snapshots.moveNext(), isTrue);

    expect(
      await store.deleteDraft(id: draftId, expectedRevision: 1),
      0,
    );
    expect(
      await store.deleteDraft(id: 404, expectedRevision: 0),
      0,
    );
    expect(
      await store.deleteDraft(id: draftId, expectedRevision: 0),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current, isEmpty);
  });

  test('does not delete published or archived items', () async {
    final categoryId = await database.catalogCategoriesDao.insertCategory(
      'Hardware',
    );
    final publishedId = await _insertProduct(
      store,
      title: 'Published',
      categoryId: categoryId,
    );
    expect(
      await store.publishDraft(
        id: publishedId,
        expectedRevision: 0,
        requiredActiveCategoryId: categoryId,
      ),
      1,
    );
    expect(
      await store.deleteDraft(id: publishedId, expectedRevision: 1),
      0,
    );

    final archivedId = await _insertProduct(
      store,
      title: 'Archived',
      categoryId: categoryId,
    );
    expect(
      await store.publishDraft(
        id: archivedId,
        expectedRevision: 0,
        requiredActiveCategoryId: categoryId,
      ),
      1,
    );
    expect(
      await store.archivePublished(id: archivedId, expectedRevision: 1),
      1,
    );
    expect(
      await store.deleteDraft(id: archivedId, expectedRevision: 2),
      0,
    );

    expect(await store.getItem(publishedId), isNotNull);
    expect(await store.getItem(archivedId), isNotNull);
  });

  test('loads records and preserves stable insertion order', () async {
    final firstId = await _insertProduct(store, title: 'First item');
    final secondId = await _insertProduct(store, title: 'Second item');

    final stored = await store.watchItems().first;
    expect(stored.map((item) => item.id), <int>[firstId, secondId]);
    expect((await store.getItem(secondId))?.title, 'Second item');
    expect(await store.getItem(404), isNull);
  });

  test('batch-loads existing identifiers once in stable order', () async {
    final firstId = await _insertProduct(store, title: 'First item');
    final secondId = await _insertProduct(store, title: 'Second item');
    await _insertProduct(store, title: 'Third item');
    selectRecorder.reset();

    final stored = await store.findItemsByIds(<int>{secondId, 404, firstId});

    expect(selectRecorder.count, 1);
    expect(stored.map((item) => item.id), <int>[firstId, secondId]);
    expect(() => stored.add(stored.first), throwsUnsupportedError);

    selectRecorder.reset();
    expect(await store.findItemsByIds(const <int>{}), isEmpty);
    expect(selectRecorder.count, 0);
  });

  test('publication condition requires a still-active category', () async {
    final categoryId = await database.catalogCategoriesDao.insertCategory(
      'Hardware',
    );
    final differentCategoryId = await database.catalogCategoriesDao
        .insertCategory('Software');
    final itemId = await _insertProduct(
      store,
      title: 'Product',
      categoryId: categoryId,
    );
    await database.catalogCategoriesDao.setCategoryActive(
      id: categoryId,
      isActive: false,
    );

    expect(
      await store.publishDraft(
        id: itemId,
        expectedRevision: 0,
        requiredActiveCategoryId: differentCategoryId,
      ),
      0,
    );
    expect(
      await store.publishDraft(
        id: itemId,
        expectedRevision: 0,
        requiredActiveCategoryId: categoryId,
      ),
      0,
    );

    await database.catalogCategoriesDao.setCategoryActive(
      id: categoryId,
      isActive: true,
    );
    expect(
      await store.publishDraft(
        id: itemId,
        expectedRevision: 0,
        requiredActiveCategoryId: categoryId,
      ),
      1,
    );
    expect(
      await store.publishDraft(
        id: itemId,
        expectedRevision: 1,
        requiredActiveCategoryId: categoryId,
      ),
      0,
    );
  });

  test(
    'archives only published items regardless of category activity',
    () async {
      final categoryId = await database.catalogCategoriesDao.insertCategory(
        'Hardware',
      );
      final itemId = await _insertProduct(
        store,
        title: 'Product',
        categoryId: categoryId,
      );

      expect(
        await store.archivePublished(id: itemId, expectedRevision: 0),
        0,
      );
      expect(
        await store.publishDraft(
          id: itemId,
          expectedRevision: 0,
          requiredActiveCategoryId: categoryId,
        ),
        1,
      );
      await database.catalogCategoriesDao.setCategoryActive(
        id: categoryId,
        isActive: false,
      );

      expect(
        await store.archivePublished(id: itemId, expectedRevision: 0),
        0,
      );
      expect(
        await store.archivePublished(id: itemId, expectedRevision: 1),
        1,
      );
      expect(
        await store.archivePublished(id: itemId, expectedRevision: 2),
        0,
      );
      final archived = await store.getItem(itemId);
      expect(archived!.statusValue, 2);
      expect(archived.revision, 2);
    },
  );

  test('published offer update rechecks category and revision', () async {
    final categoryId = await database.catalogCategoriesDao.insertCategory(
      'Hardware',
    );
    final replacementCategoryId = await database.catalogCategoriesDao
        .insertCategory('Software');
    final itemId = await _insertProduct(
      store,
      title: 'Product',
      categoryId: categoryId,
    );
    expect(
      await store.publishDraft(
        id: itemId,
        expectedRevision: 0,
        requiredActiveCategoryId: categoryId,
      ),
      1,
    );

    expect(
      await store.updatePublishedOffer(
        id: itemId,
        expectedRevision: 0,
        title: 'Stale',
        description: 'Stale',
        priceMinorUnits: 200,
        currencyCode: 'EUR',
        categoryId: categoryId,
      ),
      0,
    );
    expect(
      await store.updatePublishedOffer(
        id: itemId,
        expectedRevision: 1,
        title: 'Current',
        description: 'Current offer',
        priceMinorUnits: 200,
        currencyCode: 'EUR',
        categoryId: replacementCategoryId,
      ),
      1,
    );

    await database.catalogCategoriesDao.setCategoryActive(
      id: replacementCategoryId,
      isActive: false,
    );
    expect(
      await store.updatePublishedOffer(
        id: itemId,
        expectedRevision: 2,
        title: 'Forbidden',
        description: 'Inactive category',
        priceMinorUnits: 300,
        currencyCode: 'USD',
        categoryId: replacementCategoryId,
      ),
      0,
    );

    final current = await store.getItem(itemId);
    expect(current!.title, 'Current');
    expect(current.categoryId, replacementCategoryId);
    expect(current.revision, 2);
    expect(current.statusValue, 1);
  });

  test('database constraints reject invalid persistence values', () async {
    final categoryId = await database.catalogCategoriesDao.insertCategory(
      'Hardware',
    );
    final boundaryId = await _insertProduct(
      store,
      title: 'Maximum safe price',
      priceMinorUnits: _maxSafeInteger,
    );
    expect(
      (await store.getItem(boundaryId))?.priceMinorUnits,
      _maxSafeInteger,
    );

    await expectLater(
      _insertProduct(store, title: ''),
      throwsA(_constraintFailure),
    );

    for (final parameters in <List<Object?>>[
      <Object?>[-1, 'Item', '', 0, 'USD', 0, null],
      <Object?>[1, 'Item', '', -1, 'USD', 0, null],
      <Object?>[5, 'Item', '', _maxSafeInteger + 1, 'USD', 0, null],
      <Object?>[2, 'Item', '', 1, 'US', 0, null],
      <Object?>[6, 'Item', '', 1, 'usd', 0, null],
      <Object?>[3, 'Item', '', 1, 'USD', 3, null],
      <Object?>[4, 'Item', '', 1, 'USD', 0, 404],
      <Object?>[7, 'Item', '', 1, 'USD', 1, categoryId],
      <Object?>[8, 'Item', 'Offer', 0, 'USD', 1, categoryId],
      <Object?>[9, 'Item', 'Offer', 1, 'XXX', 1, categoryId],
      <Object?>[10, 'Item', 'Offer', 1, 'USD', 1, null],
      <Object?>[11, 'Item', 'Offer', 1, 'USD', 2, null],
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO catalog_items '
          '(id, title, description, price_minor_units, currency_code, '
          'status_value, category_id) VALUES (?, ?, ?, ?, ?, ?, ?)',
          parameters,
        ),
        throwsA(_constraintFailure),
      );
    }

    await expectLater(
      database.customStatement(
        'INSERT INTO catalog_items '
        '(title, revision) VALUES (?, ?)',
        <Object?>['Item', -1],
      ),
      throwsA(_constraintFailure),
    );
    await expectLater(
      database.customStatement(
        'INSERT INTO catalog_items '
        '(title, revision) VALUES (?, ?)',
        <Object?>['Item', _maxSafeInteger + 1],
      ),
      throwsA(_constraintFailure),
    );

    final referencedItemId = await _insertProduct(
      store,
      title: 'Referenced item',
      categoryId: categoryId,
    );
    await expectLater(
      database.customStatement(
        'DELETE FROM catalog_categories WHERE id = ?',
        <Object?>[categoryId],
      ),
      throwsA(_constraintFailure),
    );
    expect(await store.getItem(referencedItemId), isNotNull);
  });
}

final Matcher _constraintFailure = isA<SqliteException>().having(
  (error) => error.resultCode,
  'resultCode',
  SqlError.SQLITE_CONSTRAINT,
);

final class _SelectRecorder extends QueryInterceptor {
  int count = 0;

  void reset() {
    count = 0;
  }

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    count += 1;
    return executor.runSelect(statement, args);
  }
}

Future<int> _insertProduct(
  DriftCatalogItemsStore store, {
  required String title,
  int? categoryId,
  int priceMinorUnits = 100,
}) => store.insertItem(
  title: title,
  description: 'Product description',
  priceMinorUnits: priceMinorUnits,
  currencyCode: 'USD',
  categoryId: categoryId,
);
