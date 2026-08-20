import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/records/app_bloc_log_records.dart';
import 'package:template/app/diagnostics/logging/records/app_error_log_records.dart';

final class _Component {}

final class _Event {}

final class _PreviousState {}

final class _NextState {}

final class _Action {}

final class _Failure implements Exception {}

void main() {
  group('built-in records', () {
    test('expose exact unique static descriptors and typed fields', () {
      final records = <_RecordExpectation>[
        _RecordExpectation(
          record: const AppBlocCreatedLogRecord(_Component),
          staticDescriptor: AppBlocCreatedLogRecord.recordDescriptor,
          eventName: 'app.bloc.created',
          severity: AppLogSeverity.info,
          dataClass: AppLogDataClass.debugOnly,
          fields: const <_RecordedField>[
            _RecordedField('component_type', 'debug_type', _Component),
          ],
        ),
        _RecordExpectation(
          record: const AppBlocEventLogRecord(_Component, _Event),
          staticDescriptor: AppBlocEventLogRecord.recordDescriptor,
          eventName: 'app.bloc.event',
          severity: AppLogSeverity.info,
          dataClass: AppLogDataClass.debugOnly,
          fields: const <_RecordedField>[
            _RecordedField('component_type', 'debug_type', _Component),
            _RecordedField('event_type', 'debug_type', _Event),
          ],
        ),
        _RecordExpectation(
          record: const AppBlocStateChangedLogRecord(
            _Component,
            _PreviousState,
            _NextState,
          ),
          staticDescriptor: AppBlocStateChangedLogRecord.recordDescriptor,
          eventName: 'app.bloc.state_changed',
          severity: AppLogSeverity.info,
          dataClass: AppLogDataClass.debugOnly,
          fields: const <_RecordedField>[
            _RecordedField('component_type', 'debug_type', _Component),
            _RecordedField(
              'previous_state_type',
              'debug_type',
              _PreviousState,
            ),
            _RecordedField('next_state_type', 'debug_type', _NextState),
          ],
        ),
        _RecordExpectation(
          record: const AppBlocActionLogRecord(_Component, _Action),
          staticDescriptor: AppBlocActionLogRecord.recordDescriptor,
          eventName: 'app.bloc.action',
          severity: AppLogSeverity.info,
          dataClass: AppLogDataClass.debugOnly,
          fields: const <_RecordedField>[
            _RecordedField('component_type', 'debug_type', _Component),
            _RecordedField('action_type', 'debug_type', _Action),
          ],
        ),
        _RecordExpectation(
          record: const AppBlocErrorBreadcrumbLogRecord(
            _Component,
            _Failure,
          ),
          staticDescriptor: AppBlocErrorBreadcrumbLogRecord.recordDescriptor,
          eventName: 'app.bloc.error_breadcrumb',
          severity: AppLogSeverity.warning,
          dataClass: AppLogDataClass.debugOnly,
          fields: const <_RecordedField>[
            _RecordedField('component_type', 'debug_type', _Component),
            _RecordedField('error_type', 'debug_type', _Failure),
          ],
        ),
        _RecordExpectation(
          record: const AppBlocClosedLogRecord(_Component),
          staticDescriptor: AppBlocClosedLogRecord.recordDescriptor,
          eventName: 'app.bloc.closed',
          severity: AppLogSeverity.info,
          dataClass: AppLogDataClass.debugOnly,
          fields: const <_RecordedField>[
            _RecordedField('component_type', 'debug_type', _Component),
          ],
        ),
        _RecordExpectation(
          record: AppErrorReportedLogRecord(
            AppLogStableCode('APP-ROOT-001'),
          ),
          staticDescriptor: AppErrorReportedLogRecord.recordDescriptor,
          eventName: 'app.diagnostics.error_reported',
          severity: AppLogSeverity.error,
          dataClass: AppLogDataClass.supportSafe,
          fields: const <_RecordedField>[
            _RecordedField('report_code', 'support_code', 'APP-ROOT-001'),
          ],
        ),
        _RecordExpectation(
          record: const AppErrorReporterFailureLogRecord(),
          staticDescriptor: AppErrorReporterFailureLogRecord.recordDescriptor,
          eventName: 'app.diagnostics.reporter_failed',
          severity: AppLogSeverity.error,
          dataClass: AppLogDataClass.supportSafe,
          fields: const <_RecordedField>[
            _RecordedField(
              'support_code',
              'support_code',
              'APP-REPORT-001',
            ),
          ],
        ),
      ];

      final schemaKeys = <String>{};
      for (final expectation in records) {
        final descriptor = expectation.record.descriptor;
        final writer = _RecordingFieldWriter();

        expect(identical(descriptor, expectation.staticDescriptor), isTrue);
        expect(descriptor.eventName, expectation.eventName);
        expect(descriptor.eventVersion, 1);
        expect(descriptor.severity, expectation.severity);
        expect(descriptor.dataClass, expectation.dataClass);
        expect(
          expectation.record.project(writer),
          AppLogProjectionResult.complete,
        );
        expect(writer.fields, expectation.fields);
        expect(
          schemaKeys.add('${descriptor.eventName}:${descriptor.eventVersion}'),
          isTrue,
          reason: 'Every built-in event name/version pair must be unique.',
        );
      }
    });
  });
}

final class _RecordExpectation {
  const _RecordExpectation({
    required this.record,
    required this.staticDescriptor,
    required this.eventName,
    required this.severity,
    required this.dataClass,
    required this.fields,
  });

  final AppLogRecord record;
  final AppLogRecordDescriptor staticDescriptor;
  final String eventName;
  final AppLogSeverity severity;
  final AppLogDataClass dataClass;
  final List<_RecordedField> fields;
}

final class const _RecordedField(
  final String name,
  final String kind,
  final Object value,
) {
  @override
  bool operator ==(Object other) =>
      other is _RecordedField &&
      other.name == name &&
      other.kind == kind &&
      other.value == value;

  @override
  int get hashCode => Object.hash(name, kind, value);
}

final class _RecordingFieldWriter implements AppLogFieldWriter {
  final fields = <_RecordedField>[];

  @override
  void debugType(String fieldName, Type value) {
    fields.add(_RecordedField(fieldName, 'debug_type', value));
  }

  @override
  void supportCode(String fieldName, AppLogStableCode value) {
    fields.add(_RecordedField(fieldName, 'support_code', value.value));
  }

  @override
  void supportCount(String fieldName, int value) {
    fields.add(_RecordedField(fieldName, 'support_count', value));
  }

  @override
  void supportDuration(String fieldName, Duration value) {
    fields.add(_RecordedField(fieldName, 'support_duration', value));
  }

  @override
  // The positional value mirrors the production projection SPI.
  // ignore: avoid_positional_boolean_parameters
  void supportFlag(String fieldName, bool value) {
    fields.add(_RecordedField(fieldName, 'support_flag', value));
  }
}
