import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/app/routing/app_route_url_codec.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/catalog/routing/catalog_route.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';

void main() {
  group('logical URL contract', () {
    test('round-trips the canonical typed route stack', () {
      final routes = <AppRoute>[
        const DemoRoute(),
        ActivityRoute(sequence: 7),
      ];

      final uri = appRouteUrlCodec.encode(routes);
      final decoded = appRouteUrlCodec.decode(uri);

      expect(uri.toString(), '/demo/activity~sequence=7');
      expect(decoded, routes);
    });

    test('supports direct entries and normalizes them below Demo', () {
      final activity = normalizeAppStack(
        appRouteUrlCodec.decode(Uri.parse('/activity~sequence=3')),
      );
      final queriedActivity = normalizeAppStack(
        appRouteUrlCodec.decode(Uri.parse('/activity?sequence=4')),
      );
      final catalog = normalizeAppStack(
        appRouteUrlCodec.decode(Uri.parse('/catalog')),
      );

      expect(activity.first, const DemoRoute());
      expect(
        activity.last,
        isA<ActivityRoute>().having((route) => route.sequence, 'sequence', 3),
      );
      expect(
        queriedActivity.last,
        isA<ActivityRoute>().having((route) => route.sequence, 'sequence', 4),
      );
      expect(catalog, const <AppRoute>[DemoRoute(), CatalogRoute()]);
    });

    test('inline parameters take precedence over query parameters', () {
      final decoded = appRouteUrlCodec
          .decode(Uri.parse('/activity~sequence=7?sequence=8'))
          .single;

      expect(
        decoded,
        isA<ActivityRoute>().having((route) => route.sequence, 'sequence', 7),
      );
    });

    test('rejects duplicate parameters within either URL channel', () {
      final queryDuplicate = appRouteUrlCodec.decode(
        Uri.parse('/activity?sequence=1&sequence=2'),
      );
      final inlineDuplicate = appRouteUrlCodec.decode(
        Uri.parse('/activity~sequence=1&sequence=2'),
      );
      final encodedDuplicate = appRouteUrlCodec.decode(
        Uri.parse('/activity~se%71uence=1&sequence=2'),
      );
      final encodedQueryDuplicate = appRouteUrlCodec.decode(
        Uri.parse('/activity?se%71uence=1&sequence=2'),
      );
      final queryGrammarDuplicate = appRouteUrlCodec.decode(
        Uri.parse('/activity?seque+nce=1&seque%20nce=2'),
      );

      expect(
        _failureReason(queryDuplicate),
        AppRouteFailureReason.invalidRouteTree,
      );
      expect(
        _failureReason(inlineDuplicate),
        AppRouteFailureReason.invalidRouteTree,
      );
      expect(
        _failureReason(encodedDuplicate),
        AppRouteFailureReason.invalidRouteTree,
      );
      expect(
        _failureReason(encodedQueryDuplicate),
        AppRouteFailureReason.invalidRouteTree,
      );
      expect(
        _failureReason(queryGrammarDuplicate),
        AppRouteFailureReason.invalidRouteTree,
      );
    });

    test(
      'treats recovery names as internal rather than external wire values',
      () {
        final decoded = appRouteUrlCodec.decode(Uri.parse('/not-found'));

        expect(
          _failureReason(decoded),
          AppRouteFailureReason.unknownRoute,
        );
      },
    );

    test('empty, malformed, and unknown input recover without raw data', () {
      final empty = appRouteUrlCodec.decode(Uri.parse('/'));
      final invalid = appRouteUrlCodec
          .decode(Uri.parse('/activity~sequence=0'))
          .single;
      final extra = appRouteUrlCodec
          .decode(Uri.parse('/activity~sequence=1&token=secret'))
          .single;
      final unknown = appRouteUrlCodec
          .decode(Uri.parse('/private~token=secret'))
          .single;

      expect(empty, isEmpty);
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
      expect('$unknown', isNot(contains('secret')));
    });
  });

  group('external tree safety boundary', () {
    test('enforces the exact serialized-location bound before decoding', () {
      var decodeCalls = 0;
      final codec = AppRouteUrlCodec(
        _CallbackCodec(
          onDecode: (_) {
            decodeCalls++;

            return const <AppRoute>[DemoRoute()];
          },
        ),
      );

      final accepted = codec.decode(Uri.parse('/${'a' * 4095}'));
      final rejected = codec.decode(Uri.parse('/${'a' * 4096}'));

      expect(accepted, const <AppRoute>[DemoRoute()]);
      expect(decodeCalls, 1);
      expect(_failureReason(rejected), AppRouteFailureReason.invalidRouteTree);
    });

    test('enforces the exact non-empty segment bound before decoding', () {
      var decodeCalls = 0;
      final codec = AppRouteUrlCodec(
        _CallbackCodec(
          onDecode: (_) {
            decodeCalls++;

            return const <AppRoute>[DemoRoute()];
          },
        ),
      );

      final accepted = codec.decode(Uri(path: List.filled(32, 'a').join('/')));
      final rejected = codec.decode(Uri(path: List.filled(33, 'a').join('/')));

      expect(accepted, const <AppRoute>[DemoRoute()]);
      expect(decodeCalls, 1);
      expect(_failureReason(rejected), AppRouteFailureReason.invalidRouteTree);
    });

    test(
      'rejects malformed encoded parameters before calling the delegate',
      () {
        var decodeCalls = 0;
        final codec = AppRouteUrlCodec(
          _CallbackCodec(
            onDecode: (_) {
              decodeCalls++;

              return const <AppRoute>[DemoRoute()];
            },
          ),
        );

        final decoded = codec.decode(const _MalformedParameterUri());
        final malformedQuery = codec.decode(
          const _MalformedParameterUri(
            path: '/activity',
            query: 'sequence=%ZZ',
          ),
        );

        expect(_failureReason(decoded), AppRouteFailureReason.invalidRouteTree);
        expect(
          _failureReason(malformedQuery),
          AppRouteFailureReason.invalidRouteTree,
        );
        expect(decodeCalls, 0);
      },
    );

    test('allows the same inline key on distinct route segments', () {
      var decodeCalls = 0;
      final codec = AppRouteUrlCodec(
        _CallbackCodec(
          onDecode: (_) {
            decodeCalls++;

            return const <AppRoute>[DemoRoute(), CatalogRoute()];
          },
        ),
      );

      final decoded = codec.decode(
        Uri.parse('/first~id=1/second~id=2'),
      );

      expect(decoded, const <AppRoute>[DemoRoute(), CatalogRoute()]);
      expect(decodeCalls, 1);
    });

    test('collapses duplicate page keys without stringifying them', () {
      const key = _HostileLocalKey();
      final codec = AppRouteUrlCodec(
        _CallbackCodec(
          onDecode: (_) => const <AppRoute>[
            _TestRoute(name: 'first', pageKey: key),
            _TestRoute(name: 'second', pageKey: key),
          ],
        ),
      );

      final decoded = codec.decode(Uri.parse('/safe'));

      expect(_failureReason(decoded), AppRouteFailureReason.invalidRouteTree);
    });

    test('collapses fallback mixtures across the complete nested tree', () {
      const fallback = NotFoundRoute(
        reason: AppRouteFailureReason.unknownRoute,
      );
      final cases = <List<AppRoute>>[
        const <AppRoute>[fallback, fallback],
        const <AppRoute>[DemoRoute(), fallback],
        <AppRoute>[
          const _TestRoute(
            name: 'shell',
            pageKey: ValueKey<String>('shell'),
            children: <AppRoute>[fallback],
          ),
        ],
      ];

      for (final routes in cases) {
        final codec = AppRouteUrlCodec(
          _CallbackCodec(onDecode: (_) => routes),
        );

        expect(
          _failureReason(codec.decode(Uri.parse('/safe'))),
          AppRouteFailureReason.invalidRouteTree,
        );
      }
    });

    test('preserves one standalone sanitized fallback', () {
      const fallback = NotFoundRoute(
        reason: AppRouteFailureReason.invalidParameters,
      );
      final codec = AppRouteUrlCodec(
        _CallbackCodec(onDecode: (_) => const <AppRoute>[fallback]),
      );

      expect(codec.decode(Uri.parse('/safe')), const <AppRoute>[fallback]);
    });

    test('returns an immutable decoded list', () {
      final decoded = appRouteUrlCodec.decode(Uri.parse('/demo'));

      expect(() => decoded.add(const CatalogRoute()), throwsUnsupportedError);
    });

    test('preserves programming failures from the delegated codec', () {
      final expected = StateError('authored decoder failure');
      final expectedStack = StackTrace.current;
      final codec = AppRouteUrlCodec(
        _CallbackCodec(
          onDecode: (_) => Error.throwWithStackTrace(expected, expectedStack),
        ),
      );
      Object? caught;
      StackTrace? caughtStack;

      try {
        codec.decode(Uri.parse('/safe'));
      } catch (error, stackTrace) {
        caught = error;
        caughtStack = stackTrace;
      }

      expect(caught, same(expected));
      expect(caughtStack, same(expectedStack));
    });

    test('delegates encoding without rewriting the wire grammar', () {
      final expected = Uri.parse('/encoded');
      List<AppRoute>? encodedRoutes;
      final codec = AppRouteUrlCodec(
        _CallbackCodec(
          onDecode: (_) => const <AppRoute>[],
          onEncode: (routes) {
            encodedRoutes = routes;

            return expected;
          },
        ),
      );
      final routes = <AppRoute>[const DemoRoute()];

      expect(codec.encode(routes), expected);
      expect(encodedRoutes, same(routes));
    });
  });
}

AppRouteFailureReason _failureReason(List<AppRoute> routes) =>
    (routes.single as NotFoundRoute).reason;

final class _CallbackCodec implements RouteUrlCodec<AppRoute> {
  const _CallbackCodec({required this.onDecode, this.onEncode});

  final List<AppRoute> Function(Uri uri) onDecode;
  final Uri Function(List<AppRoute> routes)? onEncode;

  @override
  List<AppRoute> decode(Uri uri) => onDecode(uri);

  @override
  Uri encode(List<AppRoute> roots) => onEncode?.call(roots) ?? Uri();
}

final class _TestRoute extends AppRoute {
  const _TestRoute({
    required this.name,
    required this.pageKey,
    this.children = const <AppRoute>[],
  });

  @override
  final String name;

  @override
  final LocalKey pageKey;

  @override
  final List<AppRoute> children;

  @override
  Map<String, String> toParams() => const <String, String>{};

  @override
  AppRoute withChildren(List<RouteNode> children) => _TestRoute(
    name: name,
    pageKey: pageKey,
    children: children.cast<AppRoute>(),
  );
}

final class _HostileLocalKey extends LocalKey {
  const _HostileLocalKey();

  @override
  String toString() => throw StateError('A page key must not be stringified.');
}

final class _MalformedParameterUri implements Uri {
  const _MalformedParameterUri({
    this.path = '/activity~sequence=%ZZ',
    this.query = '',
  });

  @override
  final String path;

  @override
  final String query;

  @override
  String toString() => query.isEmpty ? path : '$path?$query';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
