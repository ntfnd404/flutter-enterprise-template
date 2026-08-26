import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_resource_disposal_exception.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/logging/records/app_error_log_records.dart';
import 'package:template/app/diagnostics/logging/records/app_startup_log_records.dart';
import 'package:template/app/startup/run_application.dart';

import 'support/run_application_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'environment failure preserves identity and mounts safe fallback',
    (
      tester,
    ) async {
      final originalObserver = Bloc.observer;
      final logger = StartupTestLogger();
      final reporter = StartupTestReporter();
      final boundaryCapture = StartupBoundaryCapture();
      const error = _HostileStartupError('never-render-this-secret');
      final stackTrace = StackTrace.current;
      var graphCalled = false;

      try {
        runApplication(
          logger: logger,
          errorReporter: reporter,
          errorBoundaryFactory: boundaryCapture.create,
          configurationLoader: () =>
              Error.throwWithStackTrace(error, stackTrace),
          dependenciesFactory: (_) async {
            graphCalled = true;

            return testAppDependencies();
          },
        );

        await reporter.waitForCount(1);
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('startup-failure-marker')),
        );

        final report = reporter.reports.single;
        expect(identical(report.error, error), isTrue);
        expect(identical(report.stackTrace, stackTrace), isTrue);
        expect(report.kind, AppErrorReportKind.environment);
        expect(graphCalled, isFalse);
        expect(find.text('APP-ENVIRONMENT-001'), findsOneWidget);
        expect(find.textContaining('never-render-this-secret'), findsNothing);
        expect(
          logger.records.whereType<AppStartupStartedLogRecord>(),
          hasLength(1),
        );
        expect(
          logger.records.whereType<AppStartupCompletedLogRecord>(),
          isEmpty,
        );
        expect(
          logger.records.whereType<AppErrorReportedLogRecord>(),
          hasLength(1),
        );
      } finally {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          restoreStartupGlobals(
            observer: originalObserver,
            boundaryCapture: boundaryCapture,
          );
        }
      }
    },
  );

  testWidgets('framework failure does not build the graph', (tester) async {
    final originalObserver = Bloc.observer;
    final logger = StartupTestLogger();
    final reporter = StartupTestReporter();
    final boundaryCapture = StartupBoundaryCapture();
    final error = StateError('private framework detail');
    final stackTrace = StackTrace.current;
    var graphCalled = false;

    try {
      runApplication(
        logger: logger,
        errorReporter: reporter,
        errorBoundaryFactory: boundaryCapture.create,
        configurationLoader: validStartupConfiguration,
        frameworkInitializer: ({required environment, required logger}) =>
            Future.error(error, stackTrace),
        dependenciesFactory: (_) async {
          graphCalled = true;

          return testAppDependencies();
        },
      );

      await reporter.waitForCount(1);
      await pumpUntilFound(tester, find.text('APP-STARTUP-001'));

      final report = reporter.reports.single;
      expect(identical(report.error, error), isTrue);
      expect(identical(report.stackTrace, stackTrace), isTrue);
      expect(report.kind, AppErrorReportKind.startup);
      expect(graphCalled, isFalse);
      expect(logger.records.whereType<AppStartupCompletedLogRecord>(), isEmpty);
    } finally {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        restoreStartupGlobals(
          observer: originalObserver,
          boundaryCapture: boundaryCapture,
        );
      }
    }
  });

  testWidgets(
    'reports primary before rollback and reporter failure cannot block fallback',
    (tester) async {
      final originalObserver = Bloc.observer;
      final logger = StartupTestLogger();
      late final StartupTestReporter reporter;
      reporter = StartupTestReporter(
        onReport: (_) => Future.error(StateError('reporter failed')),
      );
      final boundaryCapture = StartupBoundaryCapture();
      final primary = StateError('private graph detail');
      final primaryStack = StackTrace.current;
      final cleanup = StateError('private cleanup detail');
      var cleanupRan = false;

      try {
        runApplication(
          logger: logger,
          errorReporter: reporter,
          errorBoundaryFactory: boundaryCapture.create,
          configurationLoader: validStartupConfiguration,
          frameworkInitializer: ({required environment, required logger}) =>
              Future.value(),
          dependenciesFactory: (resources) {
            resources.register(Object(), (_) {
              cleanupRan = true;
              throw cleanup;
            });

            return Future<Never>.error(primary, primaryStack);
          },
        );

        await reporter.waitForCount(2);
        await pumpUntilFound(tester, find.text('APP-STARTUP-001'));

        expect(cleanupRan, isTrue);
        expect(
          reporter.reports.map((report) => report.kind),
          [
            AppErrorReportKind.startup,
            AppErrorReportKind.dependencyRollback,
          ],
        );
        expect(identical(reporter.reports.first.error, primary), isTrue);
        expect(
          identical(reporter.reports.first.stackTrace, primaryStack),
          isTrue,
        );
        expect(
          reporter.reports.last.error,
          isA<AppResourceDisposalException>(),
        );
        expect(
          logger.records.whereType<AppErrorReporterFailureLogRecord>(),
          hasLength(2),
        );
        expect(
          logger.records.whereType<AppStartupCompletedLogRecord>(),
          isEmpty,
        );
      } finally {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          restoreStartupGlobals(
            observer: originalObserver,
            boundaryCapture: boundaryCapture,
          );
        }
      }
    },
  );
}

final class _HostileStartupError implements Exception {
  const _HostileStartupError(this.secret);

  final String secret;

  @override
  String toString() => throw StateError('Hostile error must not be rendered.');
}
