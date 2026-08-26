import 'package:template/app/diagnostics/logging/app_log_record.dart';

/// Support-safe breadcrumb emitted when post-binding startup begins.
final class AppStartupStartedLogRecord extends AppLogRecord {
  /// Creates the fixed startup-started record.
  const AppStartupStartedLogRecord();

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.startup.started',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.supportSafe,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    return AppLogProjectionResult.complete;
  }
}

/// Support-safe breadcrumb emitted after root ownership handoff is scheduled.
final class AppStartupCompletedLogRecord extends AppLogRecord {
  /// Creates a completion record for the measured startup [duration].
  AppStartupCompletedLogRecord(this.duration) {
    if (duration.isNegative) {
      throw ArgumentError('Startup duration cannot be negative.');
    }
  }

  /// Monotonic duration from the started breadcrumb through `runApp` return.
  final Duration duration;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.startup.completed',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.supportSafe,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields.supportDuration('duration', duration);

    return AppLogProjectionResult.complete;
  }
}
