import 'package:ordering/src/domain/ordering_exception.dart';

/// Stable lifecycle state of an Order aggregate.
enum OrderStatus(
  /// Stable persistence representation.
  final int value,
) {
  /// Mutable persistent draft.
  draft(0),

  /// Placed point-in-time commercial snapshot.
  placed(1),

  /// Terminal cancelled aggregate.
  cancelled(2);

  /// Reconstitutes a known stable persisted value.
  static OrderStatus fromStored(int value) => switch (value) {
    0 => draft,
    1 => placed,
    2 => cancelled,
    _ => throw const OrderingDataIntegrityException(),
  };
}
