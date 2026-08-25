import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/app/routing/app_route_registry.dart';
import 'package:template/feature/activity/routing/activity_route.dart';
import 'package:template/feature/demo/routing/demo_route.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';

void main() {
  test('logical parser contract is Web-runtime safe', () async {
    final parser = RoutingInformationParser<AppRoute>(appRouteUrlCodec);

    final parsed = await parser.parseRouteInformation(
      RouteInformation(uri: Uri.parse('/demo/activity~sequence=7')),
    );
    final restored = parser.restoreRouteInformation(parsed);

    expect(parsed, <AppRoute>[const DemoRoute(), ActivityRoute(sequence: 7)]);
    expect(restored, isNotNull);
    expect(restored!.uri.toString(), '/demo/activity~sequence=7');
    expect(
      const NotFoundRoute(reason: AppRouteFailureReason.unknownRoute),
      isA<HistoryExcluded>(),
    );
    expect(
      parser.restoreRouteInformation(const <AppRoute>[
        DemoRoute(),
        NotFoundRoute(reason: AppRouteFailureReason.unknownRoute),
      ]),
      isNull,
    );
  });
}
