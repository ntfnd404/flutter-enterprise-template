import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/ordering/orders/dao/ordering_order_record.dart';
import 'package:drift/drift.dart';

part 'ordering_orders_dao.g.dart';

const int _draftStatusValue = 0;
const int _placedStatusValue = 1;
const int _cancelledStatusValue = 2;

/// Private Drift DAO for the Ordering aggregate persistence cluster.
@DriftAccessor(
  include: <String>{'../tables/ordering_orders_tables.drift'},
)
final class OrderingOrdersDao extends DatabaseAccessor<ApplicationDatabase>
    with _$OrderingOrdersDaoMixin {
  /// Attaches Ordering queries and transactions to the physical database.
  OrderingOrdersDao(super.attachedDatabase);

  /// Watches all persisted aggregates in stable identifier order.
  ///
  /// Supported line mutations always update the parent revision in the same
  /// transaction. Observing the parent table is therefore the authoritative
  /// invalidation source for the joined aggregate snapshot.
  Stream<List<OrderingOrderRecord>> watchOrders() =>
      (select(orderingOrders)..orderBy(<OrderingTerm Function(OrderingOrders)>[
            (table) => OrderingTerm.asc(table.id),
          ]))
          .watch()
          .asyncMap(
            (_) async => _groupRows(await _orderedAggregateQuery().get()),
          );

  /// Watches one persisted aggregate, yielding `null` while it is absent.
  Stream<OrderingOrderRecord?> watchOrder(int id) {
    final parent = select(orderingOrders)
      ..where((table) => table.id.equals(id));
    return parent.watch().asyncMap(
      (rows) =>
          rows.isEmpty ? Future<OrderingOrderRecord?>.value() : getOrder(id),
    );
  }

  /// Loads one aggregate, or `null` when [id] is absent.
  Future<OrderingOrderRecord?> getOrder(int id) async {
    final query = _orderedAggregateQuery()..where(orderingOrders.id.equals(id));
    final records = _groupRows(await query.get());
    return records.isEmpty ? null : records.single;
  }

  /// Inserts an empty persistent draft and returns its generated identifier.
  Future<int> insertDraft({required int createdAtUtcMilliseconds}) =>
      into(orderingOrders).insert(
        OrderingOrdersCompanion.insert(
          createdAtUtcMilliseconds: createdAtUtcMilliseconds,
        ),
      );

  /// Atomically replaces draft lines under a status-and-revision condition.
  Future<int> replaceDraftLines({
    required int id,
    required int expectedRevision,
    required int? totalMinorUnits,
    required String? currencyCode,
    required List<OrderingOrderLinesCompanion> lines,
  }) => transaction(() async {
    final affected =
        await (update(orderingOrders)..where(
              (table) =>
                  table.id.equals(id) &
                  table.statusValue.equals(_draftStatusValue) &
                  table.revision.equals(expectedRevision),
            ))
            .write(
              OrderingOrdersCompanion.custom(
                totalMinorUnits: Variable<int>(totalMinorUnits),
                currencyCode: Variable<String>(currencyCode),
                revision: orderingOrders.revision + const Constant<int>(1),
              ),
            );
    if (affected == 0) {
      return 0;
    }

    await (delete(
      orderingOrderLines,
    )..where((table) => table.orderId.equals(id))).go();
    await batch((batch) {
      batch.insertAll(orderingOrderLines, lines);
    });
    return affected;
  });

  /// Atomically refreshes lines and commits draft placement.
  Future<int> placeOrder({
    required int id,
    required int expectedRevision,
    required int totalMinorUnits,
    required String currencyCode,
    required int placedAtUtcMilliseconds,
    required List<OrderingOrderLinesCompanion> lines,
  }) => transaction(() async {
    final affected =
        await (update(orderingOrders)..where(
              (table) =>
                  table.id.equals(id) &
                  table.statusValue.equals(_draftStatusValue) &
                  table.revision.equals(expectedRevision),
            ))
            .write(
              OrderingOrdersCompanion.custom(
                statusValue: const Variable<int>(_placedStatusValue),
                totalMinorUnits: Variable<int>(totalMinorUnits),
                currencyCode: Variable<String>(currencyCode),
                revision: orderingOrders.revision + const Constant<int>(1),
                placedAtUtcMilliseconds: Variable<int>(placedAtUtcMilliseconds),
              ),
            );
    if (affected == 0) {
      return 0;
    }

    await (delete(
      orderingOrderLines,
    )..where((table) => table.orderId.equals(id))).go();
    await batch((batch) {
      batch.insertAll(orderingOrderLines, lines);
    });
    return affected;
  });

  /// Cancels a draft or placed aggregate under a revision condition.
  Future<int> cancelOrder({
    required int id,
    required int expectedRevision,
    required int cancelledAtUtcMilliseconds,
  }) =>
      (update(orderingOrders)..where(
            (table) =>
                table.id.equals(id) &
                table.statusValue.isIn(const <int>[
                  _draftStatusValue,
                  _placedStatusValue,
                ]) &
                table.revision.equals(expectedRevision),
          ))
          .write(
            OrderingOrdersCompanion.custom(
              statusValue: const Variable<int>(_cancelledStatusValue),
              revision: orderingOrders.revision + const Constant<int>(1),
              cancelledAtUtcMilliseconds: Variable<int>(
                cancelledAtUtcMilliseconds,
              ),
            ),
          );

  JoinedSelectStatement<OrderingOrders, OrderingOrder>
  _orderedAggregateQuery() {
    final query =
        select(orderingOrders).join(
          // ignore: strict_raw_type, Drift's legacy join API returns raw Join.
          <Join>[
            leftOuterJoin(
              orderingOrderLines,
              orderingOrderLines.orderId.equalsExp(orderingOrders.id),
            ),
          ],
        )..orderBy(<OrderingTerm>[
          OrderingTerm.asc(orderingOrders.id),
          OrderingTerm.asc(orderingOrderLines.catalogProductId),
        ]);

    // Drift's legacy join API returns a raw JoinedSelectStatement even though
    // the main table remains statically known. Contain that vendor limitation
    // at the DAO boundary instead of leaking a dynamic result downstream.
    return query as JoinedSelectStatement<OrderingOrders, OrderingOrder>;
  }

  List<OrderingOrderRecord> _groupRows(List<TypedResult> rows) {
    final records = <int, _MutableOrderingOrderRecord>{};
    for (final row in rows) {
      final order = row.readTable(orderingOrders);
      final record = records.putIfAbsent(
        order.id,
        () => _MutableOrderingOrderRecord(order),
      );
      final line = row.readTableOrNull(orderingOrderLines);
      if (line != null) {
        record.lines.add(line);
      }
    }

    return List<OrderingOrderRecord>.unmodifiable(
      records.values.map(
        (record) => OrderingOrderRecord(
          order: record.order,
          lines: record.lines,
        ),
      ),
    );
  }
}

final class _MutableOrderingOrderRecord {
  _MutableOrderingOrderRecord(this.order);

  final OrderingOrder order;
  final List<OrderingOrderLine> lines = <OrderingOrderLine>[];
}
