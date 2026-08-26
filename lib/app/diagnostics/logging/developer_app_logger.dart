import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';

/// Writes validated records through `dart:developer`.
final class DeveloperAppLogger implements AppLogger {
  /// Creates the production developer logger.
  factory DeveloperAppLogger() => DeveloperAppLogger._(
    sink: _writeDeveloperLog,
    includeDebugRecords: true,
  );

  DeveloperAppLogger._({
    required this._sink,
    required bool includeDebugRecords,
  }) : _includeDebugRecords = kDebugMode && includeDebugRecords;

  /// Creates a deterministic logger whose debug policy can only be reduced.
  @visibleForTesting
  factory DeveloperAppLogger.withSink({
    required void Function(String message, int level) sink,
    bool includeDebugRecords = true,
  }) => DeveloperAppLogger._(
    sink: sink,
    includeDebugRecords: includeDebugRecords,
  );

  final _AppDeveloperLogSink _sink;
  final bool _includeDebugRecords;

  @override
  void log(AppLogRecord record) {
    try {
      final descriptor = record.descriptor;
      if (descriptor.dataClass == AppLogDataClass.debugOnly &&
          !_includeDebugRecords) {
        return;
      }

      final collector = _AppLogFieldCollector(
        includeDebugFields: _includeDebugRecords,
      );
      _AppLogProjection? projection;
      try {
        final result = record.project(collector);
        if (result != AppLogProjectionResult.complete || collector.isInvalid) {
          return;
        }
        projection = collector.snapshot(descriptor);
      } finally {
        collector.seal();
      }

      _sink(
        _formatProjection(projection),
        _developerLevel(descriptor.severity),
      );
    } on Object {
      // Operational breadcrumbs must never disrupt the application flow.
    }
  }
}

typedef _AppDeveloperLogSink = void Function(String message, int level);

final class _AppLogProjection {
  const _AppLogProjection(this.descriptor, this.fields);

  final AppLogRecordDescriptor descriptor;
  final List<_AppProjectedField> fields;
}

final class _AppProjectedField {
  const _AppProjectedField(this.name, this.value);

  final String name;
  final Object value;
}

final class _AppLogFieldCollector implements AppLogFieldWriter {
  _AppLogFieldCollector({required this._includeDebugFields});

  static const _maxFields = 32;
  static const _maxJsonSafeInteger = 9007199254740991;
  static final _fieldNamePattern = RegExp(r'^[a-z][a-z0-9_]*$');

  final bool _includeDebugFields;
  List<_AppProjectedField>? _fields = [];
  Set<String>? _fieldNames = <String>{};
  bool _invalid = false;

  bool get isInvalid => _invalid;

  @override
  void debugType(String fieldName, Type value) {
    _write(fieldName, value, retainValue: _includeDebugFields);
  }

  @override
  void supportCode(String fieldName, AppLogStableCode value) {
    _write(fieldName, value);
  }

  @override
  void supportCount(String fieldName, int value) {
    if (_fields == null) {
      return;
    }
    if (value < 0 || value > _maxJsonSafeInteger) {
      _invalid = true;

      return;
    }
    _write(fieldName, value);
  }

  @override
  void supportDuration(String fieldName, Duration value) {
    if (_fields == null) {
      return;
    }
    final microseconds = value.inMicroseconds;
    if (microseconds < 0 || microseconds > _maxJsonSafeInteger) {
      _invalid = true;

      return;
    }
    _write(fieldName, value);
  }

  @override
  // The positional value is fixed by AppLogFieldWriter's narrow SPI.
  // ignore: avoid_positional_boolean_parameters
  void supportFlag(String fieldName, bool value) {
    _write(fieldName, value);
  }

  _AppLogProjection snapshot(AppLogRecordDescriptor descriptor) {
    final fields = _fields;
    if (fields == null || _invalid) {
      throw StateError('App log projection is unavailable.');
    }

    return _AppLogProjection(
      descriptor,
      List<_AppProjectedField>.unmodifiable(fields),
    );
  }

  void seal() {
    _fields?.clear();
    _fieldNames?.clear();
    _fields = null;
    _fieldNames = null;
  }

  void _write(
    String fieldName,
    Object value, {
    bool retainValue = true,
  }) {
    final fields = _fields;
    final fieldNames = _fieldNames;
    if (fields == null || fieldNames == null || _invalid) {
      return;
    }
    if (!_fieldNamePattern.hasMatch(fieldName) || fieldName.length > 48) {
      _invalid = true;

      return;
    }
    if (!fieldNames.add(fieldName) || fieldNames.length > _maxFields) {
      _invalid = true;

      return;
    }
    if (retainValue) {
      fields.add(_AppProjectedField(fieldName, value));
    }
  }
}

int _developerLevel(AppLogSeverity severity) => switch (severity) {
  AppLogSeverity.info => 800,
  AppLogSeverity.warning => 900,
  AppLogSeverity.error => 1000,
};

String _formatProjection(_AppLogProjection projection) {
  final fields = [
    projection.descriptor.eventName,
    'event_version=${projection.descriptor.eventVersion}',
    'severity=${projection.descriptor.severity.wireValue}',
    for (final field in projection.fields)
      '${field.name}=${_formatFieldValue(field.value)}',
  ];

  return fields.join(' ');
}

String _formatFieldValue(Object value) => switch (value) {
  final AppLogStableCode code => code.value,
  final Duration duration => duration.inMicroseconds.toString(),
  final Type type => type.toString(),
  final bool flag => flag ? 'true' : 'false',
  final int count => count.toString(),
  _ => throw StateError('Unsupported app log field type.'),
};

void _writeDeveloperLog(String message, int level) {
  developer.log(message, name: 'Application', level: level);
}
