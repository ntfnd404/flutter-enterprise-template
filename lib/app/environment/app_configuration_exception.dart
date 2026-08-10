/// Base contract for sanitized app-owned compile-time configuration failures.
///
/// Application startup and pre-build validation catch this type without
/// erasing the more specific failure exposed by an app-owned configuration.
/// Business packages retain their own exception contracts instead of importing
/// this application-layer type.
abstract base class AppConfigurationException implements Exception {
  /// Creates a configuration failure with an already-sanitized [message].
  const AppConfigurationException(this.message);

  /// A safe diagnostic description that never includes the rejected value.
  final String message;

  @override
  String toString() => 'AppConfigurationException: $message';
}
