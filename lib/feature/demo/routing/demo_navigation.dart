import 'package:template/app/routing/app_navigator.dart';
import 'package:template/feature/demo/routing/demo_route.dart';

/// Feature-owned navigation operations for Demo destinations.
///
/// Use this extension from Demo composition code or an application routing
/// composition point when the caller intentionally depends on the Demo
/// feature:
///
/// ```dart
/// void returnToDemo(AppNavigator navigator) => navigator.toDemo();
/// ```
///
/// Unrelated features must not import this extension. Cross-feature callers
/// instead depend on a narrow application-owned capability such as
/// `ActivityNavigation`, which prevents them from importing concrete routes.
extension DemoNavigation on AppNavigator {
  /// Resets the complete route stack to the Demo landing route.
  ///
  /// This is a destructive stack reset, not an alias for `pop`. Use it only
  /// when every currently visible route should be discarded.
  void toDemo() => clearAndPush(const DemoRoute());
}
