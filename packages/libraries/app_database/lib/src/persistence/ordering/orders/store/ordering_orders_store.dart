import 'package:app_database/src/persistence/ordering/orders/store/ordering_store_exception.dart';
import 'package:app_database/src/persistence/ordering/orders/store/stored_order.dart';
import 'package:app_database/src/persistence/ordering/orders/store/stored_order_line.dart';

/// Narrow Ordering persistence contract exposed across package boundaries.
///
/// Only SQLite `BUSY` and `LOCKED` contention becomes a sanitized
/// [OrderingStoreException]. Every other direct or background boundary error
/// and its stack are preserved. Caller input that violates a SQL invariant
/// likewise retains its original vendor error. Integer timestamps are
/// caller-supplied UTC Unix milliseconds in the inclusive range
/// `0..8640000000000000`; wall-clock order is not used as a concurrency token.
abstract interface class OrderingOrdersStore {
  /// Watches all raw aggregate snapshots in stable identifier order.
  ///
  /// Every call creates a fresh single-subscription observation. Line
  /// snapshots are ordered by Catalog product identifier. This is an
  /// authoritative state stream, not an event log: rapid commits may be
  /// represented by the latest committed snapshot. Cancellation reaches the
  /// database observation, while an error or normal completion ends it without
  /// an automatic retry.
  ///
  /// This intentionally unpaged operation is suitable only while the owning
  /// context's complete aggregate set is bounded.
  Stream<List<StoredOrder>> watchOrders();

  /// Watches one raw aggregate, yielding `null` while it is absent.
  ///
  /// Every call creates a fresh single-subscription observation with the same
  /// state, cancellation, completion, and failure semantics as [watchOrders].
  Stream<StoredOrder?> watchOrder(int id);

  /// Loads one raw aggregate, or `null` when [id] is absent.
  Future<StoredOrder?> getOrder(int id);

  /// Inserts an empty draft and returns its generated identity.
  ///
  /// Every successful call creates a distinct Order. This persistence contract
  /// does not provide a durable command-idempotency key.
  Future<int> insertDraft({required int createdAtUtcMilliseconds});

  /// Replaces draft lines atomically under an optimistic condition.
  ///
  /// A successful replacement returns one, changes one parent row, increments
  /// its revision, and replaces its complete line set in the same transaction.
  /// A missing Order, stale [expectedRevision], or non-draft lifecycle returns
  /// zero and leaves both parent and lines unchanged. Repeating a successful
  /// command with the old revision therefore returns zero; this store does not
  /// retry or provide durable idempotency.
  ///
  /// The owning Ordering adapter must supply a domain-validated aggregate
  /// snapshot whose money and lines agree. SQL-expressible violations preserve
  /// their original database failure rather than becoming an expected
  /// contention failure.
  Future<int> replaceDraftLines({
    required int id,
    required int expectedRevision,
    required int? totalMinorUnits,
    required String? currencyCode,
    required List<StoredOrderLine> lines,
  });

  /// Refreshes lines and commits placement atomically.
  ///
  /// A successful placement returns one, changes one draft parent row,
  /// increments its revision, and replaces its complete line set in the same
  /// transaction. A missing Order, stale [expectedRevision], or non-draft
  /// lifecycle returns zero without changing parent or lines. No automatic
  /// retry or durable idempotency is provided.
  ///
  /// The owning Ordering adapter must supply a non-empty, domain-validated
  /// aggregate snapshot whose money and lines agree. SQL-expressible violations
  /// preserve their original database failure.
  Future<int> placeOrder({
    required int id,
    required int expectedRevision,
    required int totalMinorUnits,
    required String currencyCode,
    required int placedAtUtcMilliseconds,
    required List<StoredOrderLine> lines,
  });

  /// Cancels a draft or placed Order optimistically.
  ///
  /// Success returns one and atomically changes one row, increments its
  /// revision, and retains its current money, lines, and placement timestamp.
  /// A missing Order, stale [expectedRevision], or already-cancelled lifecycle
  /// returns zero. Repeating a successful cancellation with the old revision
  /// therefore returns zero; this store performs no automatic retry or durable
  /// idempotency.
  Future<int> cancelOrder({
    required int id,
    required int expectedRevision,
    required int cancelledAtUtcMilliseconds,
  });
}
