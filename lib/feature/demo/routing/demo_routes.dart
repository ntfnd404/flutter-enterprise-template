import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/demo/routing/demo_route_name.dart';

/// Decoder contribution owned by the demo feature.
///
/// Invalid input is delegated to [onInvalidRoute], keeping the feature
/// independent from the application's concrete recovery destination.
Map<String, RouteDecoder<AppRoute>> demoRoutes({
  required AppRouteFallbackBuilder onInvalidRoute,
}) => <String, RouteDecoder<AppRoute>>{
  DemoRouteName.demo.value: (params, children) =>
      params.isEmpty && children.isEmpty
      ? const DemoRoute()
      : onInvalidRoute(AppRouteFailureReason.invalidParameters),
};
