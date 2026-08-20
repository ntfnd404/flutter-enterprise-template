import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_bloc_log_records.dart';

/// Emits privacy-safe, type-only debug breadcrumbs for BLoCs and Cubits.
///
/// This observer never reports failures or decides whether an observed failure
/// is handled. Root reporting remains the application error boundary's policy.
final class const AppBlocObserver({required AppLogger logger})
    extends BlocObserver
    with EphemeralBlocObserver {
  final _logger = logger;

  @override
  void onCreate(BlocBase<Object?> bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      _safeLog(AppBlocCreatedLogRecord(bloc.runtimeType));
    }
  }

  @override
  void onEvent(Bloc<Object?, Object?> bloc, Object? event) {
    super.onEvent(bloc, event);
    if (kDebugMode) {
      _safeLog(AppBlocEventLogRecord(bloc.runtimeType, event.runtimeType));
    }
  }

  @override
  void onChange(BlocBase<Object?> bloc, Change<Object?> change) {
    super.onChange(bloc, change);
    if (kDebugMode) {
      _safeLog(
        AppBlocStateChangedLogRecord(
          bloc.runtimeType,
          change.currentState.runtimeType,
          change.nextState.runtimeType,
        ),
      );
    }
  }

  /// Records an action transition without reading or stringifying its payload.
  @override
  void onAction(
    BlocBase<Object?> bloc,
    EphemeralBlocChange<Object?> change,
  ) {
    super.onAction(bloc, change);
    if (kDebugMode) {
      _safeLog(
        AppBlocActionLogRecord(bloc.runtimeType, change.current.runtimeType),
      );
    }
  }

  @override
  void onError(BlocBase<Object?> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      _safeLog(
        AppBlocErrorBreadcrumbLogRecord(
          bloc.runtimeType,
          error.runtimeType,
        ),
      );
    }
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onClose(BlocBase<Object?> bloc) {
    if (kDebugMode) {
      _safeLog(AppBlocClosedLogRecord(bloc.runtimeType));
    }
    super.onClose(bloc);
  }

  void _safeLog(AppLogRecord record) {
    try {
      _logger.log(record);
    } on Object {
      // Breadcrumbs are best effort and must not alter BLoC behavior.
    }
  }
}
