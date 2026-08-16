/// Expected temporary SQLite contention at a Catalog persistence boundary.
///
/// Only SQLite `BUSY` and `LOCKED` conditions are translated to this type.
/// Other vendor failures remain unexpected and retain their original error and
/// stack trace.
final class CatalogStoreException implements Exception {
  /// Creates a sanitized persistence failure.
  const CatalogStoreException();

  @override
  String toString() => 'CatalogStoreException(storage unavailable)';
}
