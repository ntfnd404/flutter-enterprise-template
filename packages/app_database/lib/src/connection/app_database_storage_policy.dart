import 'package:app_database/src/configuration/app_database_configuration.dart';
import 'package:app_database/src/connection/app_database_connection.dart';
import 'package:app_database/src/connection/app_database_open_exception.dart';

/// Validates the selected physical storage against application policy.
void validateAppDatabaseStoragePolicy({
  required AppDatabaseWebStoragePolicy policy,
  required AppDatabaseStorageKind storageKind,
}) {
  switch ((policy, storageKind)) {
    case (_, AppDatabaseStorageKind.native):
    case (
      AppDatabaseWebStoragePolicy.requirePersistent,
      AppDatabaseStorageKind.opfsShared ||
          AppDatabaseStorageKind.opfsLocks ||
          AppDatabaseStorageKind.sharedIndexedDb ||
          AppDatabaseStorageKind.unsafeIndexedDb,
    ):
    case (
      AppDatabaseWebStoragePolicy.requireSafePersistent,
      AppDatabaseStorageKind.opfsShared ||
          AppDatabaseStorageKind.opfsLocks ||
          AppDatabaseStorageKind.sharedIndexedDb,
    ):
      return;
    case (
      AppDatabaseWebStoragePolicy.requirePersistent,
      AppDatabaseStorageKind.inMemory,
    ):
      throw const AppDatabaseOpenException(
        AppDatabaseOpenFailure.persistentWebStorageUnavailable,
      );
    case (
      AppDatabaseWebStoragePolicy.requireSafePersistent,
      AppDatabaseStorageKind.unsafeIndexedDb || AppDatabaseStorageKind.inMemory,
    ):
      throw const AppDatabaseOpenException(
        AppDatabaseOpenFailure.safePersistentWebStorageUnavailable,
      );
  }
}
