import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_navigator.dart';
import 'package:template/app/routing/app_navigator_context.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';
import 'package:template/feature/demo/routing/demo_route.dart';

void main() {
  testWidgets('maps narrow navigation roles to the borrowed navigator', (
    tester,
  ) async {
    final state = RoutesState<AppRoute>(initialAppRoutes, normalizeAppStack);
    final navigator = AppNavigator(state);
    late BuildContext context;

    await tester.pumpWidget(
      NavigatorScope<AppNavigator>(
        navigator: navigator,
        child: Builder(
          builder: (value) {
            context = value;

            return const SizedBox();
          },
        ),
      ),
    );

    context.activityNavigation.openActivity(sequence: 5);
    await state.processingCompleted;
    expect(state.root.last, ActivityRoute(sequence: 5));

    context.catalogNavigation.openCatalog();
    await state.processingCompleted;
    expect(state.root.last, const CatalogRoute());

    state.dispose();
    expect(
      context.catalogNavigation.openCatalog,
      throwsA(isA<StateError>()),
    );
    expect(state.root.first, const DemoRoute());
  });
}
