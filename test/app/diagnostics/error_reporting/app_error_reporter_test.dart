import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_formatter.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';

final class _SensitiveFailure implements Exception {
  @override
  String toString() => 'token=secret';
}

void main() {
  group('LocalAppErrorReporter', () {
    test('formats and invokes its local sink before returning', () async {
      String? writtenMessage;
      final reporter = LocalAppErrorReporter.withSink(
        formatter: const AppErrorFormatter(AppDiagnosticDetail.supportOnly),
        sink: (message) => writtenMessage = message,
      );

      final completion = reporter.report(
        _SensitiveFailure(),
        null,
        kind: AppErrorReportKind.environment,
      );

      expect(writtenMessage, 'APP-ENVIRONMENT-001 Environment');
      await expectLater(completion, completes);
    });

    test('passes a supplied stack only through the safe formatter', () async {
      String? writtenMessage;
      final reporter = LocalAppErrorReporter.withSink(
        formatter: const AppErrorFormatter(AppDiagnosticDetail.debug),
        sink: (message) => writtenMessage = message,
      );
      final stackTrace = StackTrace.fromString('original local stack');

      await reporter.report(
        _SensitiveFailure(),
        stackTrace,
        kind: AppErrorReportKind.dependencyRollback,
      );

      expect(
        writtenMessage,
        'APP-DI-ROLLBACK-001 Dependency rollback '
        'type=_SensitiveFailure\noriginal local stack',
      );
      expect(writtenMessage, isNot(contains('secret')));
    });

    test('turns a synchronous sink failure into a failed Future', () async {
      final sinkFailure = StateError('sink failure');
      final sinkStackTrace = StackTrace.fromString('sink stack');
      final reporter = LocalAppErrorReporter.withSink(
        formatter: const AppErrorFormatter(AppDiagnosticDetail.supportOnly),
        sink: (_) => Error.throwWithStackTrace(sinkFailure, sinkStackTrace),
      );
      late Future<void> completion;

      expect(
        () => completion = reporter.report(
          _SensitiveFailure(),
          null,
          kind: AppErrorReportKind.startup,
        ),
        returnsNormally,
      );

      Object? caughtError;
      StackTrace? caughtStackTrace;
      try {
        await completion;
      } on Object catch (error, stackTrace) {
        caughtError = error;
        caughtStackTrace = stackTrace;
      }

      expect(caughtError, same(sinkFailure));
      expect(caughtStackTrace.toString(), contains('sink stack'));
    });
  });

  test('NoopAppErrorReporter returns a completed Future', () async {
    const reporter = NoopAppErrorReporter();

    await expectLater(
      reporter.report(
        _SensitiveFailure(),
        null,
        kind: AppErrorReportKind.rootZone,
      ),
      completes,
    );
  });
}
