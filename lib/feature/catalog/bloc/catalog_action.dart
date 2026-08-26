part of 'catalog_bloc.dart';

/// One-shot command from [CatalogBloc] to its own presentation.
sealed class CatalogAction {
  const CatalogAction();
}

/// Presentation-level classification for a transient command failure.
enum CatalogFailure {
  /// User input violated the title invariant.
  invalidTitle,

  /// User input violated the product-description invariant.
  invalidDescription,

  /// User input violated the product-price invariant.
  invalidPrice,

  /// The requested item disappeared before mutation completed.
  itemNotFound,

  /// The displayed item was replaced by a newer authoritative revision.
  itemChanged,

  /// Local persistence is temporarily busy or locked.
  storageUnavailable,
}

/// Requests transient presentation of an expected command [failure].
final class ShowCatalogFailureAction extends CatalogAction {
  /// Creates a failure action.
  const ShowCatalogFailureAction(this.failure);

  /// Expected command failure to present once.
  final CatalogFailure failure;
}
