/// Identifies the deployment environment selected at application startup.
///
/// This type is the deployment discriminator within the `AppEnvironment`
/// aggregate, not the complete application configuration. Missing and unknown
/// values are rejected instead of silently falling back to a development
/// environment.
///
/// Integration tests use a regular runtime environment (normally [local])
/// rather than introducing test-only branches into production code.
enum AppEnvironmentKind {
  /// Local development against services running on the developer machine.
  local,

  /// Shared development infrastructure.
  dev,

  /// Production infrastructure.
  prod,
}
