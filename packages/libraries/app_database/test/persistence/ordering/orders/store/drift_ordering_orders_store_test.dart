import 'dart:async';

import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/ordering/orders/store/drift_ordering_orders_store.dart';
import 'package:app_database/src/persistence/ordering/orders/store/stored_order_line.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late ApplicationDatabase database;
  late DriftOrderingOrdersStore store;

  setUp(() {
    database = ApplicationDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    store = DriftOrderingOrdersStore(dao: database.orderingOrdersDao);
  });

  test('persists and observes the complete Order lifecycle', () async {
    final snapshots = StreamIterator(store.watchOrders());
    addTearDown(snapshots.cancel);
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current, isEmpty);

    final id = await _insertDraft(store);
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.id, id);
    expect(snapshots.current.single.revision, 0);
    expect(snapshots.current.single.lines, isEmpty);

    expect(
      await store.replaceDraftLines(
        id: id,
        expectedRevision: 0,
        totalMinorUnits: 500,
        currencyCode: 'USD',
        lines: <StoredOrderLine>[
          _line(productId: 2, price: 200),
          _line(productId: 1, price: 300),
        ],
      ),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.revision, 1);
    expect(
      snapshots.current.single.lines.map((line) => line.catalogProductId),
      orderedEquals(<int>[1, 2]),
    );

    final draft = await store.getOrder(id);
    expect(draft, isNotNull);
    expect(draft!.statusValue, 0);
    expect(draft.revision, 1);
    expect(draft.totalMinorUnits, 500);
    expect(
      draft.lines.map((line) => line.catalogProductId),
      orderedEquals(<int>[1, 2]),
    );

    expect(
      await store.placeOrder(
        id: id,
        expectedRevision: 1,
        totalMinorUnits: 700,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[
          _line(productId: 1, price: 400),
          _line(productId: 2, price: 300),
        ],
      ),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.statusValue, 1);
    expect(snapshots.current.single.revision, 2);

    final placed = await store.getOrder(id);
    expect(placed!.statusValue, 1);
    expect(placed.revision, 2);
    expect(placed.placedAtUtcMilliseconds, 1700000001000);

    expect(
      await store.cancelOrder(
        id: id,
        expectedRevision: 2,
        cancelledAtUtcMilliseconds: 1700000002000,
      ),
      1,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current.single.statusValue, 2);
    expect(snapshots.current.single.revision, 3);
    final cancelled = await store.getOrder(id);
    expect(cancelled!.statusValue, 2);
    expect(cancelled.revision, 3);
    expect(cancelled.cancelledAtUtcMilliseconds, 1700000002000);
  });

  test('watchOrder observes line and parent snapshots', () async {
    final id = await _insertDraft(store);
    final snapshots = StreamIterator(store.watchOrder(id));
    addTearDown(snapshots.cancel);

    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current!.revision, 0);
    expect(snapshots.current!.lines, isEmpty);

    await store.replaceDraftLines(
      id: id,
      expectedRevision: 0,
      totalMinorUnits: 100,
      currencyCode: 'USD',
      lines: <StoredOrderLine>[_line(productId: 2, price: 100)],
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current!.revision, 1);
    expect(snapshots.current!.lines.single.catalogProductId, 2);

    await store.cancelOrder(
      id: id,
      expectedRevision: 1,
      cancelledAtUtcMilliseconds: 1700000001000,
    );
    expect(await snapshots.moveNext(), isTrue);
    expect(snapshots.current!.statusValue, 2);
    expect(snapshots.current!.revision, 2);
  });

  test('orders and lines use stable identifier ordering', () async {
    final firstId = await _insertDraft(store);
    final secondId = await _insertDraft(store);
    await store.replaceDraftLines(
      id: secondId,
      expectedRevision: 0,
      totalMinorUnits: 200,
      currencyCode: 'USD',
      lines: <StoredOrderLine>[
        _line(productId: 9, price: 100),
        _line(productId: 3, price: 100),
      ],
    );

    final orders = await store.watchOrders().first;

    expect(
      orders.map((order) => order.id),
      orderedEquals(<int>[firstId, secondId]),
    );
    expect(
      orders.last.lines.map((line) => line.catalogProductId),
      orderedEquals(<int>[3, 9]),
    );
  });

  test(
    'conditional line replacement leaves rejected state unchanged',
    () async {
      expect(
        await store.replaceDraftLines(
          id: 404,
          expectedRevision: 0,
          totalMinorUnits: null,
          currencyCode: null,
          lines: const <StoredOrderLine>[],
        ),
        0,
      );

      final id = await _insertDraft(store);
      expect(
        await store.replaceDraftLines(
          id: id,
          expectedRevision: 7,
          totalMinorUnits: null,
          currencyCode: null,
          lines: const <StoredOrderLine>[],
        ),
        0,
      );
      expect(await _replaceWithSingleLine(store, id: id), 1);
      expect(await _replaceWithSingleLine(store, id: id), 0);

      await store.placeOrder(
        id: id,
        expectedRevision: 1,
        totalMinorUnits: 100,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[_line(productId: 1, price: 100)],
      );
      expect(
        await store.replaceDraftLines(
          id: id,
          expectedRevision: 2,
          totalMinorUnits: null,
          currencyCode: null,
          lines: const <StoredOrderLine>[],
        ),
        0,
      );

      final unchanged = await store.getOrder(id);
      expect(unchanged!.statusValue, 1);
      expect(unchanged.revision, 2);
      expect(unchanged.lines.single.catalogProductId, 1);
    },
  );

  test('conditional placement leaves rejected state unchanged', () async {
    final line = _line(productId: 1, price: 100);
    expect(
      await store.placeOrder(
        id: 404,
        expectedRevision: 0,
        totalMinorUnits: 100,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[line],
      ),
      0,
    );

    final id = await _insertDraft(store);
    expect(
      await store.placeOrder(
        id: id,
        expectedRevision: 7,
        totalMinorUnits: 100,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[line],
      ),
      0,
    );
    expect(
      await store.placeOrder(
        id: id,
        expectedRevision: 0,
        totalMinorUnits: 100,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[line],
      ),
      1,
    );
    expect(
      await store.placeOrder(
        id: id,
        expectedRevision: 0,
        totalMinorUnits: 100,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[line],
      ),
      0,
    );
    expect(
      await store.placeOrder(
        id: id,
        expectedRevision: 1,
        totalMinorUnits: 100,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[line],
      ),
      0,
    );

    final placed = await store.getOrder(id);
    expect(placed!.statusValue, 1);
    expect(placed.revision, 1);
  });

  test('cancels draft and placed Orders only once', () async {
    expect(
      await store.cancelOrder(
        id: 404,
        expectedRevision: 0,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      0,
    );

    final draftId = await _insertDraft(store);
    expect(
      await store.cancelOrder(
        id: draftId,
        expectedRevision: 7,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      0,
    );
    expect(
      await store.cancelOrder(
        id: draftId,
        expectedRevision: 0,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      1,
    );
    expect(
      await store.cancelOrder(
        id: draftId,
        expectedRevision: 0,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      0,
    );
    expect(
      await store.cancelOrder(
        id: draftId,
        expectedRevision: 1,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      0,
    );

    final placedId = await _insertDraft(store);
    await store.placeOrder(
      id: placedId,
      expectedRevision: 0,
      totalMinorUnits: 100,
      currencyCode: 'USD',
      placedAtUtcMilliseconds: 1700000001000,
      lines: <StoredOrderLine>[_line(productId: 1, price: 100)],
    );
    expect(
      await store.cancelOrder(
        id: placedId,
        expectedRevision: 1,
        cancelledAtUtcMilliseconds: 1700000002000,
      ),
      1,
    );
    final cancelled = await store.getOrder(placedId);
    expect(cancelled!.statusValue, 2);
    expect(cancelled.revision, 2);
    expect(cancelled.placedAtUtcMilliseconds, 1700000001000);
  });

  test('rolls back parent revision and lines when replacement fails', () async {
    final id = await _insertDraft(store);
    await _replaceWithSingleLine(store, id: id);

    await expectLater(
      store.replaceDraftLines(
        id: id,
        expectedRevision: 1,
        totalMinorUnits: 200,
        currencyCode: 'USD',
        lines: <StoredOrderLine>[_line(productId: 2, price: 0)],
      ),
      throwsA(isA<SqliteException>()),
    );

    final unchanged = await store.getOrder(id);
    expect(unchanged!.statusValue, 0);
    expect(unchanged.revision, 1);
    expect(unchanged.totalMinorUnits, 100);
    expect(unchanged.lines.single.catalogProductId, 1);
  });

  test('rolls back parent revision and lines when placement fails', () async {
    final id = await _insertDraft(store);
    await _replaceWithSingleLine(store, id: id);

    await expectLater(
      store.placeOrder(
        id: id,
        expectedRevision: 1,
        totalMinorUnits: 200,
        currencyCode: 'USD',
        placedAtUtcMilliseconds: 1700000001000,
        lines: <StoredOrderLine>[_line(productId: 2, price: 0)],
      ),
      throwsA(isA<SqliteException>()),
    );

    final unchanged = await store.getOrder(id);
    expect(unchanged!.statusValue, 0);
    expect(unchanged.revision, 1);
    expect(unchanged.totalMinorUnits, 100);
    expect(unchanged.placedAtUtcMilliseconds, isNull);
    expect(unchanged.lines.single.catalogProductId, 1);
  });

  test('rolls back a duplicate-product line replacement', () async {
    final id = await _insertDraft(store);

    await expectLater(
      store.replaceDraftLines(
        id: id,
        expectedRevision: 0,
        totalMinorUnits: 200,
        currencyCode: 'USD',
        lines: <StoredOrderLine>[
          _line(productId: 1, price: 100),
          _line(productId: 1, price: 100),
        ],
      ),
      throwsA(isA<SqliteException>()),
    );

    final unchanged = await store.getOrder(id);
    expect(unchanged!.revision, 0);
    expect(unchanged.totalMinorUnits, isNull);
    expect(unchanged.lines, isEmpty);
  });

  test('revision overflow preserves the original aggregate', () async {
    const maxRevision = 9007199254740991;
    final id = await _insertDraft(store);
    await database.customStatement(
      'UPDATE ordering_orders SET revision = ? WHERE id = ?',
      <Object?>[maxRevision, id],
    );

    await expectLater(
      store.cancelOrder(
        id: id,
        expectedRevision: maxRevision,
        cancelledAtUtcMilliseconds: 1700000001000,
      ),
      throwsA(isA<SqliteException>()),
    );

    final unchanged = await store.getOrder(id);
    expect(unchanged!.statusValue, 0);
    expect(unchanged.revision, maxRevision);
    expect(unchanged.cancelledAtUtcMilliseconds, isNull);
  });

  test('replaces existing lines with an empty nullable-money draft', () async {
    final id = await _insertDraft(store);
    await _replaceWithSingleLine(store, id: id);

    expect(
      await store.replaceDraftLines(
        id: id,
        expectedRevision: 1,
        totalMinorUnits: null,
        currencyCode: null,
        lines: const <StoredOrderLine>[],
      ),
      1,
    );
    final emptyDraft = await store.getOrder(id);
    expect(emptyDraft!.revision, 2);
    expect(emptyDraft.totalMinorUnits, isNull);
    expect(emptyDraft.currencyCode, isNull);
    expect(emptyDraft.lines, isEmpty);
  });

  test('cascades owned lines without a Catalog foreign key', () async {
    final id = await _insertDraft(store);
    await store.replaceDraftLines(
      id: id,
      expectedRevision: 0,
      totalMinorUnits: 100,
      currencyCode: 'USD',
      lines: <StoredOrderLine>[_line(productId: 999999, price: 100)],
    );

    await database.customStatement(
      'DELETE FROM ordering_orders WHERE id = ?',
      <Object?>[id],
    );
    final count = await database
        .customSelect(
          'SELECT COUNT(*) AS line_count FROM ordering_order_lines '
          'WHERE order_id = ?',
          variables: <Variable<Object>>[Variable<int>(id)],
        )
        .getSingle();

    expect(count.read<int>('line_count'), 0);
  });

  test('AUTOINCREMENT does not reuse a deleted Order identity', () async {
    final firstId = await _insertDraft(store);
    await database.customStatement(
      'DELETE FROM ordering_orders WHERE id = ?',
      <Object?>[firstId],
    );

    final secondId = await _insertDraft(store);

    expect(secondId, greaterThan(firstId));
  });

  test('rejects invalid persisted money representations', () async {
    for (final values in <(int?, String?)>[
      (0, 'USD'),
      (9007199254740992, 'USD'),
      (100, null),
      (null, 'USD'),
      (100, 'XXX'),
      (100, 'usd'),
      (100, 'US'),
      (100, 'USDD'),
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO ordering_orders '
          '(total_minor_units, currency_code, '
          'created_at_utc_milliseconds) VALUES (?, ?, ?)',
          <Object?>[values.$1, values.$2, 1700000000000],
        ),
        throwsA(isA<SqliteException>()),
      );
    }
  });

  test('rejects invalid persisted line scalar representations', () async {
    final id = await _insertDraft(store);
    for (final values in <(int, String, int, String, int, int)>[
      (0, 'Product', 100, 'USD', 1, 0),
      (1, '', 100, 'USD', 1, 0),
      (1, 'Product', 0, 'USD', 1, 0),
      (1, 'Product', 9007199254740992, 'USD', 1, 0),
      (1, 'Product', 100, 'XXX', 1, 0),
      (1, 'Product', 100, 'usd', 1, 0),
      (1, 'Product', 100, 'USD', 0, 0),
      (1, 'Product', 100, 'USD', 9007199254740992, 0),
      (1, 'Product', 100, 'USD', 1, -1),
      (1, 'Product', 100, 'USD', 1, 9007199254740992),
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO ordering_order_lines '
          '(order_id, catalog_product_id, product_title_snapshot, '
          'unit_price_minor_units, currency_code, quantity, '
          'catalog_revision) VALUES (?, ?, ?, ?, ?, ?, ?)',
          <Object?>[
            id,
            values.$1,
            values.$2,
            values.$3,
            values.$4,
            values.$5,
            values.$6,
          ],
        ),
        throwsA(isA<SqliteException>()),
      );
    }

    expect((await store.getOrder(id))!.lines, isEmpty);
  });

  test('rejects timestamps outside the supported UTC range', () async {
    for (final timestamp in <int>[-1, 8640000000000001]) {
      await expectLater(
        store.insertDraft(createdAtUtcMilliseconds: timestamp),
        throwsA(isA<SqliteException>()),
      );
    }
  });

  test('rejects lifecycle columns inconsistent with stored status', () async {
    for (final values in <(int, int?, String?, int?, int?)>[
      (3, null, null, null, null),
      (0, null, null, 1700000000001, null),
      (0, null, null, null, 1700000000001),
      (1, 100, 'USD', null, null),
      (1, 100, 'USD', 1700000000001, 1700000000002),
      (2, null, null, null, null),
      (2, null, null, 1700000000001, 1700000000002),
    ]) {
      await expectLater(
        database.customStatement(
          'INSERT INTO ordering_orders '
          '(status_value, total_minor_units, currency_code, '
          'created_at_utc_milliseconds, placed_at_utc_milliseconds, '
          'cancelled_at_utc_milliseconds) VALUES (?, ?, ?, ?, ?, ?)',
          <Object?>[
            values.$1,
            values.$2,
            values.$3,
            1700000000000,
            values.$4,
            values.$5,
          ],
        ),
        throwsA(isA<SqliteException>()),
      );
    }
  });

  test('rejects revisions outside the optimistic-token range', () async {
    final id = await _insertDraft(store);
    for (final revision in <int>[-1, 9007199254740992]) {
      await expectLater(
        database.customStatement(
          'UPDATE ordering_orders SET revision = ? WHERE id = ?',
          <Object?>[revision, id],
        ),
        throwsA(isA<SqliteException>()),
      );
    }

    expect((await store.getOrder(id))!.revision, 0);
  });
}

Future<int> _insertDraft(DriftOrderingOrdersStore store) => store.insertDraft(
  createdAtUtcMilliseconds: 1700000000000,
);

Future<int> _replaceWithSingleLine(
  DriftOrderingOrdersStore store, {
  required int id,
}) => store.replaceDraftLines(
  id: id,
  expectedRevision: 0,
  totalMinorUnits: 100,
  currencyCode: 'USD',
  lines: <StoredOrderLine>[_line(productId: 1, price: 100)],
);

StoredOrderLine _line({required int productId, required int price}) =>
    StoredOrderLine(
      catalogProductId: productId,
      productTitleSnapshot: 'Product $productId',
      unitPriceMinorUnits: price,
      currencyCode: 'USD',
      quantity: 1,
      catalogRevision: 0,
    );
