import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/diagnostics_source_guard.dart';

void main() {
  const diagnosticsRoot = 'lib/app/diagnostics';
  const loggingRoot = '$diagnosticsRoot/logging';
  const recordPath = '$loggingRoot/app_log_record.dart';
  const loggerPath = '$loggingRoot/app_logger.dart';
  const developerLoggerPath = '$loggingRoot/developer_app_logger.dart';
  const observerPath = '$loggingRoot/app_bloc_observer.dart';
  const blocRecordsPath = '$loggingRoot/records/app_bloc_log_records.dart';
  const errorRecordsPath = '$loggingRoot/records/app_error_log_records.dart';
  const startupRecordsPath =
      '$loggingRoot/records/app_startup_log_records.dart';
  const recordPaths = [
    blocRecordsPath,
    errorRecordsPath,
    startupRecordsPath,
  ];

  test('public operational logging contracts stay typed and open', () {
    final recordApi = File(recordPath).readAsStringSync();
    final loggerApi = File(loggerPath).readAsStringSync();
    final normalizedRecordApi = normalizeSource(recordApi);
    final normalizedLoggerApi = normalizeSource(loggerApi);

    expect(recordApi, contains('abstract base class AppLogRecord'));
    expect(recordApi, contains('abstract interface class AppLogFieldWriter'));
    expect(recordApi, contains('extension SPI, not a security sandbox'));
    expect(recordApi, isNot(contains('sealed class AppLogRecord')));
    expect(recordApi, isNot(contains('factory AppLogRecord.')));
    expect(
      normalizedRecordApi,
      contains(
        'abstract base class AppLogRecord { const AppLogRecord(); '
        'AppLogRecordDescriptor get descriptor; '
        'AppLogProjectionResult project(AppLogFieldWriter fields); }',
      ),
    );
    expect(
      normalizedRecordApi,
      contains(
        'abstract interface class AppLogFieldWriter { '
        'void debugType(String fieldName, Type value); '
        'void supportFlag(String fieldName, bool value); '
        'void supportCount(String fieldName, int value); '
        'void supportDuration(String fieldName, Duration value); '
        'void supportCode(String fieldName, AppLogStableCode value); }',
      ),
    );
    expect(recordApi, isNot(contains('Map<')));
    expect(recordApi, isNot(contains('dynamic')));
    expect(recordApi, isNot(contains('Object?')));

    expect(loggerApi, contains('abstract interface class AppLogger'));
    expect(
      normalizedLoggerApi,
      contains(
        'abstract interface class AppLogger { '
        'void log(AppLogRecord record); }',
      ),
    );
    expect(loggerApi, isNot(contains('void log(String')));
    expect(loggerApi, isNot(contains('Map<String')));
    expect(loggerApi, isNot(contains('severity,')));
  });

  test('production logger implementations stay synchronous and contained', () {
    final implementationFiles =
        [
              ...sortedDartFiles('lib'),
              ...sortedDartFiles('packages'),
            ]
            .where(
              (file) =>
                  file.readAsStringSync().contains('implements AppLogger'),
            )
            .toList();

    expect(
      implementationFiles.map((file) => file.path),
      [loggerPath, developerLoggerPath],
    );
    expect(
      occurrenceCount(
        File(loggerPath).readAsStringSync(),
        'implements AppLogger',
      ),
      1,
    );
    expect(
      occurrenceCount(
        File(developerLoggerPath).readAsStringSync(),
        'implements AppLogger',
      ),
      1,
    );

    for (final file in implementationFiles) {
      final executableLogger = withoutLineComments(file.readAsStringSync());
      expect(
        executableLogger,
        isNot(matches(RegExp(r'void\s+log\([^)]*\)\s+async\b'))),
      );
      for (final fragment in [
        'Future<',
        'Timer(',
        'Timer.',
        'scheduleMicrotask',
        'unawaited(',
        '.then(',
        'AppErrorBoundary',
        'AppErrorReporter',
        'FlutterError',
        'PlatformDispatcher',
      ]) {
        expect(executableLogger, isNot(contains(fragment)));
      }
    }
  });

  test('production record vocabulary is exact, final, and immutable', () {
    final diagnosticsSources = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.readAsStringSync()).join('\n');
    final recordSources = recordPaths
        .map((path) => File(path).readAsStringSync())
        .join('\n');
    final discoveredClasses = RegExp(
      r'\b(?:abstract\s+)?(?:base\s+|final\s+|interface\s+|sealed\s+)?'
      r'class\s+([A-Za-z][A-Za-z0-9_]*)\s+extends\s+AppLogRecord\b',
    ).allMatches(diagnosticsSources).map((match) => match.group(1)).toList();
    final expectedClasses = _recordExpectations
        .map((expectation) => expectation.className)
        .toList();

    expect(discoveredClasses, unorderedEquals(expectedClasses));
    expect(
      occurrenceCount(
        recordSources,
        'static final AppLogRecordDescriptor recordDescriptor',
      ),
      _recordExpectations.length,
    );
    expect(
      occurrenceCount(
        recordSources,
        'AppLogRecordDescriptor get descriptor => recordDescriptor;',
      ),
      _recordExpectations.length,
    );
    expect(recordSources, isNot(contains('implements AppLogRecord')));
    expect(recordSources, isNot(contains('operator ==')));
    expect(recordSources, isNot(contains('get hashCode')));
    expect(recordSources, isNot(contains('toString()')));
    expect(recordSources, isNot(contains('factory App')));
    for (final fragment in [
      'Map<',
      'List<',
      'StackTrace',
      'Object error',
      'String message',
      'String eventName',
      'AppLogSeverity severity',
    ]) {
      expect(recordSources, isNot(contains(fragment)));
    }

    for (final expectation in _recordExpectations) {
      final classSource = recordClassSource(
        recordSources,
        expectation.className,
      );
      final normalizedClass = normalizeSource(classSource);

      expect(
        classSource,
        startsWith(
          'final class ${expectation.className} extends AppLogRecord {',
        ),
      );
      expect(normalizedClass, contains(expectation.constructor));
      expect(occurrenceCount(normalizedClass, expectation.constructor), 1);
      expect(constructorCount(classSource, expectation.className), 1);
      expect(
        instanceFinalFields(classSource),
        _recordFields[expectation.className],
      );
      expect(hasMutableInstanceField(classSource), isFalse);
      expect(
        normalizedClass,
        contains("eventName: '${expectation.eventName}'"),
      );
      expect(normalizedClass, contains('eventVersion: 1'));
      expect(
        normalizedClass,
        contains('severity: AppLogSeverity.${expectation.severity}'),
      );
      expect(
        normalizedClass,
        contains('dataClass: AppLogDataClass.${expectation.dataClass}'),
      );
      expect(
        normalizedClass,
        contains(
          'static final AppLogRecordDescriptor recordDescriptor = '
          'AppLogRecordDescriptor(',
        ),
      );
      for (final projectionFragment in expectation.projectionFragments) {
        expect(normalizedClass, contains(projectionFragment));
      }
    }

    final eventNames = RegExp(
      r"eventName:\s*'([^']+)'",
    ).allMatches(recordSources).map((match) => match.group(1)).toList();
    expect(
      eventNames,
      unorderedEquals(
        _recordExpectations.map((expectation) => expectation.eventName),
      ),
    );
    expect(eventNames.toSet().length, eventNames.length);
  });

  test('record-shape guard distinguishes mutable fields from getters', () {
    expect(hasMutableInstanceField('class R {\n  Type value;\n}'), isTrue);
    expect(
      hasMutableInstanceField('class R {\n  var value = false;\n}'),
      isTrue,
    );
    expect(
      hasMutableInstanceField('class R {\n  Type get value => String;\n}'),
      isFalse,
    );
  });

  test('record projection stays synchronous, contained, and single-pass', () {
    final recordFiles = recordPaths.map(File.new).toList();
    final recordSources = recordFiles
        .map((file) => file.readAsStringSync())
        .join('\n');
    final executableRecordSources = withoutLineComments(recordSources);

    for (final fragment in [
      ' async',
      'Future<',
      'Timer(',
      'Timer.',
      'scheduleMicrotask',
      'unawaited(',
      '.then(',
      'dart:developer',
      'dart:io',
      'AppLogger',
      '/error_reporting/',
      '_reporter.',
      '.report(',
      'Zone.',
      'FlutterError',
      'PlatformDispatcher',
    ]) {
      expect(executableRecordSources, isNot(contains(fragment)));
    }
    for (final file in recordFiles) {
      expect(
        sourceImports(file.readAsStringSync()),
        [
          'package:template/app/diagnostics/logging/app_log_record.dart',
        ],
      );
    }
    expect(
      occurrenceCount(
        recordSources,
        'return AppLogProjectionResult.complete;',
      ),
      _recordExpectations.length,
    );

    final projectCallers = sortedDartFiles(diagnosticsRoot)
        .where((file) => file.readAsStringSync().contains('record.project('))
        .map((file) => file.path)
        .toList();
    final writerImplementations = sortedDartFiles(diagnosticsRoot)
        .where(
          (file) =>
              file.readAsStringSync().contains('implements AppLogFieldWriter'),
        )
        .map((file) => file.path)
        .toList();

    expect(projectCallers, [developerLoggerPath]);
    expect(writerImplementations, [developerLoggerPath]);
    final developerLogger = File(developerLoggerPath).readAsStringSync();
    expect(occurrenceCount(developerLogger, 'record.project('), 1);
    expect(
      developerLogger.indexOf('record.project('),
      lessThan(developerLogger.indexOf('.seal(')),
    );
    expect(developerLogger, contains('finally {'));
  });

  test('debug details are clamped and support fields stay typed', () {
    final diagnosticsSources = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.readAsStringSync()).join('\n');
    final developerLogger = File(developerLoggerPath).readAsStringSync();
    final blocRecords = File(blocRecordsPath).readAsStringSync();
    final errorRecords = File(errorRecordsPath).readAsStringSync();

    expect(diagnosticsSources, isNot(contains('kReleaseMode')));
    expect(
      developerLogger,
      contains('_includeDebugRecords = kDebugMode && includeDebugRecords;'),
    );
    expect(
      developerLogger.indexOf(
        'descriptor.dataClass == AppLogDataClass.debugOnly',
      ),
      lessThan(developerLogger.indexOf('record.project(')),
    );
    for (final fragment in [
      'supportCode(',
      'supportFlag(',
      'supportCount(',
      'supportDuration(',
    ]) {
      expect(blocRecords, isNot(contains(fragment)));
    }
    expect(errorRecords, isNot(contains('debugType(')));
    expect(errorRecords, isNot(contains('String ')));
    expect(errorRecords, isNot(contains('Object ')));
    expect(errorRecords, isNot(contains('Map<')));
    expect(errorRecords, isNot(contains('List<')));
  });

  test('developer output owns projection and receives no raw failure data', () {
    const reporterPath =
        'lib/app/diagnostics/error_reporting/app_error_reporter.dart';
    final developerImporters = sortedDartFiles('lib')
        .where((file) => file.readAsStringSync().contains("'dart:developer'"))
        .map((file) => file.path)
        .toList();
    final developerLogger = File(developerLoggerPath).readAsStringSync();
    final reporter = File(reporterPath).readAsStringSync();
    final diagnosticsSources = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(
      developerImporters,
      [reporterPath, developerLoggerPath]..sort(),
    );
    expect(occurrenceCount(developerLogger, 'developer.log('), 1);
    expect(occurrenceCount(reporter, 'developer.log('), 1);
    expect(
      developerLogger,
      contains("developer.log(message, name: 'Application', level: level);"),
    );
    for (final fragment in [
      'FlutterError.presentError(',
      '.exceptionAsString(',
      'informationCollector(',
      'debugPrint(',
      'print(',
    ]) {
      expect(diagnosticsSources, isNot(contains(fragment)));
    }
  });

  test('BLoC observation is debug-only logging without error reporting', () {
    final observer = File(observerPath).readAsStringSync();

    expect(observer, contains('extends BlocObserver'));
    expect(observer, contains('with EphemeralBlocObserver'));
    expect(observer, contains('required AppLogger logger'));
    expect(observer, contains('_logger.log(record)'));
    expect(observer, isNot(contains('AppErrorReporter')));
    expect(observer, isNot(contains('/error_reporting/')));
    expect(observer, isNot(contains('developer_app_logger.dart')));
    for (final callback in [
      'void onCreate(',
      'void onEvent(',
      'void onChange(',
      'void onAction(',
      'void onError(',
      'void onClose(',
    ]) {
      expect(observer, contains(callback));
    }
    expect(observer, isNot(contains('void onTransition(')));
    expect(occurrenceCount(observer, 'if (kDebugMode)'), 6);
  });
}

const _recordExpectations = [
  _RecordExpectation(
    'AppBlocCreatedLogRecord',
    'const AppBlocCreatedLogRecord(this.componentType);',
    'app.bloc.created',
    'info',
    'debugOnly',
    ["fields.debugType('component_type', componentType);"],
  ),
  _RecordExpectation(
    'AppBlocEventLogRecord',
    'const AppBlocEventLogRecord(this.componentType, this.eventType);',
    'app.bloc.event',
    'info',
    'debugOnly',
    [
      "..debugType('component_type', componentType)",
      "..debugType('event_type', eventType);",
    ],
  ),
  _RecordExpectation(
    'AppBlocStateChangedLogRecord',
    'const AppBlocStateChangedLogRecord( this.componentType, this.previousStateType, this.nextStateType, );',
    'app.bloc.state_changed',
    'info',
    'debugOnly',
    [
      "..debugType('component_type', componentType)",
      "..debugType('previous_state_type', previousStateType)",
      "..debugType('next_state_type', nextStateType);",
    ],
  ),
  _RecordExpectation(
    'AppBlocActionLogRecord',
    'const AppBlocActionLogRecord(this.componentType, this.actionType);',
    'app.bloc.action',
    'info',
    'debugOnly',
    [
      "..debugType('component_type', componentType)",
      "..debugType('action_type', actionType);",
    ],
  ),
  _RecordExpectation(
    'AppBlocErrorBreadcrumbLogRecord',
    'const AppBlocErrorBreadcrumbLogRecord(this.componentType, this.errorType);',
    'app.bloc.error_breadcrumb',
    'warning',
    'debugOnly',
    [
      "..debugType('component_type', componentType)",
      "..debugType('error_type', errorType);",
    ],
  ),
  _RecordExpectation(
    'AppBlocClosedLogRecord',
    'const AppBlocClosedLogRecord(this.componentType);',
    'app.bloc.closed',
    'info',
    'debugOnly',
    ["fields.debugType('component_type', componentType);"],
  ),
  _RecordExpectation(
    'AppErrorReportedLogRecord',
    'const AppErrorReportedLogRecord(this.reportCode);',
    'app.diagnostics.error_reported',
    'error',
    'supportSafe',
    ["fields.supportCode('report_code', reportCode);"],
  ),
  _RecordExpectation(
    'AppErrorReporterFailureLogRecord',
    'const AppErrorReporterFailureLogRecord();',
    'app.diagnostics.reporter_failed',
    'error',
    'supportSafe',
    ["fields.supportCode('support_code', _supportCode);"],
  ),
  _RecordExpectation(
    'AppStartupStartedLogRecord',
    'const AppStartupStartedLogRecord();',
    'app.startup.started',
    'info',
    'supportSafe',
    [],
  ),
  _RecordExpectation(
    'AppStartupCompletedLogRecord',
    'AppStartupCompletedLogRecord(this.duration)',
    'app.startup.completed',
    'info',
    'supportSafe',
    ["fields.supportDuration('duration', duration);"],
  ),
];

const _recordFields = <String, List<String>>{
  'AppBlocCreatedLogRecord': ['final Type componentType;'],
  'AppBlocEventLogRecord': [
    'final Type componentType;',
    'final Type eventType;',
  ],
  'AppBlocStateChangedLogRecord': [
    'final Type componentType;',
    'final Type previousStateType;',
    'final Type nextStateType;',
  ],
  'AppBlocActionLogRecord': [
    'final Type componentType;',
    'final Type actionType;',
  ],
  'AppBlocErrorBreadcrumbLogRecord': [
    'final Type componentType;',
    'final Type errorType;',
  ],
  'AppBlocClosedLogRecord': ['final Type componentType;'],
  'AppErrorReportedLogRecord': ['final AppLogStableCode reportCode;'],
  'AppErrorReporterFailureLogRecord': [],
  'AppStartupStartedLogRecord': [],
  'AppStartupCompletedLogRecord': ['final Duration duration;'],
};

final class _RecordExpectation {
  const _RecordExpectation(
    this.className,
    this.constructor,
    this.eventName,
    this.severity,
    this.dataClass,
    this.projectionFragments,
  );

  final String className;
  final String constructor;
  final String eventName;
  final String severity;
  final String dataClass;
  final List<String> projectionFragments;
}
