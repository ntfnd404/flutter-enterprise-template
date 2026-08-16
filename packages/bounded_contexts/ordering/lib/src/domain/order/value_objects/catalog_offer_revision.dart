import 'package:ordering/src/domain/ordering_exception.dart';

/// Catalog revision represented by an Ordering line snapshot.
final class const CatalogOfferRevision._(
  /// Non-negative Catalog revision.
  final int value,
) {
  /// Validates an upstream or persisted revision.
  factory CatalogOfferRevision.fromExternal(int value) {
    if (value < 0 || value > maxValue) {
      throw const OrderingDataIntegrityException();
    }

    return CatalogOfferRevision._(value);
  }

  /// Largest exactly representable cross-platform revision.
  static const int maxValue = 9007199254740991;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogOfferRevision && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
