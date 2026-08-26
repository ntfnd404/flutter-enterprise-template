/// Failure owned by the Ordering bounded context.
sealed class OrderingException implements Exception {
  /// Creates the base of the context-owned failure hierarchy.
  const OrderingException();
}

/// Expected operational failure that callers may classify per operation.
sealed class OrderingExpectedException extends OrderingException {
  /// Creates an explicitly handleable operational failure.
  const OrderingExpectedException();
}

/// A submitted order identity is invalid.
final class OrderingInvalidOrderIdException extends OrderingExpectedException {
  /// Creates a sanitized invalid-identity failure.
  const OrderingInvalidOrderIdException();

  @override
  String toString() => 'OrderingInvalidOrderIdException(invalid order id)';
}

/// A submitted line quantity violates Ordering invariants.
final class OrderingInvalidQuantityException extends OrderingExpectedException {
  /// Creates a sanitized invalid-quantity failure.
  const OrderingInvalidQuantityException();

  @override
  String toString() => 'OrderingInvalidQuantityException(invalid quantity)';
}

/// A draft exceeds the supported number of distinct product lines.
final class OrderingTooManyLinesException extends OrderingExpectedException {
  /// Creates a sanitized line-limit failure.
  const OrderingTooManyLinesException();

  @override
  String toString() => 'OrderingTooManyLinesException(too many lines)';
}

/// One product occurs more than once in a replacement command.
final class OrderingDuplicateProductException
    extends OrderingExpectedException {
  /// Creates a sanitized duplicate-product failure.
  const OrderingDuplicateProductException();

  @override
  String toString() => 'OrderingDuplicateProductException(duplicate product)';
}

/// Placement was requested for an empty draft.
final class OrderingEmptyOrderException extends OrderingExpectedException {
  /// Creates a sanitized empty-order failure.
  const OrderingEmptyOrderException();

  @override
  String toString() => 'OrderingEmptyOrderException(empty order)';
}

/// Order lines use more than one currency.
final class OrderingMixedCurrencyException extends OrderingExpectedException {
  /// Creates a sanitized mixed-currency failure.
  const OrderingMixedCurrencyException();

  @override
  String toString() => 'OrderingMixedCurrencyException(mixed currencies)';
}

/// Checked integer arithmetic exceeded the cross-platform safe range.
final class OrderingMoneyOverflowException extends OrderingExpectedException {
  /// Creates a sanitized arithmetic failure.
  const OrderingMoneyOverflowException();

  @override
  String toString() => 'OrderingMoneyOverflowException(money overflow)';
}

/// A requested Catalog product is not currently available for Ordering.
final class OrderingProductUnavailableException
    extends OrderingExpectedException {
  /// Creates a sanitized product-availability failure.
  const OrderingProductUnavailableException();

  @override
  String toString() =>
      'OrderingProductUnavailableException(product unavailable)';
}

/// The Catalog Published Language is temporarily unavailable.
final class OrderingCatalogUnavailableException
    extends OrderingExpectedException {
  /// Creates a sanitized upstream-availability failure.
  const OrderingCatalogUnavailableException();

  @override
  String toString() =>
      'OrderingCatalogUnavailableException(catalog unavailable)';
}

/// The requested Order does not exist.
final class OrderingOrderNotFoundException extends OrderingExpectedException {
  /// Creates a sanitized missing-order failure.
  const OrderingOrderNotFoundException();

  @override
  String toString() => 'OrderingOrderNotFoundException(order not found)';
}

/// Stable reason why an Order transition was rejected.
enum OrderingTransitionFailure {
  /// Only a draft can replace its lines.
  orderNotDraft,

  /// A cancelled Order is terminal.
  orderAlreadyCancelled,

  /// Persistent state changed after the command loaded its snapshot.
  concurrentStateChange,
}

/// The current Order state cannot perform the requested transition.
final class OrderingTransitionException extends OrderingExpectedException {
  /// Creates a sanitized transition failure with stable [failure].
  const OrderingTransitionException(this.failure);

  /// Rule that rejected the transition.
  final OrderingTransitionFailure failure;

  @override
  String toString() => 'OrderingTransitionException(${failure.name})';
}

/// Local Ordering persistence is temporarily unavailable.
final class OrderingPersistenceException extends OrderingExpectedException {
  /// Creates a sanitized persistence failure.
  const OrderingPersistenceException();

  @override
  String toString() =>
      'OrderingPersistenceException(ordering storage unavailable)';
}

/// Persisted or upstream data violates Ordering invariants.
final class OrderingDataIntegrityException extends OrderingException {
  /// Creates a sanitized data-integrity failure.
  const OrderingDataIntegrityException();

  @override
  String toString() =>
      'OrderingDataIntegrityException(ordering data violates invariants)';
}
