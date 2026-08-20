import 'package:template/app/diagnostics/logging/app_log_record.dart';

/// Support-safe breadcrumb emitted before one raw unexpected-error report.
final class AppErrorReportedLogRecord extends AppLogRecord {
  /// Creates a record for the reviewed root report [reportCode].
  const AppErrorReportedLogRecord(this.reportCode);

  /// Stable support code of the root report origin.
  final AppLogStableCode reportCode;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.diagnostics.error_reported',
    eventVersion: 1,
    severity: AppLogSeverity.error,
    dataClass: AppLogDataClass.supportSafe,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields.supportCode('report_code', reportCode);

    return AppLogProjectionResult.complete;
  }
}

/// Support-safe breadcrumb emitted when the raw error reporter itself fails.
final class AppErrorReporterFailureLogRecord extends AppLogRecord {
  /// Creates the fixed reporter-failure record.
  const AppErrorReporterFailureLogRecord();

  static final _supportCode = AppLogStableCode(
    'APP-REPORT-001',
  );

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.diagnostics.reporter_failed',
    eventVersion: 1,
    severity: AppLogSeverity.error,
    dataClass: AppLogDataClass.supportSafe,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields.supportCode('support_code', _supportCode);

    return AppLogProjectionResult.complete;
  }
}
