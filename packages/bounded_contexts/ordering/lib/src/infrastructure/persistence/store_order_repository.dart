import 'dart:async';

import 'package:app_database/stores/ordering.dart';
import 'package:ordering/src/domain/order/order.dart';
import 'package:ordering/src/domain/order/order_line.dart';
import 'package:ordering/src/domain/order/value_objects/order_id.dart';
import 'package:ordering/src/domain/ordering_exception.dart';
import 'package:ordering/src/domain/repository/order_repository.dart';

/// Order repository backed by the borrowed application-database seam.
final class StoreOrderRepository implements OrderRepository {
  /// Creates the adapter without taking ownership of [store].
  const StoreOrderRepository(this._store);

  final OrderingOrdersStore _store;

  @override
  Stream<List<Order>> watchOrders() => _watch(
    _store.watchOrders,
    (records) => List<Order>.unmodifiable(records.map(_mapOrder)),
  );

  @override
  Stream<Order> watchOrder(OrderId id) => _watch(
    () => _store.watchOrder(id.value),
    (record) {
      if (record == null) {
        throw const OrderingOrderNotFoundException();
      }

      return _mapOrder(record);
    },
  );

  Stream<T> _watch<S, T>(
    Stream<S> Function() createSource,
    T Function(S value) map,
  ) {
    // A manual adapter is intentional here: source creation can fail
    // synchronously, while every later source or mapping error must terminate
    // this observation and cancel the borrowed subscription exactly once.
    StreamSubscription<S>? sourceSubscription;
    Future<void>? sourceCancellation;
    var terminated = false;
    late final StreamController<T> controller;

    void terminateWithError(Object error, StackTrace stackTrace) {
      if (terminated) {
        return;
      }
      terminated = true;
      controller.addError(
        error is OrderingStoreException
            ? const OrderingPersistenceException()
            : error,
        stackTrace,
      );
      final subscription = sourceSubscription;
      if (subscription != null) {
        sourceCancellation = subscription.cancel();
      }
      unawaited(controller.close());
    }

    void terminateNormally() {
      if (terminated) {
        return;
      }
      terminated = true;
      unawaited(controller.close());
    }

    controller = StreamController<T>(
      sync: true,
      onListen: () {
        try {
          final subscription = createSource().listen(
            (value) {
              if (terminated) {
                return;
              }
              try {
                controller.add(map(value));
              } on Object catch (error, stackTrace) {
                terminateWithError(error, stackTrace);
              }
            },
            onError: terminateWithError,
            onDone: terminateNormally,
          );
          sourceSubscription = subscription;
          if (terminated) {
            sourceCancellation = subscription.cancel();
          }
        } on Object catch (error, stackTrace) {
          terminateWithError(error, stackTrace);
        }
      },
      onPause: () => sourceSubscription?.pause(),
      onResume: () => sourceSubscription?.resume(),
      onCancel: () {
        terminated = true;

        return sourceCancellation ?? sourceSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<Order> getOrder(OrderId id) async {
    final record = await _guardPersistence(() => _store.getOrder(id.value));
    if (record == null) {
      throw const OrderingOrderNotFoundException();
    }

    return _mapOrder(record);
  }

  @override
  Future<OrderId> createDraft(DateTime createdAt) async {
    final id = await _guardPersistence(
      () => _store.insertDraft(
        createdAtUtcMilliseconds: createdAt.toUtc().millisecondsSinceEpoch,
      ),
    );

    return OrderId.fromStored(id);
  }

  @override
  Future<void> replaceDraftLines({
    required Order current,
    required Order replacement,
  }) async {
    final affected = await _guardPersistence(
      () => _store.replaceDraftLines(
        id: current.id.value,
        expectedRevision: current.revision.value,
        totalMinorUnits: replacement.money?.minorUnits,
        currencyCode: replacement.money?.currency.code,
        lines: _storedLines(replacement),
      ),
    );
    _requireChanged(affected);
  }

  @override
  Future<void> placeOrder({
    required Order current,
    required Order placed,
  }) async {
    final affected = await _guardPersistence(
      () => _store.placeOrder(
        id: current.id.value,
        expectedRevision: current.revision.value,
        totalMinorUnits: placed.money!.minorUnits,
        currencyCode: placed.money!.currency.code,
        placedAtUtcMilliseconds: placed.placedAt!.millisecondsSinceEpoch,
        lines: _storedLines(placed),
      ),
    );
    _requireChanged(affected);
  }

  @override
  Future<void> cancelOrder({
    required Order current,
    required Order cancelled,
  }) async {
    final affected = await _guardPersistence(
      () => _store.cancelOrder(
        id: current.id.value,
        expectedRevision: current.revision.value,
        cancelledAtUtcMilliseconds:
            cancelled.cancelledAt!.millisecondsSinceEpoch,
      ),
    );
    _requireChanged(affected);
  }

  Order _mapOrder(StoredOrder record) => Order.fromStored(
    id: record.id,
    lines: record.lines.map(_mapLine).toList(growable: false),
    totalMinorUnits: record.totalMinorUnits,
    currencyCode: record.currencyCode,
    statusValue: record.statusValue,
    revision: record.revision,
    createdAtUtcMilliseconds: record.createdAtUtcMilliseconds,
    placedAtUtcMilliseconds: record.placedAtUtcMilliseconds,
    cancelledAtUtcMilliseconds: record.cancelledAtUtcMilliseconds,
  );

  OrderLine _mapLine(StoredOrderLine record) => OrderLine.fromStored(
    productId: record.catalogProductId,
    title: record.productTitleSnapshot,
    unitPriceMinorUnits: record.unitPriceMinorUnits,
    currencyCode: record.currencyCode,
    quantity: record.quantity,
    catalogRevision: record.catalogRevision,
  );

  List<StoredOrderLine> _storedLines(Order order) =>
      List<StoredOrderLine>.unmodifiable(
        order.lines.map(
          (line) => StoredOrderLine(
            catalogProductId: line.product.value,
            productTitleSnapshot: line.title.value,
            unitPriceMinorUnits: line.unitPrice.minorUnits,
            currencyCode: line.currency.code,
            quantity: line.quantity.value,
            catalogRevision: line.catalogRevision.value,
          ),
        ),
      );

  void _requireChanged(int affected) {
    if (affected == 0) {
      throw const OrderingTransitionException(
        OrderingTransitionFailure.concurrentStateChange,
      );
    }
  }

  Future<T> _guardPersistence<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on OrderingStoreException catch (_, stackTrace) {
      _throwPersistence(stackTrace);
    }
  }

  Never _throwPersistence(StackTrace stackTrace) => Error.throwWithStackTrace(
    const OrderingPersistenceException(),
    stackTrace,
  );
}
