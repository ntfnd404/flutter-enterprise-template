import 'package:template/app/environment/app_configuration_exception.dart';

/// Stable reasons why an application storage namespace is invalid.
enum AppStorageNamespaceFailure {
  /// The namespace is empty.
  empty,

  /// The namespace is longer than the supported persistent-identity limit.
  tooLong,

  /// The namespace is not canonical lowercase snake case.
  nonCanonical,
}

/// Sanitized failure produced while validating a storage namespace.
final class AppStorageNamespaceException extends AppConfigurationException {
  /// Creates a failure without retaining the rejected namespace.
  const AppStorageNamespaceException(this.failure)
    : super(
        'Invalid application storage namespace. Expected lowercase snake case '
        'with at most 32 characters.',
      );

  /// Stable, privacy-safe failure classification.
  final AppStorageNamespaceFailure failure;

  @override
  String toString() => 'AppStorageNamespaceException(${failure.name})';
}
