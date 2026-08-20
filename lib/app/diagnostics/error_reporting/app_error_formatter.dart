import 'package:flutter/foundation.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';

/// Formats an untrusted failure without evaluating its message.
final class const AppErrorFormatter(
  /// Local diagnostic detail policy applied by [format].
  final AppDiagnosticDetail detail,
) {
  /// Selects debug details only for a debug build.
  factory AppErrorFormatter.forCurrentBuild() => const AppErrorFormatter(
    kDebugMode ? AppDiagnosticDetail.debug : AppDiagnosticDetail.supportOnly,
  );

  /// Produces a local diagnostic description for [error].
  ///
  /// Support-only output contains no runtime type or stack. Debug output is
  /// available only while [kDebugMode] is true; profile and release clamp any
  /// requested debug detail to support-only output. Debug formatting never
  /// invokes [Object.toString] on the failure itself.
  String format(
    Object error, {
    required AppErrorReportKind kind,
    StackTrace? stackTrace,
  }) {
    final supportDescription = '${kind.code} ${kind.label}';
    if (!kDebugMode || detail == AppDiagnosticDetail.supportOnly) {
      return supportDescription;
    }
    final typeDescription = '$supportDescription type=${error.runtimeType}';
    if (stackTrace == null) {
      return typeDescription;
    }

    return '$typeDescription\n${_formatStackTrace(stackTrace)}';
  }
}

/// Local detail policies supported by [AppErrorFormatter].
enum AppDiagnosticDetail {
  /// Includes runtime type and guarded stack details for local debugging.
  debug,

  /// Includes only a stable support code and static English label.
  supportOnly,
}

String _formatStackTrace(StackTrace stackTrace) {
  try {
    return stackTrace.toString();
  } on Object {
    return '<stack trace unavailable>';
  }
}
