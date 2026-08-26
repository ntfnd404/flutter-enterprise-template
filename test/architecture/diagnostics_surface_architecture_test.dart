import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/diagnostics_source_guard.dart';

void main() {
  const diagnosticsRoot = 'lib/app/diagnostics';
  const loggingRoot = '$diagnosticsRoot/logging';
  const errorReportingRoot = '$diagnosticsRoot/error_reporting';
  const developerLoggerPath = '$loggingRoot/developer_app_logger.dart';
  const expectedFiles = [
    '$errorReportingRoot/app_error_boundary.dart',
    '$errorReportingRoot/app_error_formatter.dart',
    '$errorReportingRoot/app_error_report_kind.dart',
    '$errorReportingRoot/app_error_reporter.dart',
    '$loggingRoot/app_bloc_observer.dart',
    '$loggingRoot/app_log_record.dart',
    '$loggingRoot/app_logger.dart',
    developerLoggerPath,
    '$loggingRoot/records/app_bloc_log_records.dart',
    '$loggingRoot/records/app_error_log_records.dart',
    '$loggingRoot/records/app_startup_log_records.dart',
  ];

  test('the isolated tree has the exact accepted Core Diagnostics surface', () {
    final actualFiles = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.path).toList();
    final sortedExpected = expectedFiles.toList()..sort();

    expect(actualFiles, sortedExpected);
    expect(Directory('lib/core/diagnostics').existsSync(), isFalse);
    expect(Directory('lib/core/bloc').existsSync(), isFalse);
    expect(Directory('$loggingRoot/adapters').existsSync(), isFalse);
    expect(Directory('$loggingRoot/support_log').existsSync(), isFalse);
  });

  test('logging and error reporting remain separate sibling capabilities', () {
    final loggingFiles = sortedDartFiles(loggingRoot);
    final errorReportingFiles = sortedDartFiles(errorReportingRoot);

    expect(
      filesContaining(loggingFiles, '/error_reporting/'),
      isEmpty,
      reason: 'Operational logging must not depend on raw error reporting.',
    );
    expect(
      filesContaining(errorReportingFiles, '/logging/'),
      [
        '$errorReportingRoot/app_error_boundary.dart',
        '$errorReportingRoot/app_error_report_kind.dart',
      ],
      reason: 'Only the boundary and report-kind mapping use safe records.',
    );

    const forbiddenDependencies = [
      'package:app_database/',
      'package:catalog/',
      'package:ordering/',
      'package:template/app/di/',
      'package:template/app/environment/',
      'package:template/app/events/',
      'package:template/app/routing/',
      'package:template/app/startup/',
      'package:template/core/event_bus/',
      'package:template/feature/',
    ];
    final dependencyOffenders = sortedDartFiles(diagnosticsRoot)
        .where((file) {
          final source = file.readAsStringSync();

          return forbiddenDependencies.any(source.contains);
        })
        .map((file) => file.path)
        .toList();
    final relativeImportOffenders = sortedDartFiles(diagnosticsRoot)
        .where((file) {
          final source = file.readAsStringSync();

          return RegExp(
            r"^import\s+'\.\.?/",
            multiLine: true,
          ).hasMatch(source);
        })
        .map((file) => file.path)
        .toList();

    expect(dependencyOffenders, isEmpty);
    expect(relativeImportOffenders, isEmpty);
  });

  test('the logger port does not hide the concrete developer logger', () {
    const loggerPath = '$loggingRoot/app_logger.dart';
    final logger = File(loggerPath).readAsStringSync();
    final developerLogger = File(developerLoggerPath).readAsStringSync();

    expect(
      sourceImports(logger),
      [
        'package:template/app/diagnostics/logging/app_log_record.dart',
      ],
    );
    expect(logger, isNot(contains('dart:developer')));
    expect(logger, isNot(contains('package:flutter/')));
    expect(logger, isNot(contains('developer_app_logger.dart')));
    expect(logger, isNot(contains('export ')));
    expect(logger, isNot(contains('DeveloperAppLogger')));
    expect(developerLogger, contains('final class DeveloperAppLogger'));

    final developerDefinitions = sortedDartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains(
            'final class DeveloperAppLogger',
          ),
        )
        .map((file) => file.path)
        .toList();
    expect(developerDefinitions, [developerLoggerPath]);
  });

  test('future capabilities and dependencies have not entered runtime', () {
    const forbiddenFragments = [
      'AppLoggingModule',
      'AppSupportLogExporter',
      'AppSupportLogSnapshot',
      'AppLogPersistenceMode',
      'RemoteAppErrorReporter',
      'AppErrorReporterRegistry',
      'AnalyticsEvent',
      'firebase_analytics',
      'firebase_crashlytics',
      'package:sentry',
      'idb_shim',
    ];
    final diagnosticsSources = sortedDartFiles(
      diagnosticsRoot,
    ).map((file) => file.readAsStringSync()).join('\n');
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lockfile = File('pubspec.lock').readAsStringSync();

    for (final fragment in forbiddenFragments) {
      expect(diagnosticsSources, isNot(contains(fragment)));
      expect(pubspec, isNot(contains(fragment)));
      expect(lockfile, isNot(contains(fragment)));
    }

    final dependencies = File(
      'lib/app/di/app_dependencies.dart',
    ).readAsStringSync();
    for (final symbol in [
      'AppLogger',
      'AppErrorReporter',
      'AppErrorBoundary',
      'AppLoggingModule',
      'AppSupportLogExporter',
    ]) {
      expect(dependencies, isNot(contains(symbol)));
    }

    final externalImporters =
        [
              ...sortedDartFiles('lib'),
              ...sortedDartFiles('packages'),
            ]
            .where((file) => !file.path.startsWith('$diagnosticsRoot/'))
            .where(
              (file) => file.readAsStringSync().contains(
                'package:template/app/diagnostics/',
              ),
            )
            .map((file) => file.path)
            .toList();

    expect(externalImporters, [
      'lib/app/startup/initialize_app_framework.dart',
      'lib/app/startup/run_application.dart',
    ]);
  });

  test('Diagnostics dependencies stay pinned to reviewed contracts', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('flutter_bloc: 9.1.1'));
    expect(pubspec, contains('ephemeral_bloc: 0.1.0'));
    expect(pubspec, isNot(contains('github.com/ntfnd404/ephemeral_bloc')));
    expect(pubspec, isNot(contains('idb_shim:')));
  });
}
