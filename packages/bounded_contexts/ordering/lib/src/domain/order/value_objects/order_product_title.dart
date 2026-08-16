import 'package:ordering/src/domain/ordering_exception.dart';

/// Ordering-owned product title snapshot.
final class const OrderProductTitle._(
  /// Canonical non-empty title snapshot.
  final String value,
) {
  /// Validates a title received through the Catalog Published Language.
  factory OrderProductTitle.fromExternal(String value) {
    if (value.isEmpty || value != value.trim()) {
      throw const OrderingDataIntegrityException();
    }

    return OrderProductTitle._(value);
  }

  /// Reconstitutes a persisted title snapshot.
  factory OrderProductTitle.fromStored(String value) =>
      OrderProductTitle.fromExternal(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderProductTitle && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
