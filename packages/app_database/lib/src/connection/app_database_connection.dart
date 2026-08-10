import 'package:drift/drift.dart';

/// Internal physical storage implementation selected for a connection.
enum AppDatabaseStorageKind {
  /// Native SQLite storage.
  native,

  /// OPFS coordinated through a shared worker.
  opfsShared,

  /// OPFS coordinated through dedicated lock workers.
  opfsLocks,

  /// IndexedDB coordinated through a shared worker.
  sharedIndexedDb,

  /// Persistent IndexedDB without safe multi-tab coordination.
  unsafeIndexedDb,

  /// Non-persistent browser memory.
  inMemory,
}

/// Internal opened executor and its provider-neutral storage classification.
final class AppDatabaseConnection {
  /// Creates an owned connection result.
  const AppDatabaseConnection({
    required this.executor,
    required this.storageKind,
  });

  /// Opened executor owned by the database module.
  final QueryExecutor executor;

  /// Physical storage selected by the platform connection.
  final AppDatabaseStorageKind storageKind;
}
