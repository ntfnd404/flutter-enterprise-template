import 'package:ordering/src/domain/order/value_objects/order_line_quantity.dart';
import 'package:ordering/src/domain/ordering_exception.dart';

/// Positive Ordering-owned unit price snapshot.
final class const OrderUnitPrice._(
  /// Positive amount in minor currency units.
  final int minorUnits,
) {
  /// Validates a price received through the Catalog Published Language.
  factory OrderUnitPrice.fromExternal(int value) {
    if (value <= 0 || value > maxMinorUnits) {
      throw const OrderingDataIntegrityException();
    }

    return OrderUnitPrice._(value);
  }

  /// Reconstitutes a persisted price.
  factory OrderUnitPrice.fromStored(int value) =>
      OrderUnitPrice.fromExternal(value);

  /// Largest exactly representable cross-platform amount.
  static const int maxMinorUnits = 9007199254740991;

  /// Calculates a checked line total.
  int totalFor(OrderLineQuantity quantity) {
    if (minorUnits > maxMinorUnits ~/ quantity.value) {
      throw const OrderingMoneyOverflowException();
    }

    return minorUnits * quantity.value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderUnitPrice && minorUnits == other.minorUnits;

  @override
  int get hashCode => minorUnits.hashCode;
}
