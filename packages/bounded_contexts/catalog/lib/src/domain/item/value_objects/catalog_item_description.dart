import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:characters/characters.dart';

/// Canonical product description that may be empty while an item is a draft.
final class const CatalogItemDescription._(
  /// Canonical description value.
  final String value,
) {
  /// Trims user input and validates its grapheme-cluster length.
  factory CatalogItemDescription.fromUserInput(String rawValue) {
    final value = rawValue.trim();
    if (!_hasValidLength(value)) {
      throw const CatalogInvalidDescriptionException();
    }

    return CatalogItemDescription._(value);
  }

  /// Reconstitutes a canonical persisted description without repairing it.
  factory CatalogItemDescription.fromStored(String storedValue) {
    if (storedValue != storedValue.trim() || !_hasValidLength(storedValue)) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogItemDescription._(storedValue);
  }

  /// Maximum accepted description length in grapheme clusters.
  static const int maxLength = 2000;

  /// Whether the draft still has no product description.
  bool get isEmpty => value.isEmpty;

  static bool _hasValidLength(String value) =>
      value.characters.length <= maxLength;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogItemDescription && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
