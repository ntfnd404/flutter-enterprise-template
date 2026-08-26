import 'package:catalog/src/domain/catalog_exception.dart';

/// Optimistic concurrency token for one catalog item snapshot.
final class const CatalogItemRevision._(
  /// Stored monotonic revision value.
  final int value,
) {
  /// Reconstitutes a persisted non-negative revision.
  factory CatalogItemRevision.fromStored(int value) {
    if (value < 0 || value > maxValue) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogItemRevision._(value);
  }

  /// Largest revision exactly representable by every supported Dart runtime.
  static const int maxValue = 9007199254740991;

  /// Returns the next committed revision.
  CatalogItemRevision next() {
    if (value >= maxValue) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogItemRevision._(value + 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogItemRevision && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
