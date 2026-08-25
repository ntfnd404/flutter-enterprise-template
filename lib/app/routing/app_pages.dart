import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/routing/app_route_page_catalog.dart';
import 'package:template/app/routing/app_route_page_definition.dart';
import 'package:template/feature/activity/routing/page_composition/activity_route_page.dart';
import 'package:template/feature/catalog/routing/page_composition/catalog_route_page.dart';
import 'package:template/feature/demo/routing/page_composition/demo_route_page.dart';
import 'package:template/feature/not_found/routing/page_composition/not_found_route_page.dart';

/// Builds the application Page catalog from feature-owned contributions.
///
/// This is the only Page composition point that receives the complete
/// dependency catalog. Each feature contribution receives only its required
/// port and captures no ownership responsibility.
AppRoutePageCatalog buildAppPages({required AppDependencies dependencies}) =>
    AppRoutePageCatalog(<AppRoutePageDefinition>[
      buildDemoRoutePageDefinition(eventBus: dependencies.eventPublisher),
      buildActivityRoutePageDefinition(eventBus: dependencies.eventSubscriber),
      buildCatalogRoutePageDefinition(catalog: dependencies.catalog),
      notFoundRoutePageDefinition,
    ]);
