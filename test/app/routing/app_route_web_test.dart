import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/routing/app_router.dart';
import 'package:template/feature/not_found/view/not_found_screen.dart';

import 'support/routing_test_fixture.dart';

void main() {
  testWidgets('Web runtime renders a privacy-safe invalid route fallback', (
    tester,
  ) async {
    final fixture = RoutingTestFixture();
    final router = createAppRouter(dependencies: fixture.dependencies);
    addTearDown(() async {
      router.dispose();
      await fixture.dispose();
    });

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/missing?token=web-secret');
    await tester.pumpAndSettle();

    expect(find.byType(NotFoundScreen), findsOneWidget);
    expect(find.textContaining('web-secret'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
