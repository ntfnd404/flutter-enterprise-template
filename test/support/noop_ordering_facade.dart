import 'package:ordering/ordering.dart';

/// Lifecycle-free Ordering test double for tests unrelated to Order behavior.
final class NoopOrderingFacade implements OrderingFacade {
  /// Creates a no-op facade.
  const NoopOrderingFacade();

  static final _id = OrderId.fromInput(1);

  @override
  Future<void> cancelOrder(OrderId orderId) => Future.value();

  @override
  Future<OrderId> createDraft() => Future.value(_id);

  @override
  Future<void> placeOrder(OrderId orderId) => Future.value();

  @override
  Future<void> replaceDraftLines({
    required OrderId orderId,
    required List<OrderLineInput> lines,
  }) => Future.value();

  @override
  Stream<Order> watchOrder(OrderId orderId) => const Stream.empty();

  @override
  Stream<List<Order>> watchOrders() => const Stream.empty();
}
