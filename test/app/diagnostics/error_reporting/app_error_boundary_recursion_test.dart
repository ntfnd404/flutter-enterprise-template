import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';

import 'support/app_error_boundary_test_support.dart';

void main() {
  group('recursion', () {
    test('suppresses direct logger-induced recursion', () async {
      late AppErrorBoundary boundary;
      Future<void>? nestedReport;
      var loggerCalls = 0;
      final reporter = TestRecordingAppErrorReporter();
      boundary = createTestErrorBoundary(
        reporter: reporter,
        logger: TestCallbackAppLogger((_) {
          loggerCalls += 1;
          if (loggerCalls == 1) {
            nestedReport = boundary.report(
              StateError('logger recursion'),
              StackTrace.current,
              kind: AppErrorReportKind.rootZone,
            );
          }
        }),
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );
      await nestedReport;

      expect(loggerCalls, 1);
      expect(reporter.records, hasLength(1));
    });

    test('suppresses inherited-async logger-induced recursion', () async {
      late AppErrorBoundary boundary;
      final nestedCompleted = Completer<void>();
      var loggerCalls = 0;
      final reporter = TestRecordingAppErrorReporter();
      boundary = createTestErrorBoundary(
        reporter: reporter,
        logger: TestCallbackAppLogger((_) {
          loggerCalls += 1;
          if (loggerCalls == 1) {
            unawaited(() async {
              await Future<void>.delayed(Duration.zero);
              await boundary.report(
                StateError('async logger recursion'),
                StackTrace.current,
                kind: AppErrorReportKind.rootZone,
              );
              nestedCompleted.complete();
            }());
          }
        }),
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );
      await nestedCompleted.future;

      expect(loggerCalls, 1);
      expect(reporter.records, hasLength(1));
    });

    test('contains an inherited-async hostile logger failure', () async {
      final failureStarted = Completer<void>();
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(
        reporter: reporter,
        logger: TestCallbackAppLogger((_) {
          unawaited(() async {
            await Future<void>.delayed(Duration.zero);
            failureStarted.complete();
            throw StateError('detached hostile logger failure');
          }());
        }),
      );
      addTearDown(boundary.dispose);

      await boundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );
      await failureStarted.future;
      await Future<void>.delayed(Duration.zero);

      expect(reporter.records, hasLength(1));
    });

    test('bounds a mutually recursive logger chain per boundary', () async {
      late AppErrorBoundary firstBoundary;
      late AppErrorBoundary secondBoundary;
      Future<void>? delegatedReport;
      var firstLoggerCalls = 0;
      var secondLoggerCalls = 0;
      final firstReporter = TestRecordingAppErrorReporter();
      final secondReporter = TestRecordingAppErrorReporter();
      firstBoundary = createTestErrorBoundary(
        reporter: firstReporter,
        logger: TestCallbackAppLogger((_) {
          firstLoggerCalls += 1;
          if (firstLoggerCalls == 1) {
            delegatedReport = secondBoundary.report(
              StateError('delegated to second'),
              StackTrace.current,
              kind: AppErrorReportKind.rootZone,
            );
          }
        }),
      );
      secondBoundary = createTestErrorBoundary(
        reporter: secondReporter,
        logger: TestCallbackAppLogger((_) {
          secondLoggerCalls += 1;
          unawaited(
            firstBoundary.report(
              StateError('delegated back to first'),
              StackTrace.current,
              kind: AppErrorReportKind.rootZone,
            ),
          );
        }),
      );
      addTearDown(firstBoundary.dispose);
      addTearDown(secondBoundary.dispose);

      await firstBoundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );
      await delegatedReport;

      expect(firstLoggerCalls, 1);
      expect(secondLoggerCalls, 1);
      expect(firstReporter.records, hasLength(1));
      expect(secondReporter.records, hasLength(1));
    });

    test(
      'rejects direct reporter recursion without calling it twice',
      () async {
        late AppErrorBoundary boundary;
        var reporterCalls = 0;
        final logger = TestRecordingAppLogger();
        final reporter = TestCallbackAppErrorReporter((_, _, _) async {
          reporterCalls += 1;
          await Future<void>.delayed(Duration.zero);
          await boundary.report(
            StateError('recursive'),
            StackTrace.current,
            kind: AppErrorReportKind.rootZone,
          );
          throw StateError('reporter also failed');
        });
        boundary = createTestErrorBoundary(reporter: reporter, logger: logger);
        addTearDown(boundary.dispose);

        await boundary.report(
          StateError('primary'),
          StackTrace.current,
          kind: AppErrorReportKind.startup,
        );

        expect(reporterCalls, 1);
        expect(
          logger.records.map((record) => record.descriptor.eventName),
          [
            'app.diagnostics.error_reported',
            'app.diagnostics.reporter_failed',
          ],
        );
      },
    );

    test('rejects a mutually recursive reporter chain', () async {
      late AppErrorBoundary firstBoundary;
      late AppErrorBoundary secondBoundary;
      var firstReporterCalls = 0;
      var secondReporterCalls = 0;
      final firstLogger = TestRecordingAppLogger();
      final secondLogger = TestRecordingAppLogger();
      firstBoundary = createTestErrorBoundary(
        reporter: TestCallbackAppErrorReporter((_, _, _) async {
          firstReporterCalls += 1;
          await secondBoundary.report(
            StateError('delegated to second'),
            StackTrace.current,
            kind: AppErrorReportKind.rootZone,
          );
        }),
        logger: firstLogger,
      );
      secondBoundary = createTestErrorBoundary(
        reporter: TestCallbackAppErrorReporter((_, _, _) async {
          secondReporterCalls += 1;
          await firstBoundary.report(
            StateError('delegated back to first'),
            StackTrace.current,
            kind: AppErrorReportKind.rootZone,
          );
        }),
        logger: secondLogger,
      );
      addTearDown(firstBoundary.dispose);
      addTearDown(secondBoundary.dispose);

      await firstBoundary.report(
        StateError('primary'),
        StackTrace.current,
        kind: AppErrorReportKind.startup,
      );

      expect(firstReporterCalls, 1);
      expect(secondReporterCalls, 1);
      expect(
        firstLogger.records.map((record) => record.descriptor.eventName),
        [
          'app.diagnostics.error_reported',
          'app.diagnostics.reporter_failed',
        ],
      );
      expect(
        secondLogger.records.map((record) => record.descriptor.eventName),
        ['app.diagnostics.error_reported'],
      );
    });
  });
}
