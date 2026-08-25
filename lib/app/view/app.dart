import 'package:flutter/material.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_navigator.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_registry.dart';

/// Root application widget below the application-lifetime
/// `AppDependencyGraphOwner`.
///
/// Router delegates, controllers, and other UI-owned resources are created and
/// disposed by this widget or an appropriate flow shell, never by the
/// application dependency graph.
final class App extends StatefulWidget {
  /// Creates the root application UI.
  const App({required this.pageBuilder, super.key});

  /// Synchronous, non-owning strategy that maps typed routes to Pages.
  ///
  /// The strategy remains stable for this widget State's lifetime. Recreate
  /// [App] with a new key to install a different Page/DI composition.
  final RouteNodePageBuilder<AppRoute> pageBuilder;

  @override
  State<App> createState() => _AppState();
}

final class _AppState extends State<App> {
  late final RouteNodePageBuilder<AppRoute> _pageBuilder;
  late final RoutesState<AppRoute> _routesState;
  late final AppNavigator _navigator;
  late final RoutingDelegate<AppRoute> _routerDelegate;
  late final RoutingInformationParser<AppRoute> _routeInformationParser;

  @override
  void initState() {
    super.initState();

    // Resolve the lazy registry and codec before allocating UI-owned routing
    // resources. An authored registry failure therefore leaves nothing to
    // dispose.
    _routeInformationParser = RoutingInformationParser<AppRoute>(
      appRouteUrlCodec,
    );
    _pageBuilder = widget.pageBuilder;
    _routesState = RoutesState<AppRoute>(initialAppRoutes, normalizeAppStack);
    _navigator = AppNavigator(_routesState);
    _routerDelegate = RoutingDelegate<AppRoute>(
      _routesState,
      pageBuilder: _pageBuilder,
    );
  }

  @override
  void dispose() {
    _routerDelegate.dispose();
    _routesState.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pageBuilder != _pageBuilder) {
      throw StateError(
        'App does not support replacing its Page-building strategy.',
      );
    }

    return NavigatorScope<AppNavigator>(
      navigator: _navigator,
      child: MaterialApp.router(
        title: 'Template',
        restorationScopeId: 'template-navigation',
        routerDelegate: _routerDelegate,
        routeInformationParser: _routeInformationParser,
      ),
    );
  }
}
