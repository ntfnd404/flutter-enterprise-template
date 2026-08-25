import 'package:flutter/material.dart';
import 'package:template/app/routing/app_route_page_definition.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';
import 'package:template/feature/demo/di/demo_scope.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/demo/view/demo_screen.dart';

/// Creates the Demo feature's typed route Page contribution.
AppRoutePageDefinition buildDemoRoutePageDefinition({
  required AppEventPublisher eventBus,
}) => TypedAppRoutePageDefinition<DemoRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<void>(
    key: route.pageKey,
    name: route.name,
    child: DemoScope(
      eventBus: eventBus,
      child: const DemoScreen(),
    ),
  ),
);
