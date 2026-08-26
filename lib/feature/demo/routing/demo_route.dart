import 'package:flutter/foundation.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/feature/demo/routing/demo_route_name.dart';

/// Landing route for the demo feature.
final class DemoRoute extends AppRoute {
  /// Creates the landing route.
  const DemoRoute();

  @override
  LocalKey get pageKey => ValueKey<String>(DemoRouteName.demo.value);

  @override
  String get name => DemoRouteName.demo.value;

  @override
  Map<String, String> toParams() => const <String, String>{};
}
