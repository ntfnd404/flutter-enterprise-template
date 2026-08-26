import 'dart:async';

import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';

typedef TestReportCallback = Future<void> Function(
  Object error,
  StackTrace? stackTrace,
  AppErrorReportKind kind,
);

typedef TestReportRecord = ({
  Object error,
  StackTrace? stackTrace,
  AppErrorReportKind kind,
});

final class TestCallbackAppErrorReporter(final TestReportCallback callback)
    implements AppErrorReporter {
  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) => callback(error, stackTrace, kind);
}

final class TestRecordingAppErrorReporter implements AppErrorReporter {
  final records = <TestReportRecord>[];
  final _waiters = <({int count, Completer<void> completer})>[];

  Future<void> waitForCount(int count) {
    if (count <= 0) {
      throw ArgumentError('Expected report count must be positive.');
    }
    if (records.length >= count) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    _waiters.add((count: count, completer: completer));

    return completer.future;
  }

  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) {
    records.add((error: error, stackTrace: stackTrace, kind: kind));
    for (final waiter in _waiters.toList()) {
      if (records.length >= waiter.count) {
        _waiters.remove(waiter);
        waiter.completer.complete();
      }
    }

    return Future<void>.value();
  }
}

final class TestCallbackAppLogger(
  final void Function(AppLogRecord record) callback,
) implements AppLogger {
  @override
  void log(AppLogRecord record) => callback(record);
}

final class TestRecordingAppLogger implements AppLogger {
  final records = <AppLogRecord>[];

  @override
  void log(AppLogRecord record) => records.add(record);
}

AppErrorBoundary createTestErrorBoundary({
  AppErrorReporter? reporter,
  AppLogger? logger,
}) => AppErrorBoundary(
  reporter: reporter ?? TestRecordingAppErrorReporter(),
  logger: logger ?? TestRecordingAppLogger(),
);
