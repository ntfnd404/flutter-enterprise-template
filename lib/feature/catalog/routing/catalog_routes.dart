import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';
import 'package:template/feature/catalog/routing/catalog_route_name.dart';

/// Decoder contribution owned by catalog presentation.
Map<String, RouteDecoder<AppRoute>> catalogRoutes({
  required AppRouteFallbackBuilder onInvalidRoute,
}) => <String, RouteDecoder<AppRoute>>{
  CatalogRouteName.catalog.value: (params, children) =>
      params.isEmpty && children.isEmpty
      ? const CatalogRoute()
      : onInvalidRoute(AppRouteFailureReason.invalidParameters),
};
