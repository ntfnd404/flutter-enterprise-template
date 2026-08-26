import 'package:ordering/src/domain/ordering_exception.dart';

/// Ordering-owned canonical currency representation.
final class const OrderCurrency._(
  /// Canonical three-letter upper-case code.
  final String code,
) {
  /// Validates a Published Language currency.
  factory OrderCurrency.fromExternal(String value) {
    if (!_isValid(value)) {
      throw const OrderingDataIntegrityException();
    }

    return OrderCurrency._(value);
  }

  /// Reconstitutes a persisted currency.
  factory OrderCurrency.fromStored(String value) =>
      OrderCurrency.fromExternal(value);

  static final RegExp _pattern = RegExp(r'^[A-Z]{3}$');

  static bool _isValid(String value) =>
      value != 'XXX' && _pattern.hasMatch(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OrderCurrency && code == other.code;

  @override
  int get hashCode => code.hashCode;
}
