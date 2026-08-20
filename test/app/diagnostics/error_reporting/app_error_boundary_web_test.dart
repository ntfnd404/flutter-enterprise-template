import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('guarded root Zone reports an externally completed Future', () async {
    final reported = Completer<void>();
    final reporter = _WebRecordingReporter(reported);
    final boundary = AppErrorBoundary(
      reporter: reporter,
      logger: _WebNoopLogger(),
    );
    addTearDown(boundary.dispose);
    try {
      final failure = StateError('root Zone Web failure');
      final stackTrace = StackTrace.fromString('root Zone Web stack');
      late Completer<void> bodyCompletion;

      boundary.run(() {
        bodyCompletion = Completer<void>();

        return bodyCompletion.future;
      });
      bodyCompletion.completeError(failure, stackTrace);
      await reported.future;
      await Future<void>.delayed(Duration.zero);

      expect(reporter.error, same(failure));
      expect(reporter.stackTrace, same(stackTrace));
      expect(reporter.kind, AppErrorReportKind.rootZone);
    } finally {
      boundary.dispose();
    }
  });
}

final class _WebRecordingReporter(final Completer<void> reported)
    implements AppErrorReporter {
  Object? error;
  StackTrace? stackTrace;
  AppErrorReportKind? kind;

  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) {
    this.error = error;
    this.stackTrace = stackTrace;
    this.kind = kind;
    reported.complete();

    return Future<void>.value();
  }
}

final class _WebNoopLogger implements AppLogger {
  @override
  void log(AppLogRecord record) {}
}
