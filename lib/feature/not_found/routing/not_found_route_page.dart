import 'package:flutter/material.dart';
import 'package:template/app/routing/app_route_page_definition.dart';
import 'package:template/feature/not_found/di/not_found_scope.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';
import 'package:template/feature/not_found/view/not_found_screen.dart';

/// NotFound feature route Page contribution for normal-graph recovery.
final AppRoutePageDefinition notFoundRoutePageDefinition =
    TypedAppRoutePageDefinition<NotFoundRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<void>(
        key: route.pageKey,
        name: route.name,
        child: NotFoundScope(
          reason: route.reason,
          child: const NotFoundScreen(),
        ),
      ),
    );
