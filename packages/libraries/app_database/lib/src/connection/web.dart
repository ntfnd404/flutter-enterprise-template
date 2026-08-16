import 'package:app_database/src/configuration/app_database_configuration.dart';
import 'package:app_database/src/connection/app_database_connection.dart';
import 'package:drift/wasm.dart';

/// Opens the application database with Drift's WebAssembly backend.
Future<AppDatabaseConnection> connect(
  AppDatabaseConfiguration configuration,
) async {
  final result = await WasmDatabase.open(
    databaseName: configuration.databaseName,
    sqlite3Uri: configuration.sqlite3Wasm,
    driftWorkerUri: configuration.driftWorker,
    moveExistingIndexedDbToOpfs: true,
  );

  return AppDatabaseConnection(
    executor: result.resolvedExecutor,
    storageKind: switch (result.chosenImplementation) {
      WasmStorageImplementation.opfsShared => AppDatabaseStorageKind.opfsShared,
      WasmStorageImplementation.opfsLocks => AppDatabaseStorageKind.opfsLocks,
      WasmStorageImplementation.sharedIndexedDb =>
        AppDatabaseStorageKind.sharedIndexedDb,
      WasmStorageImplementation.unsafeIndexedDb =>
        AppDatabaseStorageKind.unsafeIndexedDb,
      WasmStorageImplementation.inMemory => AppDatabaseStorageKind.inMemory,
    },
  );
}
