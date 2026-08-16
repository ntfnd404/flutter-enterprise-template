import 'package:app_database/app_database_composition.dart';
import 'package:app_database/src/connection/native.dart' as native;
import 'package:test/test.dart';

void main() {
  test('creates typed connection configuration', () {
    final configuration = AppDatabaseConfiguration(
      databaseName: 'template',
      nativePath: '/tmp/template.sqlite',
      webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
    );

    expect(configuration.databaseName, 'template');
    expect(configuration.nativePath, '/tmp/template.sqlite');
    expect(configuration.sqlite3Wasm, Uri(path: 'sqlite3.wasm'));
    expect(configuration.driftWorker, Uri(path: 'drift_worker.js'));
    expect(
      configuration.webStoragePolicy,
      AppDatabaseWebStoragePolicy.requirePersistent,
    );
  });

  test('rejects invalid values with typed privacy-safe failures', () {
    final scenarios = <(AppDatabaseConfigurationFailure, void Function())>[
      (
        AppDatabaseConfigurationFailure.emptyDatabaseName,
        () => AppDatabaseConfiguration(
          databaseName: '   ',
          webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
        ),
      ),
      (
        AppDatabaseConfigurationFailure.nonCanonicalDatabaseName,
        () => AppDatabaseConfiguration(
          databaseName: ' private-database ',
          webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
        ),
      ),
      (
        AppDatabaseConfigurationFailure.emptyNativePath,
        () => AppDatabaseConfiguration(
          databaseName: 'template',
          nativePath: ' ',
          webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
        ),
      ),
      (
        AppDatabaseConfigurationFailure.emptySqlite3WasmUri,
        () => AppDatabaseConfiguration(
          databaseName: 'template',
          sqlite3Wasm: Uri(),
          webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
        ),
      ),
      (
        AppDatabaseConfigurationFailure.emptyDriftWorkerUri,
        () => AppDatabaseConfiguration(
          databaseName: 'template',
          driftWorker: Uri(),
          webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
        ),
      ),
    ];

    for (final (expectedFailure, callback) in scenarios) {
      try {
        callback();
        fail('Invalid database configuration must be rejected.');
      } on AppDatabaseConfigurationException catch (error) {
        expect(error.failure, expectedFailure);
        expect(
          error.toString(),
          'AppDatabaseConfigurationException(${expectedFailure.name})',
        );
      }
    }
  });

  test('allows significant whitespace in a native filesystem path', () {
    final configuration = AppDatabaseConfiguration(
      databaseName: 'template',
      nativePath: '/tmp/Application Data/template.sqlite',
      webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
    );

    expect(
      configuration.nativePath,
      '/tmp/Application Data/template.sqlite',
    );
  });

  test('rejects a missing native path with a typed failure', () async {
    final configuration = AppDatabaseConfiguration(
      databaseName: 'template',
      webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
    );

    try {
      await native.connect(configuration);
      fail('A native connection requires a filesystem path.');
    } on AppDatabaseConfigurationException catch (error) {
      expect(
        error.failure,
        AppDatabaseConfigurationFailure.missingNativePath,
      );
      expect(
        error.toString(),
        'AppDatabaseConfigurationException(missingNativePath)',
      );
    }
  });

  test('rejects a relative native path without exposing it', () async {
    const privatePath = 'private/relative/database.sqlite';
    final configuration = AppDatabaseConfiguration(
      databaseName: 'template',
      nativePath: privatePath,
      webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
    );

    try {
      await native.connect(configuration);
      fail('A native connection requires an absolute filesystem path.');
    } on AppDatabaseConfigurationException catch (error) {
      expect(
        error.failure,
        AppDatabaseConfigurationFailure.nonAbsoluteNativePath,
      );
      expect(error.toString(), isNot(contains(privatePath)));
    }
  });
}
