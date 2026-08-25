import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';

/// Builds one typed application route Page.
///
/// [nestedPageBuilder] is the complete application catalog. A shell Page must
/// pass it to every nested navigator that renders the route's children.
typedef AppRoutePageFactory<R extends AppRoute> = Page<Object?> Function(
  BuildContext context,
  R route,
  RouteNodePageBuilder<AppRoute> nestedPageBuilder,
);

/// Type-erased Page contribution owned by one application feature.
abstract interface class AppRoutePageDefinition {
  /// Exact concrete route type handled by this definition.
  Type get routeType;

  /// Builds a Page for [route] with the complete nested Page strategy.
  Page<Object?> build(
    BuildContext context,
    AppRoute route,
    RouteNodePageBuilder<AppRoute> nestedPageBuilder,
  );
}

/// Adapts a typed feature Page factory to [AppRoutePageDefinition].
final class TypedAppRoutePageDefinition<R extends AppRoute>
    implements AppRoutePageDefinition {
  /// Creates a definition backed by [pageFactory].
  const TypedAppRoutePageDefinition({required this.pageFactory});

  /// Typed Page factory implemented by the owning feature.
  final AppRoutePageFactory<R> pageFactory;

  @override
  Type get routeType => R;

  @override
  Page<Object?> build(
    BuildContext context,
    AppRoute route,
    RouteNodePageBuilder<AppRoute> nestedPageBuilder,
  ) {
    if (route is! R) {
      throw StateError(
        'A Page definition received an incompatible route type.',
      );
    }

    return pageFactory(context, route, nestedPageBuilder);
  }
}
