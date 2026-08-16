import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:characters/characters.dart';

/// Validated category name within the Catalog language.
final class const CatalogCategoryName._(
  /// Canonical category name.
  final String value,
) {
  /// Trims user input and validates the category name.
  factory CatalogCategoryName.fromUserInput(String rawValue) {
    final value = rawValue.trim();
    if (!_hasValidLength(value)) {
      throw const CatalogInvalidCategoryNameException();
    }

    return CatalogCategoryName._(value);
  }

  /// Reconstitutes an already canonical persisted category name.
  factory CatalogCategoryName.fromStored(String storedValue) {
    if (storedValue != storedValue.trim() || !_hasValidLength(storedValue)) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogCategoryName._(storedValue);
  }

  /// Maximum accepted name length in grapheme clusters.
  static const int maxLength = 80;

  static bool _hasValidLength(String value) {
    final length = value.characters.length;
    return length > 0 && length <= maxLength;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogCategoryName && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
