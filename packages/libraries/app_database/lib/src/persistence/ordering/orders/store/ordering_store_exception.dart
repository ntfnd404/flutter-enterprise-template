/// Expected temporary SQLite contention at an Ordering persistence boundary.
final class OrderingStoreException implements Exception {
  /// Creates a sanitized expected persistence failure.
  const OrderingStoreException();

  @override
  String toString() => 'OrderingStoreException(storage unavailable)';
}
