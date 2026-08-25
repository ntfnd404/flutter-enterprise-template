import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/routing/app_pages.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/app/routing/app_route_page_catalog.dart';
import 'package:template/app/routing/app_route_page_definition.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/activity/di/activity_scope.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/catalog/di/catalog_scope.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';
import 'package:template/feature/demo/di/demo_scope.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';

import '../../support/noop_catalog_facade.dart';
import '../../support/noop_ordering_facade.dart';

void main() {
  test('rejects duplicate exact route types during composition', () {
    final definition = TypedAppRoutePageDefinition<DemoRoute>(
      pageFactory: (context, route, nestedPageBuilder) => MaterialPage<void>(
        key: route.pageKey,
        child: const SizedBox(),
      ),
    );

    expect(
      () => AppRoutePageCatalog(<AppRoutePageDefinition>[
        definition,
        definition,
      ]),
      throwsStateError,
    );
  });

  testWidgets('builds every supported route type with the route Page key', (
    tester,
  ) async {
    final eventBus = AppEventBus();
    addTearDown(eventBus.dispose);
    final catalog = buildAppPages(
      dependencies: AppDependencies(
        catalog: const NoopCatalogFacade(),
        ordering: const NoopOrderingFacade(),
        eventPublisher: eventBus,
        eventSubscriber: eventBus,
      ),
    );
    final routes = <AppRoute>[
      const DemoRoute(),
      ActivityRoute(sequence: 1),
      const CatalogRoute(),
      const NotFoundRoute(reason: AppRouteFailureReason.unknownRoute),
    ];
    final builtPages = <Page<Object?>>[];

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          builtPages.addAll(
            routes.map((route) => catalog.build(context, route)),
          );

          return const SizedBox();
        },
      ),
    );

    expect(
      builtPages.map((page) => page.key),
      routes.map((route) => route.pageKey),
    );
    expect((builtPages[0] as MaterialPage<Object?>).child, isA<DemoScope>());
    expect(
      ((builtPages[0] as MaterialPage<Object?>).child as DemoScope).eventBus,
      same(eventBus),
    );
    expect(
      (builtPages[1] as MaterialPage<Object?>).child,
      isA<ActivityScope>(),
    );
    expect(
      ((builtPages[1] as MaterialPage<Object?>).child as ActivityScope)
          .eventBus,
      same(eventBus),
    );
    expect(
      (builtPages[2] as MaterialPage<Object?>).child,
      isA<CatalogScope>(),
    );
  });

  testWidgets('every externally routable sample has a decoder and a Page', (
    tester,
  ) async {
    final eventBus = AppEventBus();
    addTearDown(eventBus.dispose);
    final catalog = buildAppPages(
      dependencies: AppDependencies(
        catalog: const NoopCatalogFacade(),
        ordering: const NoopOrderingFacade(),
        eventPublisher: eventBus,
        eventSubscriber: eventBus,
      ),
    );
    final codec = appRouteUrlCodec;
    final samples = <AppRoute>[
      const DemoRoute(),
      ActivityRoute(sequence: 7),
      const CatalogRoute(),
    ];
    final decoded = samples
        .map((sample) => codec.decode(codec.encode(<AppRoute>[sample])).single)
        .toList();
    final pages = <Page<Object?>>[];

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          pages.addAll(decoded.map((route) => catalog.build(context, route)));

          return const SizedBox();
        },
      ),
    );

    expect(
      decoded.map((route) => route.runtimeType),
      samples.map((route) => route.runtimeType),
    );
    expect(
      pages.map((page) => page.key),
      decoded.map((route) => route.pageKey),
    );
  });

  testWidgets('supplies the complete catalog to nested Page composition', (
    tester,
  ) async {
    Page<Object?>? nestedPage;
    final catalog = AppRoutePageCatalog(<AppRoutePageDefinition>[
      TypedAppRoutePageDefinition<_ParentRoute>(
        pageFactory: (context, route, nestedPageBuilder) {
          nestedPage = nestedPageBuilder(context, const _ChildRoute());

          return MaterialPage<void>(
            key: route.pageKey,
            child: const SizedBox(),
          );
        },
      ),
      TypedAppRoutePageDefinition<_ChildRoute>(
        pageFactory: (context, route, nestedPageBuilder) => MaterialPage<void>(
          key: route.pageKey,
          child: const SizedBox(),
        ),
      ),
    ]);
    Page<Object?>? rootPage;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          rootPage = catalog.build(context, const _ParentRoute());

          return const SizedBox();
        },
      ),
    );

    expect(rootPage!.key, const _ParentRoute().pageKey);
    expect(nestedPage!.key, const _ChildRoute().pageKey);
  });

  test('representative production routes have globally unique Page keys', () {
    final routes = <AppRoute>[
      const DemoRoute(),
      ActivityRoute(sequence: 1),
      ActivityRoute(sequence: 2),
      const CatalogRoute(),
      const NotFoundRoute(reason: AppRouteFailureReason.unknownRoute),
      const NotFoundRoute(reason: AppRouteFailureReason.invalidParameters),
      const NotFoundRoute(reason: AppRouteFailureReason.invalidRouteTree),
    ];

    expect(
      routes.map((route) => route.pageKey).toSet(),
      hasLength(routes.length),
    );
  });

  testWidgets('preserves a Page factory error and original stack', (
    tester,
  ) async {
    final expected = StateError('Page factory failed.');
    final expectedStack = StackTrace.current;
    final catalog = AppRoutePageCatalog(<AppRoutePageDefinition>[
      TypedAppRoutePageDefinition<DemoRoute>(
        pageFactory: (context, route, nestedPageBuilder) {
          Error.throwWithStackTrace(expected, expectedStack);
        },
      ),
    ]);
    Object? actual;
    StackTrace? actualStack;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            catalog.build(context, const DemoRoute());
          } on Object catch (error, stack) {
            actual = error;
            actualStack = stack;
          }

          return const SizedBox();
        },
      ),
    );

    expect(actual, same(expected));
    expect(actualStack.toString(), expectedStack.toString());
  });

  testWidgets('fails safely when a route has no Page definition', (
    tester,
  ) async {
    final catalog = AppRoutePageCatalog(const <AppRoutePageDefinition>[]);
    Object? failure;

    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            catalog.build(context, const _MissingRoute());
          } catch (error) {
            failure = error;
          }

          return const SizedBox();
        },
      ),
    );

    expect(failure, isA<StateError>());
    expect(failure.toString(), isNot(contains('missing-secret')));
  });
}

final class _MissingRoute extends AppRoute {
  const _MissingRoute();

  @override
  LocalKey get pageKey => const ValueKey<String>('missing-secret');

  @override
  String get name => 'missing-secret';

  @override
  Map<String, String> toParams() => const <String, String>{};
}

final class _ParentRoute extends AppRoute {
  const _ParentRoute();

  @override
  LocalKey get pageKey => const ValueKey<String>('parent');

  @override
  String get name => 'parent';

  @override
  Map<String, String> toParams() => const <String, String>{};
}

final class _ChildRoute extends AppRoute {
  const _ChildRoute();

  @override
  LocalKey get pageKey => const ValueKey<String>('child');

  @override
  String get name => 'child';

  @override
  Map<String, String> toParams() => const <String, String>{};
}
