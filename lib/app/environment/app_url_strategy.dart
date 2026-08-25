/// Selects how Flutter Web represents application routes in browser URLs.
///
/// This deployment policy is independent of the future application-routing
/// implementation. Replacing a router does not change the hash-versus-path
/// hosting contract.
enum AppUrlStrategy {
  /// Keeps the default hash-based URL format.
  hash,

  /// Uses path-based URLs and therefore requires server-side fallback routing.
  path,
}
