import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';

void main() {
  group('AppLogRecordDescriptor', () {
    test('retains an explicitly valid schema', () {
      final descriptor = AppLogRecordDescriptor(
        eventName: 'app.example.completed',
        eventVersion: 2147483647,
        severity: AppLogSeverity.warning,
        dataClass: AppLogDataClass.supportSafe,
      );

      expect(descriptor.eventName, 'app.example.completed');
      expect(descriptor.eventVersion, 2147483647);
      expect(descriptor.severity, AppLogSeverity.warning);
      expect(descriptor.dataClass, AppLogDataClass.supportSafe);
    });

    test('rejects invalid event names with a static message', () {
      final overlongName = 'app.${List<String>.filled(93, 'a').join()}';
      final invalidNames = <String>[
        '',
        'app',
        '.app.started',
        'app.started.',
        'App.started',
        'app.started-now',
        overlongName,
      ];

      for (final name in invalidNames) {
        expect(
          () => AppLogRecordDescriptor(
            eventName: name,
            eventVersion: 1,
            severity: AppLogSeverity.info,
            dataClass: AppLogDataClass.debugOnly,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'App log event name is invalid.',
            ),
          ),
        );
      }
    });

    test('rejects versions outside the positive 31-bit range', () {
      for (final version in <int>[0, -1, 2147483648]) {
        expect(
          () => AppLogRecordDescriptor(
            eventName: 'app.example.completed',
            eventVersion: version,
            severity: AppLogSeverity.info,
            dataClass: AppLogDataClass.debugOnly,
          ),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'App log event version is invalid.',
            ),
          ),
        );
      }
    });
  });

  group('AppLogStableCode', () {
    test('retains a reviewed token', () {
      expect(AppLogStableCode('APP-ROOT-001').value, 'APP-ROOT-001');
    });

    test('rejects invalid tokens with a static message', () {
      final overlongCode = 'APP-${List<String>.filled(61, 'A').join()}';
      final invalidCodes = <String>[
        '',
        'APP',
        'app-root-001',
        'APP ROOT 001',
        'APP_ROOT_001',
        overlongCode,
      ];

      for (final code in invalidCodes) {
        expect(
          () => AppLogStableCode(code),
          throwsA(
            isA<ArgumentError>().having(
              (error) => error.message,
              'message',
              'App log stable code is invalid.',
            ),
          ),
        );
      }
    });
  });
  test('wire values are explicit and stable', () {
    expect(
      AppLogSeverity.values.map((value) => value.wireValue),
      <String>['info', 'warning', 'error'],
    );
    expect(
      AppLogDataClass.values.map((value) => value.wireValue),
      <String>['debug_only', 'support_safe'],
    );
  });
}
