import 'package:template/app/diagnostics/logging/app_log_record.dart';

final class ReviewedSupportOperationLogRecord extends AppLogRecord {
  ReviewedSupportOperationLogRecord({
    required this.fallbackUsed,
    required this.attemptCount,
    required this.elapsed,
    required this.resultCode,
  });

  final bool fallbackUsed;
  final int attemptCount;
  final Duration elapsed;
  final AppLogStableCode resultCode;

  static final recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.test.support_operation',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.supportSafe,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields
      ..supportFlag('fallback_used', fallbackUsed)
      ..supportCount('attempt_count', attemptCount)
      ..supportDuration('elapsed', elapsed)
      ..supportCode('result_code', resultCode);

    return AppLogProjectionResult.complete;
  }
}
