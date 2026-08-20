import 'package:template/app/diagnostics/logging/app_log_record.dart';

/// Debug breadcrumb for a newly created BLoC or Cubit.
final class AppBlocCreatedLogRecord extends AppLogRecord {
  /// Creates a record for [componentType].
  const AppBlocCreatedLogRecord(this.componentType);

  /// Runtime component type, used only in debug output.
  final Type componentType;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.bloc.created',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.debugOnly,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields.debugType('component_type', componentType);

    return AppLogProjectionResult.complete;
  }
}

/// Debug breadcrumb for an event received by a BLoC.
final class AppBlocEventLogRecord extends AppLogRecord {
  /// Creates a record for [componentType] and [eventType].
  const AppBlocEventLogRecord(this.componentType, this.eventType);

  /// Runtime component type, used only in debug output.
  final Type componentType;

  /// Runtime event type, used only in debug output.
  final Type eventType;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.bloc.event',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.debugOnly,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields
      ..debugType('component_type', componentType)
      ..debugType('event_type', eventType);

    return AppLogProjectionResult.complete;
  }
}

/// Debug breadcrumb for one BLoC or Cubit state change.
final class AppBlocStateChangedLogRecord extends AppLogRecord {
  /// Creates a record for one component state change.
  const AppBlocStateChangedLogRecord(
    this.componentType,
    this.previousStateType,
    this.nextStateType,
  );

  /// Runtime component type, used only in debug output.
  final Type componentType;

  /// Runtime previous-state type, used only in debug output.
  final Type previousStateType;

  /// Runtime next-state type, used only in debug output.
  final Type nextStateType;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.bloc.state_changed',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.debugOnly,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields
      ..debugType('component_type', componentType)
      ..debugType('previous_state_type', previousStateType)
      ..debugType('next_state_type', nextStateType);

    return AppLogProjectionResult.complete;
  }
}

/// Debug breadcrumb for one ephemeral BLoC action.
final class AppBlocActionLogRecord extends AppLogRecord {
  /// Creates a record for [componentType] and [actionType].
  const AppBlocActionLogRecord(this.componentType, this.actionType);

  /// Runtime component type, used only in debug output.
  final Type componentType;

  /// Runtime action type, used only in debug output.
  final Type actionType;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.bloc.action',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.debugOnly,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields
      ..debugType('component_type', componentType)
      ..debugType('action_type', actionType);

    return AppLogProjectionResult.complete;
  }
}

/// Debug breadcrumb for an error observed by a BLoC or Cubit.
final class AppBlocErrorBreadcrumbLogRecord extends AppLogRecord {
  /// Creates a record for [componentType] and [errorType].
  const AppBlocErrorBreadcrumbLogRecord(this.componentType, this.errorType);

  /// Runtime component type, used only in debug output.
  final Type componentType;

  /// Runtime error type, used only in debug output.
  final Type errorType;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.bloc.error_breadcrumb',
    eventVersion: 1,
    severity: AppLogSeverity.warning,
    dataClass: AppLogDataClass.debugOnly,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields
      ..debugType('component_type', componentType)
      ..debugType('error_type', errorType);

    return AppLogProjectionResult.complete;
  }
}

/// Debug breadcrumb for a closed BLoC or Cubit.
final class AppBlocClosedLogRecord extends AppLogRecord {
  /// Creates a record for [componentType].
  const AppBlocClosedLogRecord(this.componentType);

  /// Runtime component type, used only in debug output.
  final Type componentType;

  /// Stable schema for this record type.
  static final AppLogRecordDescriptor recordDescriptor = AppLogRecordDescriptor(
    eventName: 'app.bloc.closed',
    eventVersion: 1,
    severity: AppLogSeverity.info,
    dataClass: AppLogDataClass.debugOnly,
  );

  @override
  AppLogRecordDescriptor get descriptor => recordDescriptor;

  @override
  AppLogProjectionResult project(AppLogFieldWriter fields) {
    fields.debugType('component_type', componentType);

    return AppLogProjectionResult.complete;
  }
}
