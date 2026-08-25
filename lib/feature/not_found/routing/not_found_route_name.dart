/// Stable system route names owned by the NotFound recovery feature.
enum NotFoundRouteName {
  /// Privacy-safe route identity used for the non-decodable fallback page.
  notFound('not-found');

  const NotFoundRouteName(this.value);

  /// Stable route value independent from Flutter page implementation.
  final String value;
}
