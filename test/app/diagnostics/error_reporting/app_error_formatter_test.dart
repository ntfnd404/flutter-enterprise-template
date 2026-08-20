import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_formatter.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';

final class _SensitiveFailure implements Exception {
  @override
  String toString() => 'https://example.test/?token=secret response-body';
}

final class _ThrowingFailure implements Exception {
  @override
  String toString() => throw StateError('failure must not be rendered');
}

final class _ThrowingStackTrace implements StackTrace {
  @override
  String toString() => throw StateError('stack must not escape');
}

void main() {
  group('AppErrorFormatter', () {
    test('debug detail includes only failure type and guarded stack', () {
      const formatter = AppErrorFormatter(AppDiagnosticDetail.debug);

      final result = formatter.format(
        _SensitiveFailure(),
        kind: AppErrorReportKind.startup,
        stackTrace: StackTrace.fromString('local debug stack'),
      );

      expect(
        result,
        'APP-STARTUP-001 Startup type=_SensitiveFailure\nlocal debug stack',
      );
      expect(result, isNot(contains('secret')));
      expect(result, isNot(contains('example.test')));
    });

    test('never invokes the failure toString', () {
      const formatter = AppErrorFormatter(AppDiagnosticDetail.debug);

      expect(
        formatter.format(
          _ThrowingFailure(),
          kind: AppErrorReportKind.rootZone,
        ),
        'APP-ROOT-001 Root zone type=_ThrowingFailure',
      );
    });

    test('preserves an absent stack instead of fabricating one', () {
      const formatter = AppErrorFormatter(AppDiagnosticDetail.debug);

      final result = formatter.format(
        _SensitiveFailure(),
        kind: AppErrorReportKind.flutterFramework,
      );

      expect(
        result,
        'APP-FRAMEWORK-001 Flutter framework type=_SensitiveFailure',
      );
      expect(result, isNot(contains('\n')));
    });

    test('guards a throwing stack trace in debug detail', () {
      const formatter = AppErrorFormatter(AppDiagnosticDetail.debug);

      expect(
        formatter.format(
          _ThrowingFailure(),
          kind: AppErrorReportKind.rootZone,
          stackTrace: _ThrowingStackTrace(),
        ),
        'APP-ROOT-001 Root zone type=_ThrowingFailure\n'
        '<stack trace unavailable>',
      );
    });

    test('support-only detail does not inspect failure or stack', () {
      const formatter = AppErrorFormatter(AppDiagnosticDetail.supportOnly);

      expect(
        formatter.format(
          _ThrowingFailure(),
          kind: AppErrorReportKind.platformDispatcher,
          stackTrace: _ThrowingStackTrace(),
        ),
        'APP-PLATFORM-001 Platform dispatcher',
      );
    });

    test('current build selects debug details only in debug mode', () {
      final formatter = AppErrorFormatter.forCurrentBuild();

      expect(
        formatter.detail,
        kDebugMode
            ? AppDiagnosticDetail.debug
            : AppDiagnosticDetail.supportOnly,
      );
    });
  });

  test('report kinds have exact unique support mappings', () {
    expect(
      AppErrorReportKind.values.map(
        (kind) => (kind.wireValue, kind.code, kind.label),
      ),
      const [
        ('root_zone', 'APP-ROOT-001', 'Root zone'),
        ('environment', 'APP-ENVIRONMENT-001', 'Environment'),
        ('startup', 'APP-STARTUP-001', 'Startup'),
        ('flutter_framework', 'APP-FRAMEWORK-001', 'Flutter framework'),
        ('platform_dispatcher', 'APP-PLATFORM-001', 'Platform dispatcher'),
        ('dependency_rollback', 'APP-DI-ROLLBACK-001', 'Dependency rollback'),
        ('dependency_disposal', 'APP-DI-DISPOSE-001', 'Dependency disposal'),
      ],
    );

    final codes = AppErrorReportKind.values.map((kind) => kind.code);
    final wireValues = AppErrorReportKind.values.map((kind) => kind.wireValue);

    expect(codes.toSet(), hasLength(codes.length));
    expect(wireValues.toSet(), hasLength(wireValues.length));
    expect(
      AppErrorReportKind.values.map((kind) => kind.supportCode.value),
      codes,
    );
  });
}
