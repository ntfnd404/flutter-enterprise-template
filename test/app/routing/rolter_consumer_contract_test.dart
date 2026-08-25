import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/feature/activity/routing/activity_route.dart';

void main() {
  group('Rolter 0.2.1 consumer contract', () {
    test('new, initial, and restored paths accept synchronously', () async {
      final setters =
          <
            Future<void> Function(
              RoutingDelegate<AppRoute>,
              List<AppRoute>,
            )
          >[
            (delegate, routes) => delegate.setNewRoutePath(routes),
            (delegate, routes) => delegate.setInitialRoutePath(routes),
            (delegate, routes) => delegate.setRestoredRoutePath(routes),
          ];

      for (final setPath in setters) {
        final started = Completer<void>();
        final release = Completer<void>();
        final state = RoutesState<AppRoute>(initialAppRoutes, (
          requested,
        ) async {
          started.complete();
          await release.future;

          return requested;
        });
        final delegate = RoutingDelegate<AppRoute>(
          state,
          pageBuilder: _buildPage,
        );
        var accepted = false;

        unawaited(
          setPath(delegate, <AppRoute>[ActivityRoute(sequence: 1)]).then((_) {
            accepted = true;
          }),
        );
        final drain = state.processingCompleted;

        expect(accepted, isTrue);
        await started.future;
        expect(state.root, initialAppRoutes);

        release.complete();
        await drain;
        expect(state.root, <AppRoute>[ActivityRoute(sequence: 1)]);

        delegate.dispose();
        state.dispose();
      }
    });

    test(
      'one shared drain includes FIFO requests accepted before idle',
      () async {
        final firstStarted = Completer<void>();
        final releaseFirst = Completer<void>();
        final processed = <int>[];
        final state = RoutesState<AppRoute>(initialAppRoutes, (
          requested,
        ) async {
          final route = requested.last as ActivityRoute;
          processed.add(route.sequence);
          if (route.sequence == 1) {
            firstStarted.complete();
            await releaseFirst.future;
          }

          return requested;
        });

        state.setRoot(<AppRoute>[ActivityRoute(sequence: 1)]);
        final drain = state.processingCompleted;
        await firstStarted.future;
        state.setRoot(<AppRoute>[ActivityRoute(sequence: 2)]);

        expect(processed, <int>[1]);
        releaseFirst.complete();
        await drain;

        expect(processed, <int>[1, 2]);
        expect(state.root, <AppRoute>[ActivityRoute(sequence: 2)]);
        state.dispose();
      },
    );

    test(
      'live failure preserves error and stack, then permits recovery',
      () async {
        final expected = StateError('route policy failed');
        final expectedStack = StackTrace.current;
        var shouldFail = true;
        final processed = <int>[];
        final state = RoutesState<AppRoute>(initialAppRoutes, (requested) {
          final route = requested.last as ActivityRoute;
          processed.add(route.sequence);
          if (shouldFail) {
            Error.throwWithStackTrace(expected, expectedStack);
          }

          return requested;
        });

        state.setRoot(<AppRoute>[ActivityRoute(sequence: 1)]);
        state.setRoot(<AppRoute>[ActivityRoute(sequence: 2)]);
        Object? actual;
        StackTrace? actualStack;
        try {
          await state.processingCompleted;
        } on Object catch (error, stack) {
          actual = error;
          actualStack = stack;
        }

        expect(actual, same(expected));
        expect(actualStack.toString(), expectedStack.toString());
        expect(processed, <int>[1]);
        expect(state.root, initialAppRoutes);

        shouldFail = false;
        state.setRoot(<AppRoute>[ActivityRoute(sequence: 3)]);
        await state.processingCompleted;
        expect(state.root, <AppRoute>[ActivityRoute(sequence: 3)]);
        state.dispose();
      },
    );

    for (final lateFailure in <bool>[false, true]) {
      test(
        'dispose abandons active and queued ${lateFailure ? 'error' : 'success'}',
        () async {
          final started = Completer<void>();
          final release = Completer<void>();
          final processed = <int>[];
          var notifications = 0;
          final state = RoutesState<AppRoute>(initialAppRoutes, (
            requested,
          ) async {
            final route = requested.last as ActivityRoute;
            processed.add(route.sequence);
            started.complete();
            await release.future;
            if (lateFailure) {
              throw StateError('late route policy failure');
            }

            return requested;
          });
          state.addListener(() => notifications++);

          state.setRoot(<AppRoute>[ActivityRoute(sequence: 1)]);
          state.setRoot(<AppRoute>[ActivityRoute(sequence: 2)]);
          final drain = state.processingCompleted;
          await started.future;

          state.dispose();
          release.complete();
          await drain;

          expect(processed, <int>[1]);
          expect(state.root, initialAppRoutes);
          expect(notifications, 0);
        },
      );
    }

    test('borrowed navigator rejects mutation after state disposal', () {
      final state = RoutesState<AppRoute>(initialAppRoutes, normalizeAppStack);
      final navigator = NavigationController<AppRoute>(state);
      state.dispose();

      expect(
        () => navigator.push(ActivityRoute(sequence: 1)),
        throwsA(isA<StateError>()),
      );
    });
  });

  for (final lateFailure in <bool>[false, true]) {
    testWidgets(
      'Router unmount contains pending ${lateFailure ? 'error' : 'success'}',
      (tester) async {
        final started = Completer<void>();
        final release = Completer<void>();
        final state = RoutesState<AppRoute>(initialAppRoutes, (
          requested,
        ) async {
          if (requested.last case ActivityRoute()) {
            started.complete();
            await release.future;
            if (lateFailure) {
              throw StateError('late route policy failure');
            }
          }

          return requested;
        });
        final delegate = RoutingDelegate<AppRoute>(
          state,
          pageBuilder: _buildPage,
        );
        final provider = _TestRouteInformationProvider('/demo');

        await tester.pumpWidget(
          MaterialApp.router(
            routerDelegate: delegate,
            routeInformationParser: RoutingInformationParser<AppRoute>(
              appRouteUrlCodec,
            ),
            routeInformationProvider: provider,
          ),
        );
        await tester.pumpAndSettle();

        provider.go('/activity~sequence=1');
        await tester.pump();
        await started.future;
        final drain = state.processingCompleted;

        await tester.pumpWidget(const SizedBox.shrink());
        delegate.dispose();
        state.dispose();
        release.complete();
        await drain;
        await tester.pump();

        expect(state.root, initialAppRoutes);
        expect(tester.takeException(), isNull);
        provider.dispose();
      },
    );
  }
}

Page<Object?> _buildPage(BuildContext context, AppRoute route) =>
    MaterialPage<Object?>(key: route.pageKey, child: Text(route.name));

final class _TestRouteInformationProvider extends RouteInformationProvider
    with ChangeNotifier {
  _TestRouteInformationProvider(String initialLocation)
    : _value = RouteInformation(uri: Uri.parse(initialLocation));

  RouteInformation _value;

  @override
  RouteInformation get value => _value;

  void go(String location) {
    _value = RouteInformation(uri: Uri.parse(location));
    notifyListeners();
  }
}
