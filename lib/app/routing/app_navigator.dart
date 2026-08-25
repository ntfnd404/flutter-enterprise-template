import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';

/// Bare application controller over the typed route tree.
///
/// Cross-feature callers receive narrow navigation roles assembled by the app
/// routing composition instead of depending on this controller directly.
final class AppNavigator extends NavigationController<AppRoute> {
  /// Creates a navigator backed by [state].
  const AppNavigator(super.state);
}
