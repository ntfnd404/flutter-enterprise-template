import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';

/// Captures the test-owned boundary created from the composition-root roles.
final class CapturingAppErrorBoundaryFactory {
  AppErrorBoundary? _boundary;

  /// Creates and captures a boundary using the exact supplied roles.
  AppErrorBoundary create({
    required AppLogger logger,
    required AppErrorReporter reporter,
  }) {
    final boundary = AppErrorBoundary(
      logger: logger,
      reporter: reporter,
    );
    _boundary = boundary;

    return boundary;
  }

  /// The captured boundary after [create] has run.
  AppErrorBoundary get boundary {
    final boundary = _boundary;
    if (boundary == null) {
      throw StateError('The test error boundary has not been created.');
    }

    return boundary;
  }

  /// Disposes the captured boundary after the test has reached quiescence.
  void dispose() {
    _boundary?.dispose();
  }
}
