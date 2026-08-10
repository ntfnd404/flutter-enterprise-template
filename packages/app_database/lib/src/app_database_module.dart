import 'package:app_database/src/app_database_configuration.dart';
import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/connection/app_database_connection.dart';
import 'package:app_database/src/connection/app_database_storage_policy.dart';
import 'package:app_database/src/connection/connection.dart';
import 'package:app_database/src/contexts/catalog/items/store/catalog_items_store.dart';
import 'package:app_database/src/contexts/catalog/items/store/drift_catalog_items_store.dart';

/// Owned shared physical database for one application graph.
final class AppDatabaseModule {
  AppDatabaseModule._({
    required this._configuration,
    required this._connector,
  });

  final AppDatabaseConfiguration _configuration;
  final AppDatabaseConnector _connector;

  _AppDatabaseModuleState _state = _AppDatabaseModuleState.created;
  bool _isDisposalRequested = false;
  AppDatabaseConnection? _connection;
  ApplicationDatabase? _database;
  CatalogItemsStore? _catalogItemsStore;
  Future<void>? _initialization;
  Future<void>? _disposal;

  /// Narrow borrowed Catalog persistence slice.
  ///
  /// The store becomes available only after [initialize] succeeds. The shared
  /// database module remains its owner; Catalog composition must not close it.
  CatalogItemsStore get catalogItemsStore {
    if (_state != _AppDatabaseModuleState.ready || _isDisposalRequested) {
      throw StateError('Application database module is not ready.');
    }

    return _catalogItemsStore!;
  }

  /// Opens the connection and applies pending schema migrations.
  ///
  /// App composition registers this module for rollback before awaiting this
  /// method, so every executor returned by the platform connector immediately
  /// has an owner. A failed module is terminal and must be replaced for retry.
  Future<void> initialize() {
    if (_state != _AppDatabaseModuleState.created) {
      throw StateError('Application database module was already initialized.');
    }
    _state = _AppDatabaseModuleState.initializing;

    return _initialization = _initialize();
  }

  Future<void> _initialize() async {
    try {
      final connection = await _connector(_configuration);
      _connection = connection;
      validateAppDatabaseStoragePolicy(
        policy: _configuration.webStoragePolicy,
        storageKind: connection.storageKind,
      );

      final database = ApplicationDatabase(connection.executor);
      _database = database;
      await _openAndMigrateDatabase(database);

      if (!_isDisposalRequested) {
        _catalogItemsStore = DriftCatalogItemsStore(
          dao: database.catalogItemsDao,
        );
        _state = _AppDatabaseModuleState.ready;
      }
    } catch (error, stackTrace) {
      _state = _AppDatabaseModuleState.failed;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _openAndMigrateDatabase(ApplicationDatabase database) async {
    // Drift opens its executor and applies pending migrations lazily before the
    // first query. A minimal query keeps stores unavailable until that work has
    // succeeded without coupling readiness to a context-owned table.
    await database.customSelect('SELECT 1').getSingle();
  }

  /// Closes all Drift streams and the owned physical connection.
  ///
  /// Repeated and concurrent calls observe the same disposal Future. A caller
  /// that races initialization waits for that attempt to settle before owned
  /// resources are closed. Public store access is revoked synchronously when
  /// the first disposal request is made.
  Future<void> dispose() {
    final disposal = _disposal;
    if (disposal != null) {
      return disposal;
    }

    _isDisposalRequested = true;
    return _disposal = _dispose();
  }

  Future<void> _dispose() async {
    final initialization = _initialization;
    if (_state == _AppDatabaseModuleState.initializing &&
        initialization != null) {
      try {
        await initialization;
      } on Object {
        // The initializer's caller owns its primary failure. Disposal proceeds
        // only to release resources that were acquired before that failure.
      }
    }

    if (_state == _AppDatabaseModuleState.disposed) {
      return;
    }
    _state = _AppDatabaseModuleState.disposing;

    try {
      final database = _database;
      if (database != null) {
        await database.close();
      } else {
        await _connection?.executor.close();
      }
    } finally {
      _state = _AppDatabaseModuleState.disposed;
    }
  }
}

/// Creates the application database module without opening its connection.
///
/// Register the returned module in the app resource stack immediately, then
/// await [AppDatabaseModule.initialize]. Context modules borrow its stores and
/// must never close them.
AppDatabaseModule createAppDatabaseModule({
  required AppDatabaseConfiguration configuration,
}) => AppDatabaseModule._(
  configuration: configuration,
  connector: connect,
);

/// Creates a module with a controlled package-internal connector for tests.
///
/// This function is intentionally absent from the public composition
/// entrypoint. Production composition must use [createAppDatabaseModule].
AppDatabaseModule createAppDatabaseModuleForTesting({
  required AppDatabaseConfiguration configuration,
  required AppDatabaseConnector connector,
}) => AppDatabaseModule._(
  configuration: configuration,
  connector: connector,
);

enum _AppDatabaseModuleState {
  created,
  initializing,
  ready,
  failed,
  disposing,
  disposed,
}
