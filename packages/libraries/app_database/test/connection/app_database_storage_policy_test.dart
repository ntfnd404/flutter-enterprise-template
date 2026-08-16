import 'package:app_database/app_database_composition.dart';
import 'package:app_database/src/connection/app_database_connection.dart';
import 'package:app_database/src/connection/app_database_storage_policy.dart';
import 'package:test/test.dart';

void main() {
  test('persistent policy accepts every persistent storage kind', () {
    for (final storageKind in <AppDatabaseStorageKind>[
      AppDatabaseStorageKind.native,
      AppDatabaseStorageKind.opfsShared,
      AppDatabaseStorageKind.opfsLocks,
      AppDatabaseStorageKind.sharedIndexedDb,
      AppDatabaseStorageKind.unsafeIndexedDb,
    ]) {
      expect(
        () => validateAppDatabaseStoragePolicy(
          policy: AppDatabaseWebStoragePolicy.requirePersistent,
          storageKind: storageKind,
        ),
        returnsNormally,
      );
    }
  });

  test('persistent policy rejects non-persistent memory', () {
    expect(
      () => validateAppDatabaseStoragePolicy(
        policy: AppDatabaseWebStoragePolicy.requirePersistent,
        storageKind: AppDatabaseStorageKind.inMemory,
      ),
      throwsA(
        isA<AppDatabaseOpenException>().having(
          (error) => error.failure,
          'failure',
          AppDatabaseOpenFailure.persistentWebStorageUnavailable,
        ),
      ),
    );
  });

  test('safe policy rejects unsafe IndexedDB and memory', () {
    for (final storageKind in <AppDatabaseStorageKind>[
      AppDatabaseStorageKind.unsafeIndexedDb,
      AppDatabaseStorageKind.inMemory,
    ]) {
      expect(
        () => validateAppDatabaseStoragePolicy(
          policy: AppDatabaseWebStoragePolicy.requireSafePersistent,
          storageKind: storageKind,
        ),
        throwsA(
          isA<AppDatabaseOpenException>().having(
            (error) => error.failure,
            'failure',
            AppDatabaseOpenFailure.safePersistentWebStorageUnavailable,
          ),
        ),
      );
    }
  });

  test('safe policy accepts coordinated persistent storage', () {
    for (final storageKind in <AppDatabaseStorageKind>[
      AppDatabaseStorageKind.native,
      AppDatabaseStorageKind.opfsShared,
      AppDatabaseStorageKind.opfsLocks,
      AppDatabaseStorageKind.sharedIndexedDb,
    ]) {
      expect(
        () => validateAppDatabaseStoragePolicy(
          policy: AppDatabaseWebStoragePolicy.requireSafePersistent,
          storageKind: storageKind,
        ),
        returnsNormally,
      );
    }
  });
}
