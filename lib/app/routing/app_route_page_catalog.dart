import 'package:flutter/widgets.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_page_definition.dart';

/// Composes feature-owned definitions into one synchronous Page strategy.
///
/// Dispatch uses exact runtime types, never URL route values. Duplicate types are
/// rejected during composition; a missing definition fails safely when that
/// route is first rendered.
final class AppRoutePageCatalog {
  /// Creates an immutable catalog from [definitions].
  AppRoutePageCatalog(Iterable<AppRoutePageDefinition> definitions)
    : _definitions = _index(definitions);

  final Map<Type, AppRoutePageDefinition> _definitions;

  /// Builds the Page for [route] and supplies this catalog recursively.
  Page<Object?> build(BuildContext context, AppRoute route) {
    final definition = _definitions[route.runtimeType];
    if (definition == null) {
      throw StateError('No Page definition is registered for the route type.');
    }

    return definition.build(context, route, build);
  }

  static Map<Type, AppRoutePageDefinition> _index(
    Iterable<AppRoutePageDefinition> definitions,
  ) {
    final indexed = <Type, AppRoutePageDefinition>{};
    for (final definition in definitions) {
      if (indexed.containsKey(definition.routeType)) {
        throw StateError(
          'More than one Page definition handles the same route type.',
        );
      }
      indexed[definition.routeType] = definition;
    }

    return Map<Type, AppRoutePageDefinition>.unmodifiable(indexed);
  }
}
