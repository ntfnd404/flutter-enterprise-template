import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/activity_navigation.dart';
import 'package:template/app/routing/app_navigator.dart';
import 'package:template/app/routing/catalog_navigation.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';

/// Narrow navigation roles assembled over the UI-owned [AppNavigator].
extension AppNavigatorContext on BuildContext {
  /// Resolves the narrow Activity navigation capability.
  ActivityNavigation get activityNavigation =>
      _ActivityNavigationAdapter(NavigatorScope.of<AppNavigator>(this));

  /// Resolves the narrow Catalog navigation capability.
  CatalogNavigation get catalogNavigation =>
      _CatalogNavigationAdapter(NavigatorScope.of<AppNavigator>(this));
}

final class _ActivityNavigationAdapter implements ActivityNavigation {
  const _ActivityNavigationAdapter(this._navigator);

  final AppNavigator _navigator;

  @override
  void openActivity({required int sequence}) =>
      _navigator.push(ActivityRoute(sequence: sequence));
}

final class _CatalogNavigationAdapter implements CatalogNavigation {
  const _CatalogNavigationAdapter(this._navigator);

  final AppNavigator _navigator;

  @override
  void openCatalog() => _navigator.push(const CatalogRoute());
}
