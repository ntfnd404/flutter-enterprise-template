import 'package:ordering/src/domain/order/order_line.dart';
import 'package:ordering/src/domain/order/value_objects/order_currency.dart';
import 'package:ordering/src/domain/ordering_exception.dart';

/// Checked total and currency of a non-empty Order.
final class const OrderMoney._({
  /// Positive total in minor currency units.
  required final int minorUnits,

  /// Shared currency of all lines.
  required final OrderCurrency currency,
}) {
  /// Calculates money from non-empty lines with one currency.
  factory OrderMoney.fromLines(List<OrderLine> lines) {
    if (lines.isEmpty) {
      throw const OrderingEmptyOrderException();
    }
    final currency = lines.first.currency;
    var total = 0;
    for (final line in lines) {
      if (line.currency != currency) {
        throw const OrderingMixedCurrencyException();
      }
      final lineTotal = line.totalMinorUnits;
      if (total > maxMinorUnits - lineTotal) {
        throw const OrderingMoneyOverflowException();
      }
      total += lineTotal;
    }

    return OrderMoney._(minorUnits: total, currency: currency);
  }

  /// Reconstitutes persisted money before aggregate cross-checks it.
  factory OrderMoney.fromStored({
    required int minorUnits,
    required String currencyCode,
  }) {
    if (minorUnits <= 0 || minorUnits > maxMinorUnits) {
      throw const OrderingDataIntegrityException();
    }

    return OrderMoney._(
      minorUnits: minorUnits,
      currency: OrderCurrency.fromStored(currencyCode),
    );
  }

  /// Largest exactly representable cross-platform amount.
  static const int maxMinorUnits = 9007199254740991;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderMoney &&
          minorUnits == other.minorUnits &&
          currency == other.currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);
}
