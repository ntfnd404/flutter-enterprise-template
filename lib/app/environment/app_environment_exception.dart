import 'package:template/app/environment/app_configuration_exception.dart';

/// Describes an expected application-environment contract violation.
///
/// Messages must identify the key and expected format without embedding the
/// rejected value, credentials, URL user info, or query parameters. Business
/// contexts own their own configuration exceptions rather than reusing this
/// app-startup exception as a global error hierarchy.
final class AppEnvironmentException extends AppConfigurationException {
  /// Creates an environment failure with an already-sanitized [message].
  const AppEnvironmentException(super.message);

  @override
  String toString() => 'AppEnvironmentException: $message';
}
