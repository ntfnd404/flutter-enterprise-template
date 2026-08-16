import 'package:ordering/src/domain/order/order.dart';
import 'package:ordering/src/domain/order/value_objects/order_id.dart';

/// Domain-owned persistence port for Order aggregates.
abstract interface class OrderRepository {
  /// Watches all authoritative aggregates.
  Stream<List<Order>> watchOrders();

  /// Watches one authoritative aggregate.
  Stream<Order> watchOrder(OrderId id);

  /// Loads one authoritative aggregate.
  Future<Order> getOrder(OrderId id);

  /// Persists an empty draft and returns its identity.
  Future<OrderId> createDraft(DateTime createdAt);

  /// Commits complete draft-line replacement optimistically.
  Future<void> replaceDraftLines({
    required Order current,
    required Order replacement,
  });

  /// Commits refreshed lines and placement optimistically.
  Future<void> placeOrder({
    required Order current,
    required Order placed,
  });

  /// Commits cancellation optimistically.
  Future<void> cancelOrder({
    required Order current,
    required Order cancelled,
  });
}
