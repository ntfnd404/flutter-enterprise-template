import 'package:flutter/material.dart';
import 'package:template/app/routing/app_route_page_definition.dart';
import 'package:template/core/event_bus/app_event_subscriber.dart';
import 'package:template/feature/activity/di/activity_scope.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/activity/view/activity_screen.dart';

/// Creates the Activity feature's typed route Page contribution.
AppRoutePageDefinition buildActivityRoutePageDefinition({
  required AppEventSubscriber eventBus,
}) => TypedAppRoutePageDefinition<ActivityRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<void>(
    key: route.pageKey,
    name: route.name,
    child: ActivityScope(
      eventBus: eventBus,
      child: ActivityScreen(highlightSequence: route.sequence),
    ),
  ),
);
