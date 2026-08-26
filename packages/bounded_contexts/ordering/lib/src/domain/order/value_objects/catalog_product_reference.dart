import 'package:ordering/src/domain/ordering_exception.dart';

/// Ordering-owned scalar reference to a Catalog product.
final class const CatalogProductReference._(
  /// Positive upstream scalar identity.
  final int value,
) {
  /// Validates a product identity from a command.
  factory CatalogProductReference.fromInput(int value) {
    if (value <= 0) {
      throw const OrderingProductUnavailableException();
    }

    return CatalogProductReference._(value);
  }

  /// Reconstitutes a persisted or Published Language identity.
  factory CatalogProductReference.fromExternal(int value) {
    if (value <= 0) {
      throw const OrderingDataIntegrityException();
    }

    return CatalogProductReference._(value);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogProductReference && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
