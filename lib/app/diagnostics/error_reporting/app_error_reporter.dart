import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_formatter.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';

/// Reports one application failure with its original optional stack trace.
///
/// Implementations are borrowed collaborators. They must return a Future for
/// all work they start and must not create detached reporting tasks.
abstract interface class AppErrorReporter {
  /// Reports [error] in the application-owned [kind].
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  });
}

/// Writes one privacy-safe local diagnostic through `dart:developer`.
final class LocalAppErrorReporter._(
  final AppErrorFormatter _formatter,
  final _AppLocalDiagnosticSink _sink,
) implements AppErrorReporter {
  /// Creates the default local reporter.
  factory LocalAppErrorReporter({required AppErrorFormatter formatter}) =>
      LocalAppErrorReporter._(formatter, _writeLocalDiagnostic);

  /// Creates a local reporter with a deterministic synchronous sink for tests.
  @visibleForTesting
  factory LocalAppErrorReporter.withSink({
    required AppErrorFormatter formatter,
    required void Function(String message) sink,
  }) => LocalAppErrorReporter._(formatter, sink);

  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) {
    try {
      final message = _formatter.format(
        error,
        kind: kind,
        stackTrace: stackTrace,
      );
      _sink(message);

      return Future<void>.value();
    } on Object catch (sinkError, sinkStackTrace) {
      return Future<void>.error(sinkError, sinkStackTrace);
    }
  }
}

/// Discards failures while preserving the strict asynchronous reporter API.
final class const NoopAppErrorReporter() implements AppErrorReporter {
  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) => Future<void>.value();
}

typedef _AppLocalDiagnosticSink = void Function(String message);

void _writeLocalDiagnostic(String message) {
  developer.log(message, name: 'Application', level: 1000);
}
