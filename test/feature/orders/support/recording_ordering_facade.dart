import 'dart:async';

import 'package:ordering/ordering.dart';

final class RecordingOrderingFacade implements OrderingFacade {
  final _watches = <StreamController<List<Order>>>[];
  final _watchCancellations = <Completer<void>>[];
  final _watchWaiters = <({int count, Completer<void> completer})>[];

  Future<OrderId> Function()? createDraftHandler;
  Future<void> Function(OrderId orderId)? cancelHandler;
  int createDraftCount = 0;
  int watchCancellationCount = 0;

  int get watchCount => _watches.length;

  Future<void> waitForWatchCount(int count) {
    if (_watches.length >= count) {
      return Future.value();
    }
    final completer = Completer<void>();
    _watchWaiters.add((count: count, completer: completer));

    return completer.future;
  }

  @override
  Stream<List<Order>> watchOrders() {
    final cancellation = Completer<void>();
    final controller = StreamController<List<Order>>(
      onCancel: () {
        watchCancellationCount += 1;
        if (!cancellation.isCompleted) {
          cancellation.complete();
        }
      },
    );
    _watches.add(controller);
    _watchCancellations.add(cancellation);
    for (final waiter in _watchWaiters.toList()) {
      if (_watches.length >= waiter.count) {
        _watchWaiters.remove(waiter);
        waiter.completer.complete();
      }
    }

    return controller.stream;
  }

  Future<void> waitForWatchCancellation(int index) =>
      _watchCancellations[index].future;

  void emitOrders(List<Order> orders) => _watches.last.add(orders);

  Future<void> emitWatchError(Object error, [StackTrace? stackTrace]) async {
    _watches.last.addError(error, stackTrace);
    await _watches.last.close();
  }

  Future<void> completeWatch() => _watches.last.close();

  @override
  Future<OrderId> createDraft() {
    createDraftCount += 1;

    return createDraftHandler?.call() ??
        Future.value(OrderId.fromStored(createDraftCount));
  }

  @override
  Future<void> cancelOrder(OrderId orderId) =>
      cancelHandler?.call(orderId) ?? Future.value();

  @override
  Future<void> placeOrder(OrderId orderId) => Future.value();

  @override
  Future<void> replaceDraftLines({
    required OrderId orderId,
    required List<OrderLineInput> lines,
  }) => Future.value();

  @override
  Stream<Order> watchOrder(OrderId orderId) => const Stream.empty();

  Future<void> dispose() async {
    for (final watch in _watches) {
      if (!watch.isClosed) {
        await watch.close();
      }
    }
  }
}
