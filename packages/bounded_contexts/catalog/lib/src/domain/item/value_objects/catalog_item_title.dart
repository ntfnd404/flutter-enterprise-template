import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:characters/characters.dart';

/// Validated title used by the catalog domain and repository port.
final class const CatalogItemTitle._(
  /// Normalized non-empty title.
  final String value,
) {
  /// Trims user input and validates its grapheme-cluster length.
  ///
  /// Duplicate titles are allowed. No Unicode normalization, case folding, or
  /// locale-aware comparison is applied.
  factory CatalogItemTitle.fromUserInput(String rawValue) {
    final value = rawValue.trim();
    if (!_hasValidLength(value)) {
      throw const CatalogInvalidTitleException();
    }

    return CatalogItemTitle._(value);
  }

  /// Reconstitutes an already canonical persisted title.
  ///
  /// Persisted data is never repaired silently. Non-canonical or invalid input
  /// is an unexpected [CatalogDataIntegrityException].
  factory CatalogItemTitle.fromStored(String storedValue) {
    if (storedValue != storedValue.trim() || !_hasValidLength(storedValue)) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogItemTitle._(storedValue);
  }

  /// Maximum accepted title length in user-perceived grapheme clusters.
  static const int maxLength = 120;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogItemTitle && value == other.value;

  @override
  int get hashCode => value.hashCode;

  static bool _hasValidLength(String value) {
    final length = value.characters.length;

    return length > 0 && length <= maxLength;
  }
}
