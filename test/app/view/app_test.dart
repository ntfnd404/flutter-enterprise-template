import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:template/app/view/app.dart';
import 'package:template/feature/activity/view/activity_screen.dart';
import 'package:template/feature/demo/view/demo_screen.dart';

import '../routing/support/routing_test_fixture.dart';

void main() {
  testWidgets('same dependencies retain route state across rebuild', (
    tester,
  ) async {
    final fixture = RoutingTestFixture();
    addTearDown(fixture.dispose);
    const key = ValueKey<String>('app');
    await tester.pumpWidget(App(key: key, dependencies: fixture.dependencies));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(DemoScreen))).go('/activity/7');
    await tester.pumpAndSettle();

    await tester.pumpWidget(App(key: key, dependencies: fixture.dependencies));
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
  });

  testWidgets('same State rejects dependency replacement and can recover', (
    tester,
  ) async {
    final original = RoutingTestFixture();
    final replacement = RoutingTestFixture();
    addTearDown(original.dispose);
    addTearDown(replacement.dispose);
    const key = ValueKey<String>('app');
    await tester.pumpWidget(App(key: key, dependencies: original.dependencies));

    await tester.pumpWidget(
      App(key: key, dependencies: replacement.dependencies),
    );
    final failure = tester.takeException();
    expect(
      failure,
      isA<StateError>().having(
        (error) => error.message,
        'message',
        'App does not support replacing application dependencies.',
      ),
    );

    await tester.pumpWidget(App(key: key, dependencies: original.dependencies));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DemoScreen), findsOneWidget);
  });

  testWidgets('new App identity accepts replacement dependencies', (
    tester,
  ) async {
    final original = RoutingTestFixture();
    final replacement = RoutingTestFixture();
    addTearDown(original.dispose);
    addTearDown(replacement.dispose);
    await tester.pumpWidget(
      App(
        key: const ValueKey<String>('first'),
        dependencies: original.dependencies,
      ),
    );

    await tester.pumpWidget(
      App(
        key: const ValueKey<String>('second'),
        dependencies: replacement.dependencies,
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DemoScreen), findsOneWidget);
  });

  testWidgets('restores a valid parameterized Activity configuration', (
    tester,
  ) async {
    final fixture = RoutingTestFixture();
    addTearDown(fixture.dispose);
    await tester.pumpWidget(App(dependencies: fixture.dependencies));
    await tester.pumpAndSettle();
    GoRouter.of(tester.element(find.byType(DemoScreen))).go('/activity/7');
    await tester.pumpAndSettle();

    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    expect(find.byType(ActivityScreen), findsOneWidget);
    expect(find.textContaining('7'), findsWidgets);
    expect(await tester.binding.handlePopRoute(), isTrue);
    await tester.pumpAndSettle();
    expect(find.byType(DemoScreen), findsOneWidget);
  });
}
