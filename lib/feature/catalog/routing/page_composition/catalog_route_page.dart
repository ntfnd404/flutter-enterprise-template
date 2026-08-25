import 'package:catalog/catalog.dart';
import 'package:flutter/material.dart';
import 'package:template/app/routing/app_route_page_definition.dart';
import 'package:template/feature/catalog/di/catalog_scope.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';
import 'package:template/feature/catalog/view/catalog_screen.dart';

/// Creates the catalog feature's dependency-aware Page contribution.
AppRoutePageDefinition buildCatalogRoutePageDefinition({
  required CatalogFacade catalog,
}) => TypedAppRoutePageDefinition<CatalogRoute>(
  pageFactory: (context, route, nestedPageBuilder) => MaterialPage<void>(
    key: route.pageKey,
    name: route.name,
    child: CatalogScope(
      catalog: catalog,
      child: const CatalogScreen(),
    ),
  ),
);
