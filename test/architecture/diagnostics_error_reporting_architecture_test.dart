import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/diagnostics_source_guard.dart';

void main() {
  const diagnosticsRoot = 'lib/app/diagnostics';
  const loggingRoot = '$diagnosticsRoot/logging';
  const errorReportingRoot = '$diagnosticsRoot/error_reporting';
  const loggerPath = '$loggingRoot/app_logger.dart';
  const boundaryPath = '$errorReportingRoot/app_error_boundary.dart';
  const formatterPath = '$errorReportingRoot/app_error_formatter.dart';
  const reportKindPath = '$errorReportingRoot/app_error_report_kind.dart';
  const reporterPath = '$errorReportingRoot/app_error_reporter.dart';

  test('error-reporting contracts stay strict and lifecycle-free', () {
    final reporter = File(reporterPath).readAsStringSync();
    final boundary = File(boundaryPath).readAsStringSync();
    final normalizedReporter = normalizeSource(reporter);
    final normalizedBoundary = normalizeSource(boundary);

    expect(reporter, contains('abstract interface class AppErrorReporter'));
    expect(
      normalizedReporter,
      contains(
        'abstract interface class AppErrorReporter { '
        'Future<void> report( Object error, StackTrace? stackTrace, { '
        'required AppErrorReportKind kind, }); }',
      ),
    );
    expect(reporter, isNot(contains('FutureOr<void> report(')));
    expect(reporter, isNot(contains('void report(')));
    expect(
      normalizedBoundary,
      contains('void run(Future<void> Function() body)'),
    );
    expect(
      normalizedBoundary,
      contains('bool reportSilentFlutterErrors = kDebugMode'),
    );
    expect(
      normalizedBoundary,
      contains(
        'Future<void> report( Object error, StackTrace? stackTrace, { '
        'required AppErrorReportKind kind, }) async',
      ),
    );
    expect(normalizedBoundary, contains('void dispose()'));
    expect(boundary, isNot(contains('_reporter.dispose(')));
    expect(boundary, isNot(contains('_logger.dispose(')));
  });

  test('the boundary exclusively owns global raw-failure routing', () {
    final handlerWriters = sortedDartFiles('lib')
        .where((file) {
          final source = file.readAsStringSync();

          return source.contains('FlutterError.onError =') ||
              source.contains('PlatformDispatcher.instance.onError =');
        })
        .map((file) => file.path)
        .toList();
    final boundary = File(boundaryPath).readAsStringSync();
    final normalizedBoundary = normalizeSource(boundary);

    expect(handlerWriters, <String>[boundaryPath]);
    expect(boundary, contains('runZonedGuarded<void>('));
    expect(boundary, contains('unawaited(body());'));
    expect(boundary, contains('details.stack,'));
    expect(boundary, isNot(contains('StackTrace.current')));
    expect(boundary, isNot(contains('_previousFlutterHandler(')));
    expect(boundary, isNot(contains('_previousPlatformHandler(')));
    expect(boundary, contains('return true;'));
    expect(
      normalizedBoundary,
      contains(
        'Future<void> report( Object error, StackTrace? stackTrace, { '
        'required AppErrorReportKind kind, }) async',
      ),
    );
    expect(boundary, contains('final _loggerZoneMarkerKey = Object();'));
    expect(boundary, contains('final _reporterZoneMarkerKey = Object();'));
    expect(
      boundary.indexOf('Zone.current[_loggerZoneMarkerKey]'),
      lessThan(
        boundary.indexOf('identical(inheritedInvocation?.boundary, this)'),
      ),
    );
    expect(
      boundary.indexOf('identical(inheritedInvocation?.boundary, this)'),
      lessThan(boundary.indexOf('AppErrorReportedLogRecord(kind.supportCode)')),
    );
    expect(
      boundary.indexOf('AppErrorReportedLogRecord(kind.supportCode)'),
      lessThan(boundary.indexOf('_reporter.report(')),
    );
    expect(boundary, contains('const AppErrorReporterFailureLogRecord()'));
    expect(boundary, contains('_reporterZoneMarkerKey: invocation'));
    final safeLogStart = boundary.indexOf('void _safeLog(');
    final safeLogEnd = boundary.indexOf(
      'void _restoreFlutterHandlerIfOwned()',
      safeLogStart,
    );
    final safeLogSource = boundary.substring(safeLogStart, safeLogEnd);
    expect(safeLogSource, contains('runZonedGuarded<void>('));
    expect(safeLogSource, contains('_logger.log(createRecord())'));
    expect(safeLogSource, contains('_loggerZoneMarkerKey: this'));
    expect(safeLogSource, isNot(contains('_reporter')));
    expect(safeLogSource, isNot(contains('AppErrorReporterFailureLogRecord')));
  });

  test('formatter clamps details before touching raw failure data', () {
    final formatter = File(formatterPath).readAsStringSync();
    final diagnosticsSources = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(diagnosticsSources, isNot(contains('kReleaseMode')));
    expect(
      formatter,
      contains(
        'if (!kDebugMode || detail == AppDiagnosticDetail.supportOnly)',
      ),
    );
    expect(
      formatter.indexOf(
        'if (!kDebugMode || detail == AppDiagnosticDetail.supportOnly)',
      ),
      lessThan(formatter.indexOf('error.runtimeType')),
    );
  });

  test('report kinds and stable identifiers are exact and non-overloaded', () {
    final reportKind = File(reportKindPath).readAsStringSync();
    final formatter = File(formatterPath).readAsStringSync();
    final diagnosticsSources = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.readAsStringSync()).join('\n');

    for (final expectation in _reportKindExpectations) {
      expect(
        reportKind,
        matches(
          RegExp(
            '${expectation.enumValue}\\(\\s*'
            "'${expectation.wireValue}'\\s*,\\s*"
            "'${expectation.code}'\\s*,\\s*"
            "'${expectation.label}'\\s*,?\\s*\\)",
          ),
        ),
      );
    }
    final kindCodes = RegExp(
      r"'(APP-[A-Z0-9-]+-001)'",
    ).allMatches(reportKind).map((match) => match.group(1)).toList();

    expect(
      kindCodes,
      unorderedEquals(
        _reportKindExpectations.map((expectation) => expectation.code),
      ),
    );
    expect(kindCodes.toSet().length, _reportKindExpectations.length);
    expect(reportKind, contains('AppLogStableCode get supportCode'));
    expect(reportKind, isNot(contains('AppLogSeverity')));
    expect(formatter, isNot(contains('APP-')));
    expect(diagnosticsSources, contains("'APP-REPORT-001'"));
    expect(diagnosticsSources, isNot(contains('APP-HANDLER-001')));
  });

  test('boundary depends on the logger port, never its implementation', () {
    final boundary = File(boundaryPath).readAsStringSync();

    expect(
      sourceImports(boundary),
      contains(
        'package:template/app/diagnostics/logging/app_logger.dart',
      ),
    );
    expect(boundary, isNot(contains('developer_app_logger.dart')));
    expect(
      File(loggerPath).readAsStringSync(),
      isNot(contains('/error_reporting/')),
    );
  });
}

const _reportKindExpectations = <_ReportKindExpectation>[
  _ReportKindExpectation('rootZone', 'root_zone', 'APP-ROOT-001', 'Root zone'),
  _ReportKindExpectation(
    'environment',
    'environment',
    'APP-ENVIRONMENT-001',
    'Environment',
  ),
  _ReportKindExpectation('startup', 'startup', 'APP-STARTUP-001', 'Startup'),
  _ReportKindExpectation(
    'flutterFramework',
    'flutter_framework',
    'APP-FRAMEWORK-001',
    'Flutter framework',
  ),
  _ReportKindExpectation(
    'platformDispatcher',
    'platform_dispatcher',
    'APP-PLATFORM-001',
    'Platform dispatcher',
  ),
  _ReportKindExpectation(
    'dependencyRollback',
    'dependency_rollback',
    'APP-DI-ROLLBACK-001',
    'Dependency rollback',
  ),
  _ReportKindExpectation(
    'dependencyDisposal',
    'dependency_disposal',
    'APP-DI-DISPOSE-001',
    'Dependency disposal',
  ),
];

final class _ReportKindExpectation {
  const _ReportKindExpectation(
    this.enumValue,
    this.wireValue,
    this.code,
    this.label,
  );

  final String enumValue;
  final String wireValue;
  final String code;
  final String label;
}
