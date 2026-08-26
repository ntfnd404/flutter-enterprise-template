import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';

/// One test-owned application error report with its original values.
final class AppErrorReportRecord({
  /// Original error object received by the reporter.
  required final Object error,

  /// Original optional stack received by the reporter.
  required final StackTrace? stackTrace,

  /// Application report kind assigned by the reporting boundary.
  required final AppErrorReportKind kind,
});

/// Records every report synchronously for process-isolated integration tests.
final class RecordingAppErrorReporter implements AppErrorReporter {
  /// Reports observed by this instance in invocation order.
  final List<AppErrorReportRecord> records = <AppErrorReportRecord>[];

  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) {
    records.add(
      AppErrorReportRecord(
        error: error,
        stackTrace: stackTrace,
        kind: kind,
      ),
    );

    return Future<void>.value();
  }
}
