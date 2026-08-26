part of 'catalog_bloc.dart';

/// Lifecycle of the authoritative catalog observation.
enum CatalogObservationStatus {
  /// The first snapshot or a retry is pending.
  loading,

  /// The authoritative stream is active and has produced data.
  ready,

  /// The authoritative stream ended or is temporarily unavailable.
  unavailable,
}

/// Immutable persistent state rendered by catalog presentation.
final class CatalogState {
  CatalogState._({
    required List<CatalogItem> items,
    required this.observationStatus,
  }) : items = List<CatalogItem>.unmodifiable(items);

  /// Creates a loading state, optionally preserving a stale snapshot.
  factory CatalogState.loading({List<CatalogItem> items = const []}) =>
      CatalogState._(
        items: items,
        observationStatus: CatalogObservationStatus.loading,
      );

  /// Creates a ready state with authoritative [items].
  factory CatalogState.ready({required List<CatalogItem> items}) =>
      CatalogState._(
        items: items,
        observationStatus: CatalogObservationStatus.ready,
      );

  /// Creates an unavailable state while preserving the last known [items].
  factory CatalogState.unavailable({required List<CatalogItem> items}) =>
      CatalogState._(
        items: items,
        observationStatus: CatalogObservationStatus.unavailable,
      );

  /// Last catalog snapshot delivered by the application facade.
  final List<CatalogItem> items;

  /// Current lifecycle of the authoritative stream.
  final CatalogObservationStatus observationStatus;

  /// Whether an initial observation or retry is pending.
  bool get isLoading => observationStatus == CatalogObservationStatus.loading;
}
