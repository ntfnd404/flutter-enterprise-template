import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_formatter.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/developer_app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_error_log_records.dart';

import 'support/app_error_boundary_test_support.dart';

void main() {
  group('report', () {
    test('preserves the original error, nullable stack, and kind', () async {
      final reporter = TestRecordingAppErrorReporter();
      final logger = TestRecordingAppLogger();
      final boundary = createTestErrorBoundary(
        reporter: reporter,
        logger: logger,
      );
      addTearDown(boundary.dispose);
      final withoutStack = StateError('without stack');
      final withStack = StateError('with stack');
      final stackTrace = StackTrace.fromString('original stack');

      await boundary.report(
        withoutStack,
        null,
        kind: AppErrorReportKind.flutterFramework,
      );
      await boundary.report(
        withStack,
        stackTrace,
        kind: AppErrorReportKind.startup,
      );

      expect(reporter.records, hasLength(2));
      expect(reporter.records.first.error, same(withoutStack));
      expect(reporter.records.first.stackTrace, isNull);
      expect(
        reporter.records.first.kind,
        AppErrorReportKind.flutterFramework,
      );
      expect(reporter.records.last.error, same(withStack));
      expect(reporter.records.last.stackTrace, same(stackTrace));
      expect(reporter.records.last.kind, AppErrorReportKind.startup);
      final reportedRecords = logger.records
          .whereType<AppErrorReportedLogRecord>()
          .toList();
      expect(reportedRecords, hasLength(2));
      expect(
        reportedRecords.map((record) => record.reportCode.value),
        ['APP-FRAMEWORK-001', 'APP-STARTUP-001'],
      );
    });

    test('logs the support-safe occurrence before raw reporting', () async {
      final calls = <String>[];
      final boundary = createTestErrorBoundary(
        logger: TestCallbackAppLogger(
          (record) => calls.add('log:${record.descriptor.eventName}'),
        ),
        reporter: TestCallbackAppErrorReporter((_, _, _) async {
          calls.add('report');
        }),
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );

      expect(calls, [
        'log:app.diagnostics.error_reported',
        'report',
      ]);
    });

    test('composes the built-in local logger and reporter in order', () async {
      final calls = <String>[];
      final boundary = createTestErrorBoundary(
        logger: DeveloperAppLogger.withSink(
          sink: (message, level) => calls.add('log:$level:$message'),
        ),
        reporter: LocalAppErrorReporter.withSink(
          formatter: const AppErrorFormatter(
            AppDiagnosticDetail.supportOnly,
          ),
          sink: (message) => calls.add('report:$message'),
        ),
      );
      addTearDown(boundary.dispose);
      final stackTrace = StackTrace.fromString('sensitive stack');

      await boundary.report(
        StateError('sensitive error'),
        stackTrace,
        kind: AppErrorReportKind.startup,
      );

      expect(calls, <String>[
        <String>[
          'log:1000:app.diagnostics.error_reported event_version=1 ',
          'severity=error report_code=APP-STARTUP-001',
        ].join(),
        'report:APP-STARTUP-001 Startup',
      ]);
      expect(calls.join(' '), isNot(contains('sensitive error')));
      expect(calls.join(' '), isNot(contains('sensitive stack')));
    });

    test('does not let a logger failure suppress the raw reporter', () async {
      var reporterCalls = 0;
      final boundary = createTestErrorBoundary(
        logger: TestCallbackAppLogger((_) => throw StateError('broken logger')),
        reporter: TestCallbackAppErrorReporter((_, _, _) async {
          reporterCalls += 1;
        }),
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.rootZone,
      );

      expect(reporterCalls, 1);
    });

    test('contains synchronous reporter failure and logs it once', () async {
      final failure = StateError('broken reporter');
      final logger = TestRecordingAppLogger();
      final boundary = createTestErrorBoundary(
        reporter: TestCallbackAppErrorReporter((_, _, _) => throw failure),
        logger: logger,
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );

      expect(
        logger.records.map((record) => record.descriptor.eventName),
        [
          'app.diagnostics.error_reported',
          'app.diagnostics.reporter_failed',
        ],
      );
    });

    test('contains asynchronous reporter failure and logs it once', () async {
      final failure = StateError('broken async reporter');
      final failureStack = StackTrace.fromString('reporter stack');
      final logger = TestRecordingAppLogger();
      final boundary = createTestErrorBoundary(
        reporter: TestCallbackAppErrorReporter(
          (_, _, _) => Future<void>.error(failure, failureStack),
        ),
        logger: logger,
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );

      expect(
        logger.records.map((record) => record.descriptor.eventName),
        [
          'app.diagnostics.error_reported',
          'app.diagnostics.reporter_failed',
        ],
      );
    });

    test('suppresses a logger failure after reporter failure', () async {
      final boundary = createTestErrorBoundary(
        reporter: TestCallbackAppErrorReporter(
          (_, _, _) => throw StateError('broken reporter'),
        ),
        logger: TestCallbackAppLogger(
          (_) => throw StateError('broken fallback logger'),
        ),
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );
    });

    test('allows independent reports to run concurrently', () async {
      var calls = 0;
      final bothEntered = Completer<void>();
      final release = Completer<void>();
      final boundary = createTestErrorBoundary(
        reporter: TestCallbackAppErrorReporter((_, _, _) async {
          calls += 1;
          if (calls == 2) {
            bothEntered.complete();
          }
          await release.future;
        }),
      );
      addTearDown(boundary.dispose);

      final first = boundary.report(
        StateError('first'),
        StackTrace.current,
        kind: AppErrorReportKind.rootZone,
      );
      final second = boundary.report(
        StateError('second'),
        StackTrace.current,
        kind: AppErrorReportKind.platformDispatcher,
      );
      await bothEntered.future;
      expect(calls, 2);

      release.complete();
      await Future.wait<void>([first, second]);
    });
  });
}
