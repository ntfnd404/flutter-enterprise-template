import 'package:flutter/foundation.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/feature/catalog/routing/catalog_route_name.dart';

/// Data-only destination for catalog presentation.
final class CatalogRoute extends AppRoute {
  /// Creates the catalog route.
  const CatalogRoute();

  @override
  LocalKey get pageKey => ValueKey<String>(CatalogRouteName.catalog.value);

  @override
  String get name => CatalogRouteName.catalog.value;

  @override
  Map<String, String> toParams() => const <String, String>{};
}
