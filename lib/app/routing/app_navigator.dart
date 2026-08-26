import 'package:rolter/rolter.dart';
import 'package:template/app/routing/activity_navigation.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/catalog_navigation.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';

/// Application navigation facade over the typed route tree.
///
/// Stable callers depend on narrow application routing capabilities, while this
/// concrete composition object maps them to feature-owned typed routes.
final class AppNavigator extends NavigationController<AppRoute>
    implements ActivityNavigation, CatalogNavigation {
  /// Creates a navigator backed by [state].
  const AppNavigator(super.state);

  @override
  void openActivity({required int sequence}) => push(
    ActivityRoute(sequence: sequence),
  );

  @override
  void openCatalog() => push(const CatalogRoute());
}
