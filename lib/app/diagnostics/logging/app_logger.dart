import 'package:template/app/diagnostics/logging/app_log_record.dart';

/// Writes one typed operational breadcrumb synchronously.
///
/// A logger is a borrowed, non-owning collaborator. Built-in implementations
/// contain record and sink failures and never interpret records as analytics.
/// An implementation must not declare [log] as `async`, reenter itself, call
/// the application error boundary or reporter, or install global handlers. A
/// future owning module may schedule only work that it tracks and contains.
abstract interface class AppLogger {
  /// Attempts to write [record] without delaying the calling flow.
  ///
  /// Validation, projection, and any synchronous sink or enqueue handoff
  /// finish before this method returns. No failure escapes to the caller.
  void log(AppLogRecord record);
}

/// Discards records without inspecting or projecting them.
final class const NoopAppLogger() implements AppLogger {
  @override
  void log(AppLogRecord record) {}
}
