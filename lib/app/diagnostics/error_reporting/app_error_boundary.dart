import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_error_log_records.dart';

/// Owns error routing for the root Flutter application isolate.
///
/// The boundary installs the guarded application Zone and the Flutter and
/// platform handlers. It does not automatically capture failures raised before
/// [run], though callers may submit them explicitly through [report]. It does
/// not cover child isolates or failures that terminate the VM or process before
/// a handler can run.
/// Creates a boundary backed by borrowed [reporter] and [logger] policies.
final class AppErrorBoundary({
  required AppErrorReporter reporter,
  required AppLogger logger,
  bool reportSilentFlutterErrors = kDebugMode,
}) {
  static AppErrorBoundary? _activeBoundary;

  // Per-boundary identities preserve reentry markers across nested boundaries.
  final _loggerZoneMarkerKey = Object();
  final _reporterZoneMarkerKey = Object();
  final _reporter = reporter;
  final _logger = logger;
  final _reportSilentFlutterErrors = reportSilentFlutterErrors;

  _AppErrorBoundaryState _state = _AppErrorBoundaryState.created;
  Zone? _runCallerZone;
  FlutterExceptionHandler? _previousFlutterHandler;
  FlutterExceptionHandler? _installedFlutterHandler;
  ErrorCallback? _previousPlatformHandler;
  ErrorCallback? _installedPlatformHandler;

  /// Runs [body] in the guarded root application Zone.
  ///
  /// Flutter binding initialization and `runApp` must both happen from [body].
  /// The callback's Future is deliberately not returned across the error-Zone
  /// boundary; asynchronous failures are routed to this boundary instead.
  void run(Future<void> Function() body) {
    _ensureCanRun();
    _acquireActiveLease();
    _runCallerZone = Zone.current;
    _state = _AppErrorBoundaryState.active;

    Object? installationError;
    StackTrace? installationStackTrace;
    var installationFailed = false;

    runZonedGuarded<void>(
      () {
        try {
          _installGlobalHandlers();
        } catch (error, stackTrace) {
          installationFailed = true;
          installationError = error;
          installationStackTrace = stackTrace;

          return;
        }

        unawaited(body());
      },
      _onRootZoneError,
    );

    if (!installationFailed) {
      return;
    }

    _terminateAfterInstallationFailure();
    Error.throwWithStackTrace(installationError!, installationStackTrace!);
  }

  /// Reports [error] without allowing reporter failures to escape.
  ///
  /// A direct call is permitted before or during [run] and does not acquire the
  /// global-handler lease. After [dispose], callers must not deliberately start
  /// new reports; an unavoidable late callback remains best-effort and
  /// no-throw, without a delivery guarantee.
  ///
  /// [stackTrace] remains nullable so a framework failure without a supplied
  /// stack is not given a fabricated trace. Independent calls may run
  /// concurrently; no ordering, retry, or delivery guarantee is provided.
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) async {
    if (identical(Zone.current[_loggerZoneMarkerKey], this)) {
      return;
    }

    final inheritedInvocation =
        Zone.current[_reporterZoneMarkerKey] as _AppErrorReportingInvocation?;
    if (identical(inheritedInvocation?.boundary, this)) {
      _logReporterFailureOnce(inheritedInvocation!);

      return;
    }

    final invocation = _AppErrorReportingInvocation(this);
    _safeLog(() => AppErrorReportedLogRecord(kind.supportCode));
    try {
      await runZoned<Future<void>>(
        () => _reporter.report(
          error,
          stackTrace,
          kind: kind,
        ),
        zoneValues: {_reporterZoneMarkerKey: invocation},
      );
    } on Object {
      _logReporterFailureOnce(invocation);
    }
  }

  /// Restores handlers still owned by this boundary and releases its lease.
  ///
  /// Production keeps the boundary alive for the root-isolate lifetime. Tests
  /// and controlled teardown must call this method only after their work is
  /// quiescent: disposal neither cancels the root Zone nor awaits reports that
  /// are already in flight.
  void dispose() {
    if (_state == _AppErrorBoundaryState.disposed) {
      return;
    }

    if (_state == _AppErrorBoundaryState.created) {
      _state = _AppErrorBoundaryState.disposed;

      return;
    }

    try {
      _restoreFlutterHandlerIfOwned();
    } finally {
      try {
        _restorePlatformHandlerIfOwned();
      } finally {
        _releaseActiveLease();
        _clearHandlerReferences();
        _state = _AppErrorBoundaryState.disposed;
      }
    }
  }

  void _ensureCanRun() {
    switch (_state) {
      case _AppErrorBoundaryState.created:
        return;
      case _AppErrorBoundaryState.active:
        throw StateError('AppErrorBoundary can run only once.');
      case _AppErrorBoundaryState.disposed:
        throw StateError('A disposed AppErrorBoundary cannot run.');
    }
  }

  void _acquireActiveLease() {
    if (_activeBoundary != null) {
      throw StateError('Another AppErrorBoundary is already active.');
    }
    _activeBoundary = this;
  }

  void _installGlobalHandlers() {
    _previousFlutterHandler = FlutterError.onError;
    _previousPlatformHandler = PlatformDispatcher.instance.onError;
    _installedFlutterHandler = _handleFlutterError;
    _installedPlatformHandler = _handlePlatformError;

    FlutterError.onError = _installedFlutterHandler;
    PlatformDispatcher.instance.onError = _installedPlatformHandler;
  }

  void _handleFlutterError(FlutterErrorDetails details) {
    if (details.silent && !_reportSilentFlutterErrors) {
      return;
    }

    unawaited(
      report(
        details.exception,
        details.stack,
        kind: AppErrorReportKind.flutterFramework,
      ),
    );
  }

  bool _handlePlatformError(Object error, StackTrace stackTrace) {
    unawaited(
      report(
        error,
        stackTrace,
        kind: AppErrorReportKind.platformDispatcher,
      ),
    );

    return true;
  }

  void _onRootZoneError(Object error, StackTrace stackTrace) {
    unawaited(
      report(
        error,
        stackTrace,
        kind: AppErrorReportKind.rootZone,
      ),
    );
  }

  void _logReporterFailureOnce(_AppErrorReportingInvocation invocation) {
    if (invocation.hasLoggedFailure) {
      return;
    }
    invocation.hasLoggedFailure = true;
    _safeLog(() => const AppErrorReporterFailureLogRecord());
  }

  void _safeLog(AppLogRecord Function() createRecord) {
    runZonedGuarded<void>(
      () => _logger.log(createRecord()),
      (_, _) {
        // A logging failure is terminal for this breadcrumb. Reporting it
        // would recurse and could replace the primary failure.
      },
      zoneValues: {_loggerZoneMarkerKey: this},
    );
  }

  void _restoreFlutterHandlerIfOwned() {
    if (identical(FlutterError.onError, _installedFlutterHandler)) {
      FlutterError.onError = _previousFlutterHandler;
    }
  }

  void _restorePlatformHandlerIfOwned() {
    final callerZone = _runCallerZone;
    if (callerZone == null) {
      return;
    }

    callerZone.run<void>(() {
      if (identical(
        PlatformDispatcher.instance.onError,
        _installedPlatformHandler,
      )) {
        PlatformDispatcher.instance.onError = _previousPlatformHandler;
      }
    });
  }

  void _terminateAfterInstallationFailure() {
    try {
      _restoreFlutterHandlerIfOwned();
    } on Object {
      // Installation cannot establish a usable reporting boundary. Preserve
      // its primary failure while still attempting the remaining rollback.
    }

    try {
      _restorePlatformHandlerIfOwned();
    } on Object {
      // The primary installation failure retains precedence.
    } finally {
      _releaseActiveLease();
      _clearHandlerReferences();
      _state = _AppErrorBoundaryState.disposed;
    }
  }

  void _releaseActiveLease() {
    if (identical(_activeBoundary, this)) {
      _activeBoundary = null;
    }
  }

  void _clearHandlerReferences() {
    _runCallerZone = null;
    _previousFlutterHandler = null;
    _installedFlutterHandler = null;
    _previousPlatformHandler = null;
    _installedPlatformHandler = null;
  }
}

enum _AppErrorBoundaryState { created, active, disposed }

final class _AppErrorReportingInvocation {
  _AppErrorReportingInvocation(this.boundary);

  final AppErrorBoundary boundary;
  bool hasLoggedFailure = false;
}
