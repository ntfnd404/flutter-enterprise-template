/// Signals that a log record finished its synchronous field projection.
enum AppLogProjectionResult {
  /// The record wrote every field and started no asynchronous work.
  complete,
}

/// Application-owned semantic severity of an operational log record.
///
/// A record fixes this value. Callers cannot select sink levels per invocation.
enum AppLogSeverity {
  /// Normal operational information.
  info('info'),

  /// A recoverable or noteworthy operational condition.
  warning('warning'),

  /// An unexpected operational failure occurrence.
  error('error');

  const AppLogSeverity(this.wireValue);

  /// Stable value used by future support-log formats.
  final String wireValue;
}

/// Controls whether a record is local-debug-only or support-history eligible.
enum AppLogDataClass {
  /// The record is discarded before projection outside a debug build.
  debugOnly('debug_only'),

  /// The approved support projection may enter bounded local support history.
  supportSafe('support_safe');

  const AppLogDataClass(this.wireValue);

  /// Stable value used by future support-log formats.
  final String wireValue;
}

/// Stable, validated identity and policy for one log-record schema.
final class AppLogRecordDescriptor {
  /// Creates a descriptor with an explicit version, severity, and data class.
  AppLogRecordDescriptor({
    required this.eventName,
    required this.eventVersion,
    required this.severity,
    required this.dataClass,
  }) {
    if (!_eventNamePattern.hasMatch(eventName) || eventName.length > 96) {
      throw ArgumentError('App log event name is invalid.');
    }
    if (eventVersion <= 0 || eventVersion > 0x7fffffff) {
      throw ArgumentError('App log event version is invalid.');
    }
  }

  /// Stable lower-case dotted event name.
  final String eventName;

  /// Positive version of this event's observable schema.
  final int eventVersion;

  /// Semantic severity fixed by the record type.
  final AppLogSeverity severity;

  /// Local data-classification decision fixed by the record type.
  final AppLogDataClass dataClass;
}

/// A validated, low-cardinality support code with an application-owned meaning.
///
/// Syntax validation is not a PII scrubber. Production code creates values from
/// reviewed literals or explicit closed mappings, never from runtime input.
final class AppLogStableCode {
  /// Validates and creates one support code.
  factory AppLogStableCode(String value) {
    if (!_stableCodePattern.hasMatch(value) || value.length > 64) {
      throw ArgumentError('App log stable code is invalid.');
    }

    return AppLogStableCode._(value);
  }

  AppLogStableCode._(this.value);

  /// Stable ASCII value of this code.
  final String value;
}

/// Receives one synchronous, typed projection from an [AppLogRecord].
///
/// Implementing this interface does not grant access to the production logger
/// or storage. Production calls are restricted to the internal projection
/// engine; tests may use recording writers.
abstract interface class AppLogFieldWriter {
  /// Adds a debug-only runtime type.
  void debugType(String fieldName, Type value);

  /// Adds a support-safe boolean flag.
  // The positional value is part of the deliberately small projection SPI.
  // ignore: avoid_positional_boolean_parameters
  void supportFlag(String fieldName, bool value);

  /// Adds a support-safe, non-negative JSON-safe count.
  void supportCount(String fieldName, int value);

  /// Adds a support-safe, non-negative duration.
  void supportDuration(String fieldName, Duration value);

  /// Adds a reviewed, low-cardinality support code.
  void supportCode(String fieldName, AppLogStableCode value);
}

/// Base contract for an application-owned typed operational breadcrumb.
///
/// Concrete production records are final immutable subclasses in the trusted
/// outer application. This is an extension SPI, not a security sandbox.
abstract base class AppLogRecord {
  const AppLogRecord();

  /// Static schema and policy owned by the concrete record type.
  AppLogRecordDescriptor get descriptor;

  /// Writes fields synchronously and returns [AppLogProjectionResult.complete].
  AppLogProjectionResult project(AppLogFieldWriter fields);
}

final _eventNamePattern = RegExp(
  r'^[a-z][a-z0-9_]*(?:\.[a-z][a-z0-9_]*)+$',
);
final _stableCodePattern = RegExp(
  r'^[A-Z][A-Z0-9]*(?:-[A-Z0-9]+)+$',
);
