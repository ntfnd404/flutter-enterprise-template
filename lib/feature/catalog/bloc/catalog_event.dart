part of 'catalog_bloc.dart';

/// Input accepted by [CatalogBloc].
sealed class CatalogEvent {
  const CatalogEvent();
}

sealed class _CatalogObservationRequested extends CatalogEvent {
  const _CatalogObservationRequested();
}

/// Starts observing authoritative catalog state.
final class CatalogStarted extends _CatalogObservationRequested {
  /// Creates the startup event.
  const CatalogStarted();
}

/// Retries observation after the authoritative stream became unavailable.
final class CatalogRetryRequested extends _CatalogObservationRequested {
  /// Creates a retry request.
  const CatalogRetryRequested();
}

/// Requests creation of an unpublished product draft.
final class CatalogDraftCreated extends CatalogEvent {
  /// Creates a validated-draft request from raw presentation values.
  const CatalogDraftCreated({
    required this.title,
    required this.description,
    required this.priceMinorUnits,
    required this.currencyCode,
  });

  /// Raw user-entered title validated by the application facade.
  final String title;

  /// Raw user-entered description validated by the application facade.
  final String description;

  /// Parsed minor-unit amount validated by the application facade.
  final int priceMinorUnits;

  /// Raw currency code normalized by the application facade.
  final String currencyCode;
}

/// Requests deletion of one catalog item.
final class CatalogItemDeleted extends CatalogEvent {
  /// Creates a delete request.
  const CatalogItemDeleted({required this.id, required this.expectedRevision});

  /// Context-owned item identifier.
  final int id;

  /// Optimistic token from the authoritative item snapshot shown to the user.
  final CatalogItemRevision expectedRevision;
}
