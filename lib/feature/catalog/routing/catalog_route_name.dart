/// Stable names owned by catalog routing.
enum CatalogRouteName {
  /// Catalog list route.
  catalog('catalog');

  const CatalogRouteName(this.value);

  /// Stable URL segment and registry key.
  final String value;
}
