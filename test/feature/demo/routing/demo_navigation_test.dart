import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_navigator.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/demo/routing/demo_navigation.dart';
import 'package:template/feature/demo/routing/demo_route.dart';

void main() {
  test(
    'toDemo replaces the complete stack with the Demo landing route',
    () async {
      final state = RoutesState<AppRoute>(
        <AppRoute>[
          const DemoRoute(),
          ActivityRoute(sequence: 7),
        ],
        normalizeAppStack,
      );
      addTearDown(state.dispose);
      final navigator = AppNavigator(state);

      navigator.toDemo();
      await state.processingCompleted;

      expect(state.root, const <AppRoute>[DemoRoute()]);
    },
  );
}
