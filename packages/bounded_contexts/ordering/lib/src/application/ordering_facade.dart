import 'package:ordering/src/application/order_line_input.dart';
import 'package:ordering/src/domain/order/order.dart';
import 'package:ordering/src/domain/order/value_objects/order_id.dart';
import 'package:ordering/src/domain/ordering_exception.dart';

/// Public application API of the Ordering bounded context.
///
/// Command futures complete only after their local aggregate write commits.
/// Commands without a useful caller-owned payload return `Future<void>`;
/// authoritative aggregate state is observed through the watch operations.
/// Implementations are lifecycle-free and never transfer ownership of their
/// borrowed persistence or upstream-query dependencies to callers.
/// Data-integrity and other unexpected failures propagate to the app-owned
/// error boundary unchanged.
abstract interface class OrderingFacade {
  /// Creates an independent observation of all authoritative Orders.
  ///
  /// The returned stream is single-subscription. It first emits the current
  /// immutable snapshot in ascending Order ID order and then committed
  /// changes. Cancellation reaches persistence. Error or normal completion
  /// terminates this observation without retry; retry requires another call.
  /// Temporary contention produces [OrderingPersistenceException].
  Stream<List<Order>> watchOrders();

  /// Creates an independent observation of one authoritative Order.
  ///
  /// Ownership, termination, retry, and persistence-failure semantics match
  /// [watchOrders]. A missing Order produces
  /// [OrderingOrderNotFoundException] and terminates the observation.
  Stream<Order> watchOrder(OrderId orderId);

  /// Persists an empty draft and returns its stable identity after commit.
  ///
  /// Temporary contention produces [OrderingPersistenceException].
  Future<OrderId> createDraft();

  /// Replaces the entire line set of a persistent draft.
  ///
  /// The raw input list is snapshotted before asynchronous work. Empty input
  /// does not query Catalog. Non-empty input is resolved in one batch and may
  /// produce operation-specific validation, availability, transition, or
  /// persistence failures from the public Ordering hierarchy.
  Future<void> replaceDraftLines({
    required OrderId orderId,
    required List<OrderLineInput> lines,
  });

  /// Refreshes Catalog offers and places a non-empty draft atomically.
  ///
  /// Catalog and Ordering do not share a transaction. The committed Order
  /// retains the point-in-time snapshots returned by this request.
  Future<void> placeOrder(OrderId orderId);

  /// Cancels a draft or placed Order without querying Catalog.
  Future<void> cancelOrder(OrderId orderId);
}
