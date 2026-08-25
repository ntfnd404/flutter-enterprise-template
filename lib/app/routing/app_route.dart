import 'package:rolter/rolter.dart';

/// Stable routing SPI implemented by application features.
///
/// The class is intentionally not sealed because concrete routes live in
/// separate feature libraries. These defaults are for leaf routes; future
/// nested or shell routes must override [children], [withChildren], and any
/// equality affected by their child tree.
abstract base class AppRoute with KeyedRouteEquality implements RouteNode {
  /// Creates an application route.
  const AppRoute();

  @override
  List<AppRoute> get children => const <AppRoute>[];

  @override
  AppRoute withChildren(List<RouteNode> children) => this;
}
