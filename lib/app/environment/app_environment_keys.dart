/// Canonical dart-define keys accepted by the application environment.
///
/// Runtime loading and pre-build validation share this contract so adding a
/// key cannot create independent Dart allowlists. Environment profile files,
/// build scripts, and CI still repeat the wire names by necessity and are kept
/// aligned through validation and tests.
abstract final class AppEnvironmentKeys {
  /// Selects the deployment environment.
  static const environment = 'APP_ENVIRONMENT';

  /// Selects the Flutter Web browser URL strategy.
  static const urlStrategy = 'APP_URL_STRATEGY';

  /// Every key that must be present in a complete environment profile.
  static const required = <String>{
    environment,
    urlStrategy,
  };
}
