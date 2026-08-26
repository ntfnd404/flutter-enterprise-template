import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/diagnostics/logging/developer_app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_bloc_log_records.dart';
import 'package:template/app/diagnostics/logging/records/app_error_log_records.dart';

import 'support/reviewed_support_operation_log_record.dart';

final class _Component {}

final class _Event {}

final class _Failure implements Exception {}

void main() {
  group('DeveloperAppLogger', () {
    test('writes normalized typed projections at policy-owned levels', () {
      final entries = <({String message, int level})>[];
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
      );

      logger
        ..log(const AppBlocCreatedLogRecord(_Component))
        ..log(const AppBlocEventLogRecord(_Component, _Event))
        ..log(
          const AppBlocErrorBreadcrumbLogRecord(_Component, _Failure),
        )
        ..log(
          AppErrorReportedLogRecord(AppLogStableCode('APP-ROOT-001')),
        )
        ..log(const AppErrorReporterFailureLogRecord());

      expect(entries, <({String message, int level})>[
        (
          message:
              'app.bloc.created event_version=1 severity=info '
              'component_type=_Component',
          level: 800,
        ),
        (
          message:
              'app.bloc.event event_version=1 severity=info '
              'component_type=_Component event_type=_Event',
          level: 800,
        ),
        (
          message:
              'app.bloc.error_breadcrumb event_version=1 severity=warning '
              'component_type=_Component error_type=_Failure',
          level: 900,
        ),
        (
          message:
              'app.diagnostics.error_reported event_version=1 '
              'severity=error report_code=APP-ROOT-001',
          level: 1000,
        ),
        (
          message:
              'app.diagnostics.reporter_failed event_version=1 '
              'severity=error support_code=APP-REPORT-001',
          level: 1000,
        ),
      ]);
    });

    test('accepts a reviewed final record from another library', () {
      final entries = <({String message, int level})>[];
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );
      final record = ReviewedSupportOperationLogRecord(
        fallbackUsed: true,
        attemptCount: 2,
        elapsed: const Duration(microseconds: 34),
        resultCode: AppLogStableCode('APP-TEST-001'),
      );

      logger.log(record);

      expect(entries, <({String message, int level})>[
        (
          message:
              'app.test.support_operation event_version=1 severity=info '
              'fallback_used=true attempt_count=2 elapsed=34 '
              'result_code=APP-TEST-001',
          level: 800,
        ),
      ]);
    });
  });

  test('NoopAppLogger does not inspect or project a record', () {
    const logger = NoopAppLogger();

    expect(
      () => logger.log(const _ThrowingDescriptorRecord()),
      returnsNormally,
    );
  });
}

final class _ThrowingDescriptorRecord extends AppLogRecord {
  const _ThrowingDescriptorRecord();

  @override
  AppLogRecordDescriptor get descriptor {
    throw StateError('Hostile descriptor.');
  }

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fail('A record with a hostile descriptor must not be projected.');
  }
}
