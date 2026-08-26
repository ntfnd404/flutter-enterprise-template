@TestOn('browser')
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/environment/app_url_strategy.dart';
import 'package:template/app/startup/url_strategy.dart';

void main() {
  test('hash strategy is a supported safe browser default', () {
    expect(
      () => configureUrlStrategy(AppUrlStrategy.hash),
      returnsNormally,
    );
  });

  test('path strategy remains compiled as a deployment opt-in', () {
    // The Flutter test runner does not provide the deployment `<base href>`
    // required by PathUrlStrategy. The architecture guard pins the Web call,
    // while `flutter build web` verifies the production entry document.
    expect(AppUrlStrategy.values, contains(AppUrlStrategy.path));
  });
}
