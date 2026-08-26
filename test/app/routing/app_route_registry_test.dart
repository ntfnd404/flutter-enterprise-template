import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/activity_navigation.dart';
import 'package:template/app/routing/app_navigator.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/activity/routing/activity_route_name.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/demo/routing/demo_route_name.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';
import 'package:template/feature/not_found/routing/not_found_route_name.dart';

void main() {
  final codec = TreeUrlCodec<AppRoute>(appRouteRegistry);

  test('rejects duplicate decoder values before router construction', () {
    AppRoute decoder(Map<String, String> params, List<RouteNode> children) =>
        const DemoRoute();

    expect(
      () => composeAppRouteDecoders(<Map<String, RouteDecoder<AppRoute>>>[
        <String, RouteDecoder<AppRoute>>{'duplicate': decoder},
        <String, RouteDecoder<AppRoute>>{'duplicate': decoder},
      ]),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'privacy-safe message',
          isNot(contains('duplicate')),
        ),
      ),
    );
  });

  test('application routing owns the initial feature route policy', () {
    expect(initialAppRoutes, const <AppRoute>[DemoRoute()]);
  });

  test('route names expose stable values independently of pages', () {
    expect(DemoRouteName.demo.value, 'demo');
    expect(ActivityRouteName.activity.value, 'activity');
    expect(NotFoundRouteName.notFound.value, 'not-found');
    expect(const DemoRoute().name, DemoRouteName.demo.value);
    expect(
      ActivityRoute(sequence: 1).name,
      ActivityRouteName.activity.value,
    );
  });

  test('round-trips the typed flat route stack', () {
    final routes = <AppRoute>[
      const DemoRoute(),
      ActivityRoute(sequence: 7),
    ];

    final uri = codec.encode(routes);
    final decoded = codec.decode(uri);

    expect(uri.toString(), '/demo/activity~sequence=7');
    expect(decoded, routes);
  });

  test('normalizes a direct activity deep link below the landing route', () {
    final decoded = codec.decode(Uri.parse('/activity~sequence=3'));

    final normalized = normalizeAppStack(decoded);

    expect(normalized.first, const DemoRoute());
    expect(
      normalized.last,
      isA<ActivityRoute>().having((route) => route.sequence, 'sequence', 3),
    );
  });

  test(
    'invalid, extra, and unknown route input uses privacy-safe fallback',
    () {
      final invalid = codec.decode(Uri.parse('/activity~sequence=0')).single;
      final extra = codec
          .decode(Uri.parse('/activity~sequence=1&token=secret'))
          .single;
      final unknown = codec.decode(Uri.parse('/private~token=secret')).single;

      expect(invalid, isA<NotFoundRoute>());
      expect(extra, isA<NotFoundRoute>());
      expect(unknown, isA<NotFoundRoute>());
      expect(
        (invalid as NotFoundRoute).reason,
        AppRouteFailureReason.invalidParameters,
      );
      expect(
        (extra as NotFoundRoute).reason,
        AppRouteFailureReason.invalidParameters,
      );
      expect(
        (unknown as NotFoundRoute).reason,
        AppRouteFailureReason.unknownRoute,
      );
      expect(unknown.toParams(), isEmpty);
      expect(unknown.pageKey.toString(), isNot(contains('secret')));
    },
  );

  test('route identity includes every typed identity-bearing parameter', () {
    expect(
      ActivityRoute(sequence: 1).pageKey,
      isNot(ActivityRoute(sequence: 2).pageKey),
    );
    expect(
      () => ActivityRoute(sequence: 0),
      throwsArgumentError,
    );
  });

  test('typed navigator pushes and pops activity routes', () async {
    final state = RoutesState<AppRoute>(
      const <AppRoute>[DemoRoute()],
      normalizeAppStack,
    );
    addTearDown(state.dispose);
    final navigator = AppNavigator(state);

    final ActivityNavigation activityNavigation = navigator;
    activityNavigation.openActivity(sequence: 5);
    await state.processingCompleted;
    expect(state.root.last, isA<ActivityRoute>());

    navigator.pop();
    await state.processingCompleted;
    expect(state.root, const <AppRoute>[DemoRoute()]);
  });
}
