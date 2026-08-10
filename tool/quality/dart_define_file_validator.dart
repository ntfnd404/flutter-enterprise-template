import 'package:template/app/environment/app_configuration_exception.dart';
import 'package:template/app/environment/app_environment_keys.dart';
import 'package:template/app/environment/app_startup_configuration.dart';

/// Validates tracked `--dart-define-from-file` profiles before Flutter starts.
///
/// The parser uses a closed allowlist and never renders rejected values. This
/// protects CI logs from accidental credentials even though secrets must never
/// be placed in client dart-defines in the first place. CI/CD must validate the
/// exact file later passed to Flutter, for example with
/// `make check-env ENV_FILE=env/prod.env`.
final class DartDefineFileValidator {
  /// Creates the stateless configuration validator.
  const DartDefineFileValidator();

  /// Parses [contents] and validates the same environment contract as runtime.
  void validate(String contents) {
    final values = _parse(contents);
    _validateKeys(values.keys.toSet());

    try {
      AppStartupConfiguration.fromValues(
        environment: _required(
          values,
          AppEnvironmentKeys.environment,
        ),
        urlStrategy: _required(
          values,
          AppEnvironmentKeys.urlStrategy,
        ),
        storageNamespace: _required(
          values,
          AppEnvironmentKeys.storageNamespace,
        ),
      );
    } on AppConfigurationException {
      throw const DartDefineValidationException(
        'Dart-define values violate the application environment contract.',
      );
    }
  }

  Map<String, String> _parse(String contents) {
    final values = <String, String>{};
    final lines = contents.split('\n');

    for (var index = 0; index < lines.length; index++) {
      final rawLine = lines[index];
      final line = rawLine.endsWith('\r')
          ? rawLine.substring(0, rawLine.length - 1)
          : rawLine;
      final normalized = line.trim();
      if (normalized.isEmpty || normalized.startsWith('#')) {
        continue;
      }
      if (line != normalized) {
        throw DartDefineValidationException(
          'Invalid configuration syntax at line ${index + 1}.',
        );
      }

      final separator = line.indexOf('=');
      if (separator <= 0) {
        throw DartDefineValidationException(
          'Invalid configuration syntax at line ${index + 1}.',
        );
      }

      final key = line.substring(0, separator);
      final value = line.substring(separator + 1);
      if (key != key.trim() || value != value.trim()) {
        throw DartDefineValidationException(
          'Invalid configuration syntax at line ${index + 1}.',
        );
      }
      if (!RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(key)) {
        // Never echo malformed key text: it can contain terminal control codes.
        throw DartDefineValidationException(
          'Invalid configuration key at line ${index + 1}.',
        );
      }
      if (!AppEnvironmentKeys.required.contains(key)) {
        throw DartDefineValidationException(
          'Unsupported dart-define key: $key.',
        );
      }
      if (values.containsKey(key)) {
        throw DartDefineValidationException('Duplicate dart-define key: $key.');
      }
      if (value.isEmpty) {
        throw DartDefineValidationException(
          'Empty dart-define value for key: $key.',
        );
      }
      values[key] = value;
    }

    return values;
  }

  void _validateKeys(Set<String> actual) {
    final missing = AppEnvironmentKeys.required.difference(actual);
    if (missing.isNotEmpty) {
      throw DartDefineValidationException(
        'Missing required dart-define key: ${missing.first}.',
      );
    }
  }

  String _required(Map<String, String> values, String key) {
    final value = values[key];
    if (value == null) {
      throw DartDefineValidationException(
        'Missing required dart-define key: $key.',
      );
    }

    return value;
  }
}

/// A safe validation failure suitable for command-line output.
final class DartDefineValidationException implements Exception {
  /// Creates a validation failure with an already-sanitized [message].
  const DartDefineValidationException(this.message);

  /// Human-readable text that never includes rejected values.
  final String message;

  @override
  String toString() => message;
}
