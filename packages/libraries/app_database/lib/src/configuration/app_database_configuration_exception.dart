/// Stable reasons why application-database configuration is invalid.
enum AppDatabaseConfigurationFailure {
  /// The persistent database identifier is empty.
  emptyDatabaseName,

  /// The persistent database identifier has leading or trailing whitespace.
  nonCanonicalDatabaseName,

  /// A native database connection has no filesystem path.
  missingNativePath,

  /// A supplied native filesystem path contains only whitespace.
  emptyNativePath,

  /// A supplied native filesystem path is not absolute.
  nonAbsoluteNativePath,

  /// The Web SQLite asset URI is empty.
  emptySqlite3WasmUri,

  /// The Web Drift worker asset URI is empty.
  emptyDriftWorkerUri,
}

/// Sanitized configuration failure at the application-database boundary.
final class AppDatabaseConfigurationException implements Exception {
  /// Creates a failure without retaining the rejected configuration value.
  const AppDatabaseConfigurationException(this.failure);

  /// Stable, privacy-safe failure classification.
  final AppDatabaseConfigurationFailure failure;

  @override
  String toString() => 'AppDatabaseConfigurationException(${failure.name})';
}
