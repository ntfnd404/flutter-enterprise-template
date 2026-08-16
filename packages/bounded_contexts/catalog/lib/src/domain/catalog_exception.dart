/// Failure owned by the catalog context.
sealed class CatalogException implements Exception {
  /// Creates the base of a context-owned failure hierarchy.
  const CatalogException();
}

/// Expected operational failure that a caller may handle explicitly.
///
/// This is a classification boundary, not a universal presentation policy.
/// Callers handle only the concrete failures documented for an operation.
sealed class CatalogExpectedException extends CatalogException {
  /// Creates the base of an explicitly handleable operational failure.
  const CatalogExpectedException();
}

/// The submitted item title violates catalog invariants.
final class CatalogInvalidTitleException extends CatalogExpectedException {
  /// Creates a sanitized invalid-title failure.
  const CatalogInvalidTitleException();

  @override
  String toString() => 'CatalogInvalidTitleException(invalid title)';
}

/// The submitted item description violates catalog invariants.
final class CatalogInvalidDescriptionException
    extends CatalogExpectedException {
  /// Creates a sanitized invalid-description failure.
  const CatalogInvalidDescriptionException();

  @override
  String toString() =>
      'CatalogInvalidDescriptionException(invalid description)';
}

/// The submitted item price violates catalog invariants.
final class CatalogInvalidPriceException extends CatalogExpectedException {
  /// Creates a sanitized invalid-price failure.
  const CatalogInvalidPriceException();

  @override
  String toString() => 'CatalogInvalidPriceException(invalid price)';
}

/// The submitted category name violates catalog invariants.
final class CatalogInvalidCategoryNameException
    extends CatalogExpectedException {
  /// Creates a sanitized invalid-category-name failure.
  const CatalogInvalidCategoryNameException();

  @override
  String toString() =>
      'CatalogInvalidCategoryNameException(invalid category name)';
}

/// The requested catalog item does not exist.
final class CatalogItemNotFoundException extends CatalogExpectedException {
  /// Creates a sanitized missing-item failure.
  const CatalogItemNotFoundException();

  @override
  String toString() => 'CatalogItemNotFoundException(item not found)';
}

/// The requested catalog category does not exist.
final class CatalogCategoryNotFoundException extends CatalogExpectedException {
  /// Creates a sanitized missing-category failure.
  const CatalogCategoryNotFoundException();

  @override
  String toString() => 'CatalogCategoryNotFoundException(category not found)';
}

/// Stable reason why an item cannot be published.
enum CatalogItemPublicationFailure {
  /// Only draft items can be published.
  itemNotDraft,

  /// A publishable item needs a non-empty description.
  descriptionRequired,

  /// A publishable item needs a price greater than zero.
  positivePriceRequired,

  /// The placeholder currency cannot be published.
  concreteCurrencyRequired,

  /// A publishable item needs an assigned category.
  categoryRequired,

  /// The assigned category must be active.
  activeCategoryRequired,
}

/// A draft does not satisfy the product publication policy.
final class CatalogItemPublicationException extends CatalogExpectedException {
  /// Creates a sanitized publication failure with a stable [failure].
  const CatalogItemPublicationException(this.failure);

  /// Policy rule that rejected publication.
  final CatalogItemPublicationFailure failure;

  @override
  String toString() => 'CatalogItemPublicationException(${failure.name})';
}

/// Stable reason why an item lifecycle transition was rejected.
enum CatalogItemTransitionFailure {
  /// Only draft items may have their product details revised.
  itemNotDraft,

  /// Only published items can be archived.
  itemNotPublished,

  /// The caller's snapshot was stale or state changed again before commit.
  concurrentStateChange,
}

/// An item cannot complete the requested lifecycle transition.
final class CatalogItemTransitionException extends CatalogExpectedException {
  /// Creates a sanitized transition failure with a stable [failure].
  const CatalogItemTransitionException(this.failure);

  /// Lifecycle rule that rejected the transition.
  final CatalogItemTransitionFailure failure;

  @override
  String toString() => 'CatalogItemTransitionException(${failure.name})';
}

/// Local catalog persistence is temporarily unavailable.
final class CatalogPersistenceException extends CatalogExpectedException {
  /// Creates a sanitized persistence failure.
  const CatalogPersistenceException();

  @override
  String toString() =>
      'CatalogPersistenceException(catalog storage unavailable)';
}

/// Persisted data violates catalog domain invariants.
///
/// This is an unexpected failure. Presentation must not convert it into an
/// ordinary operational state; root diagnostics retain responsibility for it.
final class CatalogDataIntegrityException extends CatalogException {
  /// Creates a sanitized data-integrity failure.
  const CatalogDataIntegrityException();

  @override
  String toString() =>
      'CatalogDataIntegrityException(catalog data violates invariants)';
}
