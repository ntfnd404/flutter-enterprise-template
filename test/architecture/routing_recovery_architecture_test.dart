import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('Activity navigation contract belongs to application routing', () {
    expect(
      File('lib/feature/app/routing/activity_navigation.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/app/routing/activity_navigation.dart').existsSync(),
      isTrue,
    );
    expect(Directory('lib/core/routing').existsSync(), isFalse);
  });

  test('AppNavigator maps narrow routing capabilities to feature routes', () {
    final contents = File(
      'lib/app/routing/app_navigator.dart',
    ).readAsStringSync();

    expect(contents, isNot(contains('package:template/feature/demo/')));
    expect(contents, contains('implements ActivityNavigation'));
    expect(
      contents,
      contains('/feature/activity/routing/activity_route.dart'),
    );
  });

  test('concrete feature imports stay in composition locations', () {
    final offenders = dartFiles('lib/app')
        .where((file) {
          final contents = file.readAsStringSync();
          final importsFeature = contents.contains('package:template/feature/');
          final approved =
              file.path.endsWith('/app/routing/app_navigator.dart') ||
              file.path.endsWith('/app/routing/app_pages.dart') ||
              file.path.endsWith('/app/routing/app_route_registry.dart') ||
              file.path.endsWith('/app/view/startup_failure_app.dart');

          return importsFeature && !approved;
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('main composes decoder and Page catalogs before runApp handoff', () {
    final contents = File('lib/main.dart').readAsStringSync();
    final pages = contents.indexOf('pageCatalogBuilder(');
    final decoders = contents.indexOf('final _ = appRouteRegistry;');
    final handoff = contents.indexOf('runApp(', decoders);

    expect(pages, greaterThanOrEqualTo(0));
    expect(decoders, greaterThan(pages));
    expect(handoff, greaterThan(decoders));
  });

  test('feature-owned Demo navigation is not imported by other features', () {
    const demoNavigationPath = 'lib/feature/demo/routing/demo_navigation.dart';
    final demoNavigation = File(demoNavigationPath);

    expect(
      demoNavigation.existsSync(),
      isTrue,
      reason: 'DemoNavigation must remain in the Demo-owned routing directory.',
    );
    expect(
      demoNavigation.readAsStringSync(),
      contains('extension DemoNavigation on AppNavigator'),
    );

    final offenders = dartFiles('lib/feature')
        .where(
          (file) =>
              !file.path.contains('/feature/demo/') &&
              file.readAsStringSync().contains(
                'feature/demo/routing/demo_navigation.dart',
              ),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('recovery features expose BLoC, DI, routing, and view boundaries', () {
    const requiredFiles = <String>[
      'lib/feature/not_found/bloc/not_found_bloc.dart',
      'lib/feature/not_found/bloc/not_found_event.dart',
      'lib/feature/not_found/bloc/not_found_state.dart',
      'lib/feature/not_found/di/not_found_scope.dart',
      'lib/feature/not_found/routing/not_found_route.dart',
      'lib/feature/not_found/routing/not_found_route_name.dart',
      'lib/feature/not_found/view/not_found_screen.dart',
      'lib/feature/startup_failure/bloc/startup_failure_bloc.dart',
      'lib/feature/startup_failure/bloc/startup_failure_event.dart',
      'lib/feature/startup_failure/bloc/startup_failure_state.dart',
      'lib/feature/startup_failure/di/startup_failure_scope.dart',
      'lib/feature/startup_failure/view/startup_failure_screen.dart',
    ];

    expect(File('lib/app/routing/not_found_route.dart').existsSync(), isFalse);
    expect(File('lib/app/view/not_found_screen.dart').existsSync(), isFalse);
    for (final path in requiredFiles) {
      expect(File(path).existsSync(), isTrue, reason: '$path must exist.');
    }
  });

  test('feature route decoders depend on fallback strategy, not NotFound', () {
    for (final path in <String>[
      'lib/feature/demo/routing/demo_routes.dart',
      'lib/feature/activity/routing/activity_routes.dart',
      'lib/feature/catalog/routing/catalog_routes.dart',
    ]) {
      final contents = File(path).readAsStringSync();
      expect(contents, contains('AppRouteFallbackBuilder'));
      expect(contents, contains('onInvalidRoute'));
      expect(
        contents,
        contains('AppRouteFailureReason.invalidParameters'),
      );
      expect(contents, isNot(contains('feature/not_found/')));
      expect(contents, isNot(contains('NotFoundRoute')));
    }
  });

  test(
    'only NotFound itself and application registry import its concrete route',
    () {
      final offenders = dartFiles('lib')
          .where((file) {
            final importsRoute = file
                .readAsLinesSync()
                .where((line) => line.trimLeft().startsWith('import '))
                .any(
                  (line) => line.contains(
                    'feature/not_found/routing/not_found_route.dart',
                  ),
                );
            final approved =
                file.path.endsWith('/app/routing/app_route_registry.dart') ||
                file.path.contains('/feature/not_found/');

            return importsRoute && !approved;
          })
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    },
  );

  test('Demo and Activity do not import the NotFound recovery feature', () {
    final offenders =
        <File>[
              ...dartFiles('lib/feature/demo'),
              ...dartFiles('lib/feature/activity'),
            ]
            .where(
              (file) => file.readAsStringSync().contains(
                'package:template/feature/not_found/',
              ),
            )
            .map((file) => file.path)
            .toList();

    expect(offenders, isEmpty);
  });

  test('startup failure feature remains isolated from the normal graph', () {
    const forbiddenImports = <String>[
      'package:template/app/routing/',
      'package:template/app/di/',
      'package:template/core/event_bus/',
    ];
    final offenders = dartFiles('lib/feature/startup_failure')
        .where((file) {
          final contents = file.readAsStringSync();

          return forbiddenImports.any(contents.contains);
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('application startup fallback is a thin framework wrapper', () {
    final contents = File(
      'lib/app/view/startup_failure_app.dart',
    ).readAsStringSync();

    expect(contents, contains('MaterialApp('));
    expect(contents, contains('StartupFailureScope('));
    expect(contents, contains('StartupFailureScreen()'));
    expect(contents, isNot(contains('Scaffold(')));
  });

  test('NotFound stores no attempted URI or query payload', () {
    final contents = dartFiles(
      'lib/feature/not_found',
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(contents, isNot(matches(RegExp(r'final\s+Uri\b'))));
    expect(
      contents,
      isNot(
        matches(
          RegExp(r'final\s+String\s+(?:uri|query|attemptedUri|rawUri)\b'),
        ),
      ),
    );
    expect(contents, isNot(contains('queryParameters')));
    expect(contents, isNot(contains('rawUri')));
  });

  test('concrete Activity route imports stay in approved locations', () {
    final offenders = dartFiles('lib')
        .where((file) {
          final importsRoute = file
              .readAsLinesSync()
              .where((line) => line.trimLeft().startsWith('import '))
              .any(_lineContainsActivityRouteImport);
          final approved =
              file.path.contains('/feature/activity/routing/') ||
              file.path.endsWith('/app/routing/app_navigator.dart');

          return importsRoute && !approved;
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('root App delegates initial-route policy to application routing', () {
    final contents = File('lib/app/view/app.dart').readAsStringSync();

    expect(contents, isNot(contains('package:template/feature/')));
    expect(contents, contains('initialAppRoutes'));
    expect(contents, contains('RouteNodePageBuilder<AppRoute>'));
    expect(contents, contains('pageBuilder: widget.pageBuilder'));
  });

  test('Page contribution SPI and application catalog stay separate', () {
    final definition = File(
      'lib/app/routing/app_route_page_definition.dart',
    ).readAsStringSync();
    final catalog = File(
      'lib/app/routing/app_route_page_catalog.dart',
    ).readAsStringSync();

    expect(
      definition,
      contains('abstract interface class AppRoutePageDefinition'),
    );
    expect(definition, contains('final class TypedAppRoutePageDefinition'));
    expect(definition, isNot(contains('final class AppRoutePageCatalog')));
    expect(catalog, contains('final class AppRoutePageCatalog'));
    expect(catalog, isNot(contains('final class TypedAppRoutePageDefinition')));
    expect(catalog, contains('app_route_page_definition.dart'));
  });

  test('routes and decoders use typed route-value contracts', () {
    final activityRoute = File(
      'lib/feature/activity/routing/activity_route.dart',
    ).readAsStringSync();
    final activityDecoders = File(
      'lib/feature/activity/routing/activity_routes.dart',
    ).readAsStringSync();
    final demoRoute = File(
      'lib/feature/demo/routing/demo_route.dart',
    ).readAsStringSync();
    final demoDecoders = File(
      'lib/feature/demo/routing/demo_routes.dart',
    ).readAsStringSync();
    final catalogRoute = File(
      'lib/feature/catalog/routing/catalog_route.dart',
    ).readAsStringSync();
    final catalogDecoders = File(
      'lib/feature/catalog/routing/catalog_routes.dart',
    ).readAsStringSync();
    final notFoundRoute = File(
      'lib/feature/not_found/routing/not_found_route.dart',
    ).readAsStringSync();

    expect(activityRoute, contains('ActivityRouteName.activity.value'));
    expect(activityDecoders, contains('ActivityRouteName.activity.value'));
    expect(demoRoute, contains('DemoRouteName.demo.value'));
    expect(demoDecoders, contains('DemoRouteName.demo.value'));
    expect(catalogRoute, contains('CatalogRouteName.catalog.value'));
    expect(catalogDecoders, contains('CatalogRouteName.catalog.value'));
    expect(notFoundRoute, contains('NotFoundRouteName.notFound.value'));

    final staticWireNames = dartFiles('lib')
        .where(
          (file) =>
              file.readAsStringSync().contains('static const String wireName'),
        )
        .map((file) => file.path)
        .toList();
    expect(staticWireNames, isEmpty);

    final rawWireNames = <String>[];
    for (final root in <String>[
      'lib/feature/activity/routing',
      'lib/feature/demo/routing',
      'lib/feature/catalog/routing',
      'lib/feature/not_found/routing',
    ]) {
      for (final file in dartFiles(
        root,
      ).where((file) => !file.path.endsWith('_route_name.dart'))) {
        if (RegExp(
          r'''['"](?:activity|catalog|demo|not-found)(?::[^'"]*)?['"]''',
        ).hasMatch(file.readAsStringSync())) {
          rawWireNames.add(file.path);
        }
      }
    }
    expect(rawWireNames, isEmpty);
  });
}

bool _lineContainsActivityRouteImport(String line) =>
    line.contains('feature/activity/routing/activity_route.dart');
