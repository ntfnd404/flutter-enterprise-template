/// Stable reasons why the physical application database could not be opened.
enum AppDatabaseOpenFailure {
  /// The browser offered only non-persistent in-memory storage.
  persistentWebStorageUnavailable,

  /// The browser offered no persistent backend safe for multiple tabs.
  safePersistentWebStorageUnavailable,
}

/// Sanitized application-database opening failure.
final class AppDatabaseOpenException implements Exception {
  /// Creates a failure without retaining browser or storage details.
  const AppDatabaseOpenException(this.failure);

  /// Stable, privacy-safe failure classification.
  final AppDatabaseOpenFailure failure;

  @override
  String toString() => 'AppDatabaseOpenException(${failure.name})';
}
