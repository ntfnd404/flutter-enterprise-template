import 'package:app_database/src/configuration/app_database_configuration_exception.dart';

/// Immutable connection configuration for the shared physical database.
final class AppDatabaseConfiguration {
  /// Creates validated connection configuration.
  ///
  /// [nativePath] is required only by the native connection implementation.
  /// The Web implementation ignores it and uses the supplied asset URIs.
  factory AppDatabaseConfiguration({
    required String databaseName,
    required AppDatabaseWebStoragePolicy webStoragePolicy,
    String? nativePath,
    Uri? sqlite3Wasm,
    Uri? driftWorker,
  }) {
    final resolvedSqlite3Wasm = sqlite3Wasm ?? Uri.parse('sqlite3.wasm');
    final resolvedDriftWorker = driftWorker ?? Uri.parse('drift_worker.js');
    final canonicalDatabaseName = databaseName.trim();
    if (canonicalDatabaseName.isEmpty) {
      throw const AppDatabaseConfigurationException(
        AppDatabaseConfigurationFailure.emptyDatabaseName,
      );
    }
    if (canonicalDatabaseName != databaseName) {
      throw const AppDatabaseConfigurationException(
        AppDatabaseConfigurationFailure.nonCanonicalDatabaseName,
      );
    }
    if (nativePath != null && nativePath.trim().isEmpty) {
      throw const AppDatabaseConfigurationException(
        AppDatabaseConfigurationFailure.emptyNativePath,
      );
    }
    if (resolvedSqlite3Wasm.toString().trim().isEmpty) {
      throw const AppDatabaseConfigurationException(
        AppDatabaseConfigurationFailure.emptySqlite3WasmUri,
      );
    }
    if (resolvedDriftWorker.toString().trim().isEmpty) {
      throw const AppDatabaseConfigurationException(
        AppDatabaseConfigurationFailure.emptyDriftWorkerUri,
      );
    }

    return AppDatabaseConfiguration._(
      databaseName: databaseName,
      nativePath: nativePath,
      sqlite3Wasm: resolvedSqlite3Wasm,
      driftWorker: resolvedDriftWorker,
      webStoragePolicy: webStoragePolicy,
    );
  }

  const AppDatabaseConfiguration._({
    required this.databaseName,
    required this.nativePath,
    required this.sqlite3Wasm,
    required this.driftWorker,
    required this.webStoragePolicy,
  });

  /// Logical storage identity used on Web and to derive the native file name.
  final String databaseName;

  /// Absolute application-owned database path used on native platforms.
  final String? nativePath;

  /// SQLite WebAssembly asset URI used on Web.
  final Uri sqlite3Wasm;

  /// Drift worker asset URI used on Web.
  final Uri driftWorker;

  /// Minimum persistence guarantees accepted from the Web connection.
  final AppDatabaseWebStoragePolicy webStoragePolicy;
}

/// Provider-neutral persistence guarantees required from a Web database.
enum AppDatabaseWebStoragePolicy {
  /// Accepts every persistent backend, including single-tab IndexedDB.
  requirePersistent,

  /// Accepts only persistent backends safe for coordinated multi-tab access.
  requireSafePersistent,
}
