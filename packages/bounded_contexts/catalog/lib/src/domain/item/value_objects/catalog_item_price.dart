import 'package:catalog/src/domain/catalog_exception.dart';

/// Product price represented without floating-point arithmetic.
final class const CatalogItemPrice._({
  /// Non-negative amount in the currency's minor unit.
  required final int minorUnits,

  /// Canonical three-letter upper-case currency code.
  ///
  /// `XXX` is reserved for an incomplete draft, including migrated data, and
  /// cannot be published.
  required final String currencyCode,
}) {
  /// Validates user-entered price components.
  ///
  /// The currency is normalized to upper case. Minor-unit interpretation is
  /// owned by the caller's currency policy; this type never stores decimals.
  factory CatalogItemPrice.fromUserInput({
    required int minorUnits,
    required String currencyCode,
  }) {
    final normalizedCurrency = currencyCode.trim().toUpperCase();
    if (!_hasValidAmount(minorUnits) ||
        !_currencyPattern.hasMatch(normalizedCurrency)) {
      throw const CatalogInvalidPriceException();
    }

    return CatalogItemPrice._(
      minorUnits: minorUnits,
      currencyCode: normalizedCurrency,
    );
  }

  /// Reconstitutes an already canonical persisted price.
  factory CatalogItemPrice.fromStored({
    required int minorUnits,
    required String currencyCode,
  }) {
    if (!_hasValidAmount(minorUnits) ||
        !_currencyPattern.hasMatch(currencyCode)) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogItemPrice._(
      minorUnits: minorUnits,
      currencyCode: currencyCode,
    );
  }

  /// Largest integer exactly representable across Dart VM and Web runtimes.
  static const int maxSafeMinorUnits = 9007199254740991;

  /// Number of ASCII letters in the canonical currency code.
  static const int currencyCodeLength = 3;

  static final RegExp _currencyPattern = RegExp(
    '^[A-Z]{$currencyCodeLength}\$',
  );

  /// Whether this is a positive price in a concrete currency.
  bool get isPublishable => minorUnits > 0 && currencyCode != 'XXX';

  static bool _hasValidAmount(int value) =>
      value >= 0 && value <= maxSafeMinorUnits;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogItemPrice &&
          minorUnits == other.minorUnits &&
          currencyCode == other.currencyCode;

  @override
  int get hashCode => Object.hash(minorUnits, currencyCode);
}
