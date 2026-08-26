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
final class const AppDatabaseConnection({
  /// Opened executor owned by the database module.
  required final QueryExecutor executor,

  /// Physical storage selected by the platform connection.
  required final AppDatabaseStorageKind storageKind,
}) {
  /// Creates an owned connection result.
  this;
}
