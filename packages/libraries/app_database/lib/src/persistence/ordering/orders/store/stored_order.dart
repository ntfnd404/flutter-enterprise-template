import 'package:app_database/src/persistence/ordering/orders/store/stored_order_line.dart';

/// Provider-neutral persisted Ordering aggregate snapshot.
final class StoredOrder({
  /// Positive database-assigned identity.
  required final int id,

  /// Raw stable lifecycle representation.
  required final int statusValue,

  /// Raw total, absent while an empty draft has no money.
  required final int? totalMinorUnits,

  /// Raw currency paired with [totalMinorUnits].
  required final String? currencyCode,

  /// Raw optimistic revision.
  required final int revision,

  /// UTC Unix milliseconds at draft creation.
  required final int createdAtUtcMilliseconds,

  /// UTC Unix milliseconds at placement, if placed.
  required final int? placedAtUtcMilliseconds,

  /// UTC Unix milliseconds at cancellation, if cancelled.
  required final int? cancelledAtUtcMilliseconds,

  required List<StoredOrderLine> lines,
}) {
  /// Creates an immutable raw aggregate record.
  this;

  /// Immutable stored line snapshots.
  final List<StoredOrderLine> lines = List<StoredOrderLine>.unmodifiable(lines);
}
