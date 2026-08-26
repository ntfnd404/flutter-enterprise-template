import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/ordering/orders/dao/ordering_order_record.dart';
import 'package:app_database/src/persistence/ordering/orders/dao/ordering_orders_dao.dart';
import 'package:app_database/src/persistence/ordering/orders/store/ordering_orders_store.dart';
import 'package:app_database/src/persistence/ordering/orders/store/ordering_sqlite_failure.dart';
import 'package:app_database/src/persistence/ordering/orders/store/stored_order.dart';
import 'package:app_database/src/persistence/ordering/orders/store/stored_order_line.dart';
import 'package:drift/isolate.dart';
import 'package:sqlite3/common.dart';

/// Drift-backed implementation of the narrow Ordering persistence seam.
final class DriftOrderingOrdersStore implements OrderingOrdersStore {
  /// Creates a store over the private Ordering DAO.
  const DriftOrderingOrdersStore({required this._dao});

  final OrderingOrdersDao _dao;

  @override
  Stream<List<StoredOrder>> watchOrders() async* {
    try {
      await for (final records in _dao.watchOrders()) {
        yield List<StoredOrder>.unmodifiable(records.map(_mapOrder));
      }
    } on SqliteException catch (error, stackTrace) {
      throwOrderingSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwOrderingSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<StoredOrder?> watchOrder(int id) async* {
    try {
      await for (final record in _dao.watchOrder(id)) {
        yield record == null ? null : _mapOrder(record);
      }
    } on SqliteException catch (error, stackTrace) {
      throwOrderingSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwOrderingSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<StoredOrder?> getOrder(int id) => _guardPersistence(() async {
    final record = await _dao.getOrder(id);
    return record == null ? null : _mapOrder(record);
  });

  @override
  Future<int> insertDraft({required int createdAtUtcMilliseconds}) =>
      _guardPersistence(
        () => _dao.insertDraft(
          createdAtUtcMilliseconds: createdAtUtcMilliseconds,
        ),
      );

  @override
  Future<int> replaceDraftLines({
    required int id,
    required int expectedRevision,
    required int? totalMinorUnits,
    required String? currencyCode,
    required List<StoredOrderLine> lines,
  }) => _guardPersistence(
    () => _dao.replaceDraftLines(
      id: id,
      expectedRevision: expectedRevision,
      totalMinorUnits: totalMinorUnits,
      currencyCode: currencyCode,
      lines: lines
          .map((line) => _lineCompanion(line, orderId: id))
          .toList(growable: false),
    ),
  );

  @override
  Future<int> placeOrder({
    required int id,
    required int expectedRevision,
    required int totalMinorUnits,
    required String currencyCode,
    required int placedAtUtcMilliseconds,
    required List<StoredOrderLine> lines,
  }) => _guardPersistence(
    () => _dao.placeOrder(
      id: id,
      expectedRevision: expectedRevision,
      totalMinorUnits: totalMinorUnits,
      currencyCode: currencyCode,
      placedAtUtcMilliseconds: placedAtUtcMilliseconds,
      lines: lines
          .map((line) => _lineCompanion(line, orderId: id))
          .toList(growable: false),
    ),
  );

  @override
  Future<int> cancelOrder({
    required int id,
    required int expectedRevision,
    required int cancelledAtUtcMilliseconds,
  }) => _guardPersistence(
    () => _dao.cancelOrder(
      id: id,
      expectedRevision: expectedRevision,
      cancelledAtUtcMilliseconds: cancelledAtUtcMilliseconds,
    ),
  );

  Future<T> _guardPersistence<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on SqliteException catch (error, stackTrace) {
      throwOrderingSqliteFailure(
        error: error,
        sqliteError: error,
        stackTrace: stackTrace,
      );
    } on DriftRemoteException catch (error, stackTrace) {
      final remoteCause = error.remoteCause;
      throwOrderingSqliteFailure(
        error: error,
        sqliteError: remoteCause is SqliteException ? remoteCause : null,
        stackTrace: stackTrace,
      );
    }
  }

  StoredOrder _mapOrder(OrderingOrderRecord record) {
    final order = record.order;
    return StoredOrder(
      id: order.id,
      statusValue: order.statusValue,
      totalMinorUnits: order.totalMinorUnits,
      currencyCode: order.currencyCode,
      revision: order.revision,
      createdAtUtcMilliseconds: order.createdAtUtcMilliseconds,
      placedAtUtcMilliseconds: order.placedAtUtcMilliseconds,
      cancelledAtUtcMilliseconds: order.cancelledAtUtcMilliseconds,
      lines: record.lines.map(_mapLine).toList(growable: false),
    );
  }

  StoredOrderLine _mapLine(OrderingOrderLine line) => StoredOrderLine(
    catalogProductId: line.catalogProductId,
    productTitleSnapshot: line.productTitleSnapshot,
    unitPriceMinorUnits: line.unitPriceMinorUnits,
    currencyCode: line.currencyCode,
    quantity: line.quantity,
    catalogRevision: line.catalogRevision,
  );

  OrderingOrderLinesCompanion _lineCompanion(
    StoredOrderLine line, {
    required int orderId,
  }) => OrderingOrderLinesCompanion.insert(
    orderId: orderId,
    catalogProductId: line.catalogProductId,
    productTitleSnapshot: line.productTitleSnapshot,
    unitPriceMinorUnits: line.unitPriceMinorUnits,
    currencyCode: line.currencyCode,
    quantity: line.quantity,
    catalogRevision: line.catalogRevision,
  );
}
