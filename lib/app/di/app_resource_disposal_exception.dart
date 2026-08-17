import 'dart:async';

/// A resource cleanup failure and the stack trace where it occurred.
///
/// [error] and [stackTrace] are sensitive diagnostic values. Callers must pass
/// them only to an approved diagnostics boundary and must not render them in
/// user-facing output.
final class const AppResourceDisposalFailure({
  /// The original object thrown by the resource disposer.
  required final Object error,

  /// The original stack trace captured at the disposer boundary.
  required final StackTrace stackTrace,
}) {
  @override
  String toString() => 'AppResourceDisposalFailure';
}

/// Handles one aggregate failure raised while releasing graph-owned resources.
///
/// DI selects the failure and preserves its stack trace. Application
/// composition adapts this callback to diagnostics without making DI depend on
/// a concrete reporter. DI awaits the callback to preserve failure ordering;
/// an implementation that performs I/O must enforce its own bounded timeout.
typedef AppResourceDisposalFailureCallback = FutureOr<void> Function(
  AppResourceDisposalException error,
  StackTrace stackTrace,
);

/// Captures secondary cleanup failures raised while graph construction rolls
/// back.
///
/// This callback is deliberately synchronous: rollback must finish before the
/// primary construction failure is rethrown, but reporting I/O does not belong
/// in that critical path. Implementations must only retain the aggregate in
/// caller-owned local state for later, correctly ordered reporting; they must
/// not report outward, perform I/O, or throw.
typedef AppResourceRollbackFailureCollector = void Function(
  AppResourceDisposalException error,
  StackTrace stackTrace,
);

/// Aggregates every failure raised while disposing an application graph.
///
/// Cleanup continues after individual failures. Error messages are omitted
/// from [toString] so diagnostics do not accidentally render credentials,
/// paths, provider response bodies, or arbitrary exception messages.
final class AppResourceDisposalException implements Exception {
  /// Creates a non-empty immutable aggregate of [failures].
  factory AppResourceDisposalException(
    Iterable<AppResourceDisposalFailure> failures,
  ) {
    final values = List<AppResourceDisposalFailure>.unmodifiable(failures);
    if (values.isEmpty) {
      throw ArgumentError('Disposal failures must not be empty.');
    }

    return AppResourceDisposalException._(values);
  }

  const AppResourceDisposalException._(this.failures);

  /// Individual failures in actual disposal order.
  final List<AppResourceDisposalFailure> failures;

  @override
  String toString() =>
      'AppResourceDisposalException(${failures.length} failures)';
}
