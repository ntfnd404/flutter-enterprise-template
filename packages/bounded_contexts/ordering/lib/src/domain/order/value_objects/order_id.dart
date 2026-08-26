import 'package:ordering/src/domain/ordering_exception.dart';

/// Stable identity of an Order aggregate.
final class const OrderId._(
  /// Positive database-assigned scalar value.
  final int value,
) {
  /// Validates an identity received by an application command.
  factory OrderId.fromInput(int value) {
    if (value <= 0) {
      throw const OrderingInvalidOrderIdException();
    }

    return OrderId._(value);
  }

  /// Reconstitutes a persisted identity without repairing it.
  factory OrderId.fromStored(int value) {
    if (value <= 0) {
      throw const OrderingDataIntegrityException();
    }

    return OrderId._(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OrderId && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
