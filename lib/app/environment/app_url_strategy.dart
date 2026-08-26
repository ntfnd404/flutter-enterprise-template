/// Selects how Flutter Web represents application routes in browser URLs.
///
/// This is a Flutter Web deployment policy independent of Rolter, `go_router`,
/// or any other routing engine. Replacing the application router does not
/// change the hash-versus-path hosting contract.
enum AppUrlStrategy {
  /// Keeps the default hash-based URL format.
  hash,

  /// Uses path-based URLs and therefore requires server-side fallback routing.
  path,
}
