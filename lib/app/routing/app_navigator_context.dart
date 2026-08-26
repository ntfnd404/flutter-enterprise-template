import 'package:flutter/widgets.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/activity_navigation.dart';
import 'package:template/app/routing/app_navigator.dart';
import 'package:template/app/routing/catalog_navigation.dart';

/// Typed access to the UI-owned [AppNavigator].
extension AppNavigatorContext on BuildContext {
  /// Resolves the navigator without subscribing to changes.
  AppNavigator get navigator => NavigatorScope.of<AppNavigator>(this);

  /// Resolves the narrow Activity navigation capability.
  ActivityNavigation get activityNavigation => navigator;

  /// Resolves the narrow Catalog navigation capability.
  CatalogNavigation get catalogNavigation => navigator;
}
