import 'package:ordering/ordering.dart';

/// Lifecycle-free Ordering test double for tests unrelated to Order behavior.
final class NoopOrderingFacade implements OrderingFacade {
  /// Creates a no-op facade.
  const NoopOrderingFacade();

  static final OrderId _id = OrderId.fromInput(1);

  @override
  Future<void> cancelOrder(OrderId orderId) async {}

  @override
  Future<OrderId> createDraft() async => _id;

  @override
  Future<void> placeOrder(OrderId orderId) async {}

  @override
  Future<void> replaceDraftLines({
    required OrderId orderId,
    required List<OrderLineInput> lines,
  }) async {}

  @override
  Stream<Order> watchOrder(OrderId orderId) => const Stream<Order>.empty();

  @override
  Stream<List<Order>> watchOrders() => const Stream<List<Order>>.empty();
}
