import 'package:ordering/src/domain/ordering_exception.dart';

/// Positive quantity of one distinct Order product line.
final class const OrderLineQuantity._(
  /// Positive quantity.
  final int value,
) {
  /// Validates command input.
  factory OrderLineQuantity.fromInput(int value) {
    if (value <= 0) {
      throw const OrderingInvalidQuantityException();
    }

    return OrderLineQuantity._(value);
  }

  /// Reconstitutes a persisted quantity.
  factory OrderLineQuantity.fromStored(int value) {
    if (value <= 0 || value > maxValue) {
      throw const OrderingDataIntegrityException();
    }

    return OrderLineQuantity._(value);
  }

  /// Upper representation bound, not a commercial per-line limit.
  static const int maxValue = 9007199254740991;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderLineQuantity && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
