import 'package:flutter_test/flutter_test.dart';
import 'package:rolter/rolter.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/routing/not_found_route.dart';
import 'package:template/feature/not_found/routing/not_found_route_name.dart';

void main() {
  test(
    'uses typed privacy-safe identity and remains excluded from history',
    () {
      const route = NotFoundRoute(
        reason: AppRouteFailureReason.invalidParameters,
      );

      expect(route.name, NotFoundRouteName.notFound.value);
      expect(route.pageKey.toString(), contains('invalidParameters'));
      expect(route.toParams(), isEmpty);
      expect(route, isA<HistoryExcluded>());
    },
  );
}
