import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/routing/app_router.dart';
import 'package:template/feature/activity/view/activity_screen.dart';
import 'package:template/feature/catalog/view/catalog_screen.dart';
import 'package:template/feature/demo/view/demo_screen.dart';
import 'package:template/feature/not_found/view/not_found_screen.dart';
import 'package:template/feature/orders/view/orders_screen.dart';

import 'support/routing_test_fixture.dart';

void main() {
  testWidgets('maps the exact canonical route vocabulary', (tester) async {
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.byType(DemoScreen), findsOneWidget);
    for (final scenario in <(String, Type)>[
      ('/activity/7', ActivityScreen),
      ('/catalog', CatalogScreen),
      ('/orders', OrdersScreen),
    ]) {
      router.go(scenario.$1);
      await tester.pumpAndSettle();
      expect(find.byType(scenario.$2), findsOneWidget);
    }
  });

  testWidgets('preserves a platform-provided initial location', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue = '/activity/7';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.textContaining('7'), findsWidgets);
  });

  testWidgets('accepts the maximum canonical Activity sequence', (
    tester,
  ) async {
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/activity/2147483647');
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.textContaining('2147483647'), findsWidgets);
  });

  testWidgets('fails closed for malformed or unsupported locations', (
    tester,
  ) async {
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    for (final location in <String>[
      '/activity/0',
      '/activity/-1',
      '/activity/01',
      '/activity/2147483648',
      '/activity/+1',
      '/catalog?token=secret-value',
      '/orders#secret-fragment',
      '/unknown/secret-value',
      '/Catalog',
    ]) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(
        find.byType(NotFoundScreen),
        findsOneWidget,
        reason: location,
      );
      expect(find.textContaining('secret-value'), findsNothing);
      expect(find.textContaining('secret-fragment'), findsNothing);
    }
  });

  testWidgets('accepts provider-normalized trailing slash aliases', (
    tester,
  ) async {
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    router.go('/catalog/');
    await tester.pumpAndSettle();

    expect(find.byType(CatalogScreen), findsOneWidget);
    expect(router.state.uri.path, '/catalog');
  });

  testWidgets('system back returns every child route to Demo', (tester) async {
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    for (final location in <String>['/activity/7', '/catalog', '/orders']) {
      router.go(location);
      await tester.pumpAndSettle();
      expect(
        find.byType(DemoScreen, skipOffstage: false),
        findsOneWidget,
      );
      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect(find.byType(DemoScreen), findsOneWidget);
    }

    expect(await tester.binding.handlePopRoute(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
