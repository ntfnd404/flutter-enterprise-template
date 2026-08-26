import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/developer_app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_error_log_records.dart';

final class _Component {}

void main() {
  group('DeveloperAppLogger projection', () {
    test('drops debug-only records before projection when disabled', () {
      final entries = <({String message, int level})>[];
      final record = _ProjectionRecord(
        descriptor: _debugDescriptor,
        projectFields: (_) {
          fail('A suppressed debug record must not be projected.');
        },
      );
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );

      expect(() => logger.log(record), returnsNormally);
      expect(record.descriptorReads, 1);
      expect(record.projectionCalls, 0);
      expect(entries, isEmpty);
    });

    test('omits debug fields from support-safe records when disabled', () {
      final entries = <({String message, int level})>[];
      final record = _ProjectionRecord(
        descriptor: _supportDescriptor,
        projectFields: (fields) {
          fields
            ..debugType('component_type', _Component)
            ..supportFlag('enabled', true)
            ..supportCount('attempt_count', 12)
            ..supportDuration(
              'elapsed',
              const Duration(microseconds: 34),
            )
            ..supportCode('result_code', AppLogStableCode('APP-TEST-001'));
        },
      );
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );

      logger.log(record);

      expect(record.descriptorReads, 1);
      expect(record.projectionCalls, 1);
      expect(entries, <({String message, int level})>[
        (
          message:
              'app.test.support event_version=1 severity=warning '
              'enabled=true attempt_count=12 elapsed=34 '
              'result_code=APP-TEST-001',
          level: 900,
        ),
      ]);
    });

    test('validates suppressed debug declarations as part of the schema', () {
      final entries = <({String message, int level})>[];
      final duplicateName = _ProjectionRecord(
        descriptor: _supportDescriptor,
        projectFields: (fields) {
          fields
            ..debugType('duplicate', _Component)
            ..supportFlag('duplicate', false);
        },
      );
      final tooManyDebugFields = _ProjectionRecord(
        descriptor: _supportDescriptor,
        projectFields: (fields) {
          for (var index = 0; index < 33; index += 1) {
            fields.debugType('debug_type_$index', _Component);
          }
        },
      );
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );

      logger
        ..log(duplicateName)
        ..log(tooManyDebugFields);

      expect(duplicateName.projectionCalls, 1);
      expect(tooManyDebugFields.projectionCalls, 1);
      expect(entries, isEmpty);
    });

    test('accepts exact field count and numeric upper bounds', () {
      final entries = <({String message, int level})>[];
      final record = _ProjectionRecord(
        descriptor: _supportDescriptor,
        projectFields: (fields) {
          for (var index = 0; index < 30; index += 1) {
            fields.supportFlag('flag_$index', true);
          }
          fields
            ..supportCount('count_limit', 9007199254740991)
            ..supportDuration(
              'duration_limit',
              const Duration(microseconds: 9007199254740991),
            );
        },
      );
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );

      logger.log(record);

      expect(record.projectionCalls, 1);
      expect(entries, hasLength(1));
      expect(entries.single.message, contains('flag_29=true'));
      expect(
        entries.single.message,
        contains('count_limit=9007199254740991'),
      );
      expect(
        entries.single.message,
        contains('duration_limit=9007199254740991'),
      );
    });

    test('atomically rejects every invalid projection shape', () {
      final entries = <({String message, int level})>[];
      final overlongFieldName = List<String>.filled(49, 'a').join();
      final records = <_ProjectionRecord>[
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields
              ..supportFlag('duplicate', true)
              ..supportFlag('duplicate', false);
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields.supportFlag('Invalid_Field', true);
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields.supportFlag(overlongFieldName, true);
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields.supportCount('attempt_count', -1);
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields.supportCount('attempt_count', 9007199254740992);
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields.supportDuration(
              'elapsed',
              const Duration(microseconds: -1),
            );
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            fields.supportDuration(
              'elapsed',
              const Duration(microseconds: 9007199254740992),
            );
          },
        ),
        _ProjectionRecord(
          descriptor: _supportDescriptor,
          projectFields: (fields) {
            for (var index = 0; index < 33; index += 1) {
              fields.supportFlag('flag_$index', true);
            }
          },
        ),
      ];
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );

      for (final record in records) {
        expect(() => logger.log(record), returnsNormally);
        expect(record.projectionCalls, 1);
      }
      expect(entries, isEmpty);
    });

    test('contains descriptor, projection, and sink failures', () {
      final entries = <({String message, int level})>[];
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
          throw StateError('Hostile sink.');
        },
      );
      final projectionFailure = _ProjectionRecord(
        descriptor: _supportDescriptor,
        projectFields: (_) {
          throw StateError('Hostile projection.');
        },
      );

      expect(
        () => logger.log(const _ThrowingDescriptorRecord()),
        returnsNormally,
      );
      expect(() => logger.log(projectionFailure), returnsNormally);
      expect(
        () => logger.log(
          AppErrorReportedLogRecord(AppLogStableCode('APP-ROOT-001')),
        ),
        returnsNormally,
      );

      expect(projectionFailure.projectionCalls, 1);
      expect(entries, hasLength(1));
    });

    test('turns a retained writer into a silent tombstone', () {
      final entries = <({String message, int level})>[];
      late AppLogFieldWriter retainedWriter;
      final record = _ProjectionRecord(
        descriptor: _supportDescriptor,
        projectFields: (fields) {
          retainedWriter = fields;
          fields.supportFlag('enabled', true);
        },
      );
      final logger = DeveloperAppLogger.withSink(
        sink: (message, level) {
          entries.add((message: message, level: level));
        },
        includeDebugRecords: false,
      );

      logger.log(record);
      final originalEntry = entries.single;

      expect(
        () => retainedWriter
          ..debugType('late_type', _Component)
          ..supportFlag('late_flag', true)
          ..supportCount('late_count', -1)
          ..supportDuration(
            'late_duration',
            const Duration(microseconds: -1),
          )
          ..supportCode('late_code', AppLogStableCode('APP-LATE-001')),
        returnsNormally,
      );
      expect(entries, <({String message, int level})>[originalEntry]);
    });
  });
}

final _debugDescriptor = AppLogRecordDescriptor(
  eventName: 'app.test.debug',
  eventVersion: 1,
  severity: AppLogSeverity.info,
  dataClass: AppLogDataClass.debugOnly,
);

final _supportDescriptor = AppLogRecordDescriptor(
  eventName: 'app.test.support',
  eventVersion: 1,
  severity: AppLogSeverity.warning,
  dataClass: AppLogDataClass.supportSafe,
);
typedef _ProjectFields = void Function(AppLogFieldWriter fields);

final class _ProjectionRecord extends AppLogRecord {
  factory _ProjectionRecord({
    required AppLogRecordDescriptor descriptor,
    required _ProjectFields projectFields,
  }) => _ProjectionRecord._(descriptor, projectFields);

  _ProjectionRecord._(this._descriptor, this.projectFields);

  final AppLogRecordDescriptor _descriptor;
  final _ProjectFields projectFields;
  int descriptorReads = 0;
  int projectionCalls = 0;

  @override
  AppLogRecordDescriptor get descriptor {
    descriptorReads += 1;

    return _descriptor;
  }

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    projectionCalls += 1;
    projectFields(fields);

    return AppLogProjectionResult.complete;
  }
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
