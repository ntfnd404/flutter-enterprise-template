import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/app/routing/app_route_url_codec.dart';
import 'package:template/feature/activity/routing/activity_routes.dart';
import 'package:template/feature/catalog/routing/catalog_routes.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/demo/routing/demo_routes.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';

AppRoute _buildFallback(AppRouteFailureReason reason) =>
    NotFoundRoute(reason: reason);

/// Application route registry assembled from feature-owned decoder maps.
///
/// This is the application composition point for feature decoder
/// contributions. Page/DI composition remains separate in `app_pages.dart`,
/// while the routing engine stays unaware of application screens.
final RouteRegistry<AppRoute> appRouteRegistry = RouteRegistry<AppRoute>(
  composeAppRouteDecoders(<Map<String, RouteDecoder<AppRoute>>>[
    demoRoutes(onInvalidRoute: _buildFallback),
    activityRoutes(onInvalidRoute: _buildFallback),
    catalogRoutes(onInvalidRoute: _buildFallback),
  ]),
  fallback: (_) => _buildFallback(AppRouteFailureReason.unknownRoute),
);

/// Application URL codec with bounded external-input recovery policy.
///
/// [TreeUrlCodec] owns the wire grammar. [AppRouteUrlCodec] validates the
/// decoded tree before it reaches mutable router state.
final RouteUrlCodec<AppRoute> appRouteUrlCodec = AppRouteUrlCodec(
  TreeUrlCodec<AppRoute>(appRouteRegistry),
);

/// Merges decoder contributions without allowing Dart map overwrites.
///
/// The returned map is immutable. An authored duplicate fails before the
/// router is attached and does not expose URL parameters or attempted input.
Map<String, RouteDecoder<AppRoute>> composeAppRouteDecoders(
  Iterable<Map<String, RouteDecoder<AppRoute>>> contributions,
) {
  final decoders = <String, RouteDecoder<AppRoute>>{};
  for (final contribution in contributions) {
    for (final entry in contribution.entries) {
      if (decoders.containsKey(entry.key)) {
        throw StateError(
          'More than one route decoder uses the same route value.',
        );
      }
      decoders[entry.key] = entry.value;
    }
  }

  return Map<String, RouteDecoder<AppRoute>>.unmodifiable(decoders);
}

/// Initial route stack used by the application shell.
///
/// Keeping this policy beside the registry prevents the root `App` widget from
/// importing a concrete feature route solely to start navigation.
List<AppRoute> get initialAppRoutes => const <AppRoute>[DemoRoute()];

/// Ensures the demo landing page remains below every deep-linked destination.
List<AppRoute> normalizeAppStack(List<AppRoute> requested) {
  if (requested.isEmpty) {
    return initialAppRoutes;
  }
  if (requested.first is DemoRoute) {
    return requested;
  }

  return <AppRoute>[const DemoRoute(), ...requested];
}
