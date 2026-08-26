import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('go_router stays inside the two root UI composition libraries', () {
    final importers = dartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains(
            "import 'package:go_router/go_router.dart';",
          ),
        )
        .map((file) => file.path)
        .toList();

    expect(
      importers,
      unorderedEquals(<String>[
        'lib/app/routing/app_router.dart',
        'lib/app/view/app.dart',
      ]),
    );

    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('go_router: 18.0.0'));
    expect(pubspec, isNot(contains('go_router_builder:')));
    expect(pubspec, isNot(contains('build_runner:')));
    expect(pubspec, isNot(contains('rolter:')));
    expect(pubspec, isNot(contains('ui_kit:')));
  });

  test('the app router is the exact concrete feature composition point', () {
    final router = File(
      'lib/app/routing/app_router.dart',
    ).readAsStringSync();
    final featureImports = RegExp(
      r"import 'package:template/(feature/[^']+)';",
    ).allMatches(router).map((match) => match.group(1)).toList();

    expect(
      featureImports,
      unorderedEquals(<String>[
        'feature/activity/di/activity_scope.dart',
        'feature/activity/view/activity_screen.dart',
        'feature/catalog/di/catalog_scope.dart',
        'feature/catalog/view/catalog_screen.dart',
        'feature/demo/view/demo_screen.dart',
        'feature/not_found/view/not_found_screen.dart',
        'feature/orders/di/orders_scope.dart',
        'feature/orders/view/orders_screen.dart',
      ]),
    );
    expect(router, contains("const _rootPath = '/';"));
    expect(router, contains("const _activityPath = 'activity/:sequence';"));
    expect(router, contains("const _catalogPath = 'catalog';"));
    expect(router, contains("const _ordersPath = 'orders';"));
    expect(router, isNot(contains('initialLocation:')));
    expect(router, isNot(contains('overridePlatformDefaultLocation:')));
    expect(router, isNot(contains('debugLogDiagnostics: true')));
    expect(router, isNot(contains('NavigatorObserver')));

    final app = File('lib/app/view/app.dart').readAsStringSync();
    expect(
      app.indexOf('_router.dispose();'),
      lessThan(app.indexOf('super.dispose();')),
    );
  });

  test('features and packages stay provider-neutral and feature-isolated', () {
    final providerOffenders = <String>[];
    for (final root in <String>['lib/feature', 'packages']) {
      providerOffenders.addAll(
        dartFiles(root)
            .where(
              (file) => file.readAsStringSync().contains('package:go_router/'),
            )
            .map((file) => file.path),
      );
    }
    expect(providerOffenders, isEmpty);

    final crossFeatureImports = <String>[];
    for (final file in dartFiles('lib/feature')) {
      final relative = file.path.substring('lib/feature/'.length);
      final owner = relative.split('/').first;
      final source = file.readAsStringSync();
      final imports = RegExp(
        r'package:template/feature/([^/]+)/',
      ).allMatches(source).map((match) => match.group(1));
      if (imports.any((feature) => feature != owner)) {
        crossFeatureImports.add(file.path);
      }
    }
    expect(crossFeatureImports, isEmpty);
  });

  test('navigation and EventBus remain narrow privacy-safe seams', () {
    final router = File(
      'lib/app/routing/app_router.dart',
    ).readAsStringSync();
    final notFound = File(
      'lib/feature/not_found/view/not_found_screen.dart',
    ).readAsStringSync();
    final event = File(
      'lib/app/events/order_draft_created_app_event.dart',
    ).readAsStringSync();

    expect(router, isNot(contains('GlobalKey<NavigatorState>')));
    expect(router, isNot(contains('NavigationService')));
    expect(router, isNot(contains('state.error')));
    expect(notFound, isNot(contains('Uri')));
    expect(notFound, isNot(contains('GoRouterState')));
    expect(notFound, isNot(contains('error')));
    expect(event, contains('required this.operationSequence'));
    expect(event, isNot(contains('OrderId')));
    expect(event, isNot(contains('Uri')));
    expect(event, isNot(contains('Route')));
  });

  test('generated routing and speculative routing layers stay absent', () {
    final offenders = dartFiles('lib')
        .where((file) {
          final path = file.path;
          final source = file.readAsStringSync();

          return path.endsWith('.g.dart') && source.contains('GoRouteData') ||
              source.contains('class AppRoute ') ||
              source.contains('AppRoutePageCatalog') ||
              source.contains('RouteNodePageBuilder') ||
              source.contains('NavigationService');
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
