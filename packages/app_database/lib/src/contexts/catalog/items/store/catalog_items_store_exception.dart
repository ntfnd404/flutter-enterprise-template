/// Expected temporary SQLite contention at the Catalog persistence boundary.
///
/// Only SQLite `BUSY` and `LOCKED` conditions are translated to this type.
/// Other vendor failures remain unexpected and retain their original error and
/// stack trace.
final class CatalogItemsStoreException implements Exception {
  /// Creates a sanitized persistence failure.
  const CatalogItemsStoreException();

  @override
  String toString() => 'CatalogItemsStoreException(storage unavailable)';
}
