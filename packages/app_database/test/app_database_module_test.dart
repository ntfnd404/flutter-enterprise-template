import 'dart:async';
import 'dart:io';

import 'package:app_database/app_database_catalog.dart';
import 'package:app_database/app_database_composition.dart';
import 'package:app_database/src/app_database_module.dart'
    show createAppDatabaseModuleForTesting;
import 'package:app_database/src/connection/app_database_connection.dart';
import 'package:drift/drift.dart';
import 'package:drift/isolate.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:test/test.dart';

void main() {
  const operationTimeout = Duration(seconds: 10);
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'template-app-database-',
    );
  });

  tearDown(() => directory.delete(recursive: true));

  test('persists data after the module is closed and reopened', () async {
    final configuration = _configuration(directory);
    final first = createAppDatabaseModule(configuration: configuration);
    addTearDown(first.dispose);
    await first.initialize();
    await first.catalogItemsStore.insertItem('Persisted item');
    await first.dispose();

    final reopened = createAppDatabaseModule(configuration: configuration);
    addTearDown(reopened.dispose);
    await reopened.initialize();

    final items = await reopened.catalogItemsStore.watchItems().first;
    expect(items, hasLength(1));
    expect(items.single.title, 'Persisted item');
  });

  test('exposes stores only while the module is ready', () async {
    final module = createAppDatabaseModule(
      configuration: _configuration(directory),
    );
    addTearDown(module.dispose);

    expect(() => module.catalogItemsStore, throwsStateError);
    await module.initialize();
    expect(() => module.catalogItemsStore, returnsNormally);
    expect(module.initialize, throwsStateError);

    final disposal = module.dispose();
    expect(() => module.catalogItemsStore, throwsStateError);
    await disposal;
    expect(() => module.catalogItemsStore, throwsStateError);
  });

  test('shares one disposal Future between concurrent callers', () async {
    final module = createAppDatabaseModule(
      configuration: _configuration(directory),
    );
    addTearDown(module.dispose);
    await module.initialize();

    final first = module.dispose();
    final second = module.dispose();

    expect(identical(first, second), isTrue);
    await first;
  });

  test('disposal racing initialization never publishes a store', () async {
    final connection = Completer<AppDatabaseConnection>();
    final closeRecorder = _RecordingCloseInterceptor();
    final executor = NativeDatabase.memory().interceptWith(closeRecorder);
    final module = createAppDatabaseModuleForTesting(
      configuration: _configuration(directory),
      connector: (_) => connection.future,
    );
    addTearDown(module.dispose);

    final initialization = module.initialize();
    var storeWasBlockedWhenInitializationCompleted = false;
    final initializationObserver = initialization.then((_) {
      expect(() => module.catalogItemsStore, throwsStateError);
      storeWasBlockedWhenInitializationCompleted = true;
    });

    final firstDisposal = module.dispose();
    final secondDisposal = module.dispose();
    expect(identical(firstDisposal, secondDisposal), isTrue);
    expect(() => module.catalogItemsStore, throwsStateError);

    connection.complete(
      AppDatabaseConnection(
        executor: executor,
        storageKind: AppDatabaseStorageKind.native,
      ),
    );

    await initialization;
    await initializationObserver;
    await firstDisposal;

    expect(storeWasBlockedWhenInitializationCompleted, isTrue);
    expect(closeRecorder.closeCount, 1);
    expect(() => module.catalogItemsStore, throwsStateError);
  });

  test('readiness failure leaves the acquired connection disposable', () async {
    final databaseFile = File(
      '${directory.path}/corrupted_template_test.sqlite',
    );
    await databaseFile.writeAsBytes(<int>[0, 1, 2, 3, 4, 5]);
    final module = createAppDatabaseModule(
      configuration: AppDatabaseConfiguration(
        databaseName: 'template_test',
        nativePath: databaseFile.path,
        webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
      ),
    );
    addTearDown(module.dispose);

    await expectLater(
      module.initialize(),
      throwsA(isA<DriftRemoteException>()),
    );
    expect(module.initialize, throwsStateError);
    expect(() => module.catalogItemsStore, throwsStateError);

    final firstDisposal = module.dispose();
    final secondDisposal = module.dispose();
    expect(identical(firstDisposal, secondDisposal), isTrue);
    await firstDisposal;
  });

  test('a failed module is terminal and remains safely disposable', () async {
    final module = createAppDatabaseModule(
      configuration: AppDatabaseConfiguration(
        databaseName: 'template_test',
        nativePath: 'relative/private/database.sqlite',
        webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
      ),
    );
    addTearDown(module.dispose);

    await expectLater(
      module.initialize(),
      throwsA(
        isA<AppDatabaseConfigurationException>().having(
          (error) => error.failure,
          'failure',
          AppDatabaseConfigurationFailure.nonAbsoluteNativePath,
        ),
      ),
    );
    expect(module.initialize, throwsStateError);
    expect(() => module.catalogItemsStore, throwsStateError);

    final first = module.dispose();
    final second = module.dispose();
    expect(identical(first, second), isTrue);
    await first;
  });

  test('policy rejection leaves the acquired executor disposable', () async {
    final closeRecorder = _RecordingCloseInterceptor();
    final executor = NativeDatabase.memory().interceptWith(closeRecorder);
    final module = createAppDatabaseModuleForTesting(
      configuration: _configuration(directory),
      connector: (_) => Future<AppDatabaseConnection>.value(
        AppDatabaseConnection(
          executor: executor,
          storageKind: AppDatabaseStorageKind.inMemory,
        ),
      ),
    );
    addTearDown(module.dispose);

    await expectLater(
      module.initialize(),
      throwsA(
        isA<AppDatabaseOpenException>().having(
          (error) => error.failure,
          'failure',
          AppDatabaseOpenFailure.persistentWebStorageUnavailable,
        ),
      ),
    );
    expect(module.initialize, throwsStateError);

    await module.dispose();
    expect(closeRecorder.closeCount, 1);
  });

  test('cleanup failure does not replace policy rejection', () async {
    final cleanupFailure = StateError('controlled cleanup failure');
    final closeRecorder = _RecordingCloseInterceptor(
      closeFailure: cleanupFailure,
    );
    final executor = NativeDatabase.memory().interceptWith(closeRecorder);
    final module = createAppDatabaseModuleForTesting(
      configuration: _configuration(directory),
      connector: (_) => Future<AppDatabaseConnection>.value(
        AppDatabaseConnection(
          executor: executor,
          storageKind: AppDatabaseStorageKind.inMemory,
        ),
      ),
    );

    final initialization = module.initialize();
    await expectLater(
      initialization,
      throwsA(isA<AppDatabaseOpenException>()),
    );

    final firstDisposal = module.dispose();
    final secondDisposal = module.dispose();
    expect(identical(firstDisposal, secondDisposal), isTrue);
    await expectLater(firstDisposal, throwsA(same(cleanupFailure)));
    await expectLater(secondDisposal, throwsA(same(cleanupFailure)));
    expect(closeRecorder.closeCount, 1);
  });

  test('maps remote native mutation contention', () async {
    final module = await _openLockedModule(directory);

    await expectLater(
      module.catalogItemsStore
          .insertItem('Blocked item')
          .timeout(operationTimeout),
      throwsA(isA<CatalogItemsStoreException>()),
    );
  });

  test('maps remote native watch contention', () async {
    final module = await _openLockedModule(directory);

    await expectLater(
      module.catalogItemsStore.watchItems().first.timeout(operationTimeout),
      throwsA(isA<CatalogItemsStoreException>()),
    );
  });

  test('preserves an unexpected remote native SQLite failure', () async {
    final module = createAppDatabaseModule(
      configuration: _configuration(directory),
    );
    addTearDown(module.dispose);
    await module.initialize();

    try {
      await module.catalogItemsStore.insertItem('');
      fail('Expected the SQLite constraint failure to remain unexpected.');
    } on DriftRemoteException catch (error) {
      expect(
        error.remoteCause,
        isA<SqliteException>().having(
          (error) => error.resultCode,
          'resultCode',
          SqlError.SQLITE_CONSTRAINT,
        ),
      );
    }
  });
}

AppDatabaseConfiguration _configuration(Directory directory) =>
    AppDatabaseConfiguration(
      databaseName: 'template_test',
      nativePath: '${directory.path}/template_test.sqlite',
      webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
    );

Future<AppDatabaseModule> _openLockedModule(
  Directory directory,
) async {
  final configuration = _configuration(directory);
  final module = createAppDatabaseModule(configuration: configuration);
  addTearDown(module.dispose);
  await module.initialize();

  final lock = sqlite.sqlite3.open(configuration.nativePath!);
  addTearDown(() {
    try {
      lock.execute('ROLLBACK');
    } on SqliteException {
      // A failed test may release or invalidate the transaction first.
    } finally {
      lock.close();
    }
  });
  lock.execute('BEGIN EXCLUSIVE');

  return module;
}

final class _RecordingCloseInterceptor extends QueryInterceptor {
  _RecordingCloseInterceptor({this.closeFailure});

  final Object? closeFailure;
  int closeCount = 0;

  @override
  Future<void> close(QueryExecutor inner) async {
    closeCount += 1;
    await inner.close();

    final failure = closeFailure;
    if (failure != null) {
      Error.throwWithStackTrace(failure, StackTrace.current);
    }
  }
}
