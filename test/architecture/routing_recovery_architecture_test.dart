import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('application routing owns the typed route and navigation contracts', () {
    const requiredFiles = <String>[
      'lib/app/routing/activity_navigation.dart',
      'lib/app/routing/app_navigator.dart',
      'lib/app/routing/app_navigator_context.dart',
      'lib/app/routing/app_pages.dart',
      'lib/app/routing/app_route.dart',
      'lib/app/routing/app_route_fallback.dart',
      'lib/app/routing/app_route_page_catalog.dart',
      'lib/app/routing/app_route_page_definition.dart',
      'lib/app/routing/app_route_registry.dart',
      'lib/app/routing/app_route_url_codec.dart',
      'lib/app/routing/catalog_navigation.dart',
    ];

    for (final path in requiredFiles) {
      expect(File(path).existsSync(), isTrue, reason: '$path must exist.');
    }
    expect(Directory('lib/core/routing').existsSync(), isFalse);
    expect(Directory('lib/feature/app').existsSync(), isFalse);
  });

  test('AppNavigator stays bare and feature-neutral', () {
    final contents = File(
      'lib/app/routing/app_navigator.dart',
    ).readAsStringSync();

    expect(contents, contains('extends NavigationController<AppRoute>'));
    expect(contents, isNot(contains('package:template/feature/')));
    expect(contents, isNot(contains('implements ActivityNavigation')));
    expect(contents, isNot(contains('implements CatalogNavigation')));
    expect(contents, isNot(contains('openActivity')));
    expect(contents, isNot(contains('openCatalog')));
  });

  test('narrow navigation adapters are private app composition', () {
    final contents = File(
      'lib/app/routing/app_navigator_context.dart',
    ).readAsStringSync();

    expect(contents, contains('final class _ActivityNavigationAdapter'));
    expect(contents, contains('final class _CatalogNavigationAdapter'));
    expect(contents, contains('ActivityNavigation get activityNavigation'));
    expect(contents, contains('CatalogNavigation get catalogNavigation'));
    expect(
      contents,
      isNot(matches(RegExp(r'AppNavigator\s+get\s+navigator\b'))),
    );
    expect(contents, isNot(contains('AppDependencies')));
    expect(contents, isNot(contains('register(')));
  });

  test('concrete feature imports stay at exact app composition points', () {
    const approved = <String, Set<String>>{
      'lib/app/routing/app_navigator_context.dart': <String>{
        'package:template/feature/activity/routing/activity_route.dart',
        'package:template/feature/catalog/routing/catalog_route.dart',
      },
      'lib/app/routing/app_pages.dart': <String>{
        'package:template/feature/activity/routing/page_composition/activity_route_page.dart',
        'package:template/feature/catalog/routing/page_composition/catalog_route_page.dart',
        'package:template/feature/demo/routing/page_composition/demo_route_page.dart',
        'package:template/feature/not_found/routing/page_composition/not_found_route_page.dart',
      },
      'lib/app/routing/app_route_registry.dart': <String>{
        'package:template/feature/activity/routing/activity_routes.dart',
        'package:template/feature/catalog/routing/catalog_routes.dart',
        'package:template/feature/demo/routing/demo_route.dart',
        'package:template/feature/demo/routing/demo_routes.dart',
        'package:template/feature/not_found/routing/not_found_route.dart',
      },
      'lib/app/routing/app_route_url_codec.dart': <String>{
        'package:template/feature/not_found/routing/not_found_route.dart',
      },
    };
    final importers = dartFiles('lib/app')
        .where(
          (file) =>
              file.readAsStringSync().contains('package:template/feature/'),
        )
        .map((file) => file.path)
        .toSet();

    expect(importers, approved.keys.toSet());
    for (final entry in approved.entries) {
      expect(
        _packageImports(File(entry.key))
            .where((uri) => uri.startsWith('package:template/feature/'))
            .toSet(),
        entry.value,
        reason: '${entry.key} has an unreviewed concrete feature import.',
      );
    }
  });

  test('feature decoders depend on fallback policy, not NotFound', () {
    for (final path in <String>[
      'lib/feature/demo/routing/demo_routes.dart',
      'lib/feature/activity/routing/activity_routes.dart',
      'lib/feature/catalog/routing/catalog_routes.dart',
    ]) {
      final contents = File(path).readAsStringSync();
      expect(contents, contains('AppRouteFallbackBuilder'));
      expect(contents, contains('onInvalidRoute'));
      expect(contents, contains('AppRouteFailureReason.invalidParameters'));
      expect(contents, isNot(contains('feature/not_found/')));
      expect(contents, isNot(contains('NotFoundRoute')));
    }
  });

  test('recovery route is imported only by its feature and app policy', () {
    const approved = <String>{
      'lib/app/routing/app_route_registry.dart',
      'lib/app/routing/app_route_url_codec.dart',
    };
    final offenders = dartFiles('lib')
        .where((file) {
          if (file.path.contains('/feature/not_found/')) {
            return false;
          }

          return file.readAsStringSync().contains(
            'feature/not_found/routing/not_found_route.dart',
          );
        })
        .map((file) => file.path)
        .where((path) => !approved.contains(path))
        .toList();

    expect(offenders, isEmpty);
  });

  test('every Page adapter uses the feature page-composition boundary', () {
    const expected = <String>{
      'lib/feature/activity/routing/page_composition/activity_route_page.dart',
      'lib/feature/catalog/routing/page_composition/catalog_route_page.dart',
      'lib/feature/demo/routing/page_composition/demo_route_page.dart',
      'lib/feature/not_found/routing/page_composition/not_found_route_page.dart',
    };
    final actual = dartFiles('lib/feature')
        .where((file) => file.path.endsWith('_route_page.dart'))
        .map((file) => file.path)
        .toSet();

    expect(actual, expected);
    for (final path in actual) {
      final contents = File(path).readAsStringSync();
      expect(contents, contains('key: route.pageKey'));
      expect(contents, isNot(contains('app/di/app_dependencies.dart')));
      expect(contents, isNot(contains('/bloc/')));
      expect(contents, isNot(contains("import 'dart:io'")));
      expect(contents, isNot(contains('Future<')));
      expect(contents, isNot(contains(' async')));
      expect(contents, isNot(contains('.dispose(')));
    }
  });

  test('production route implementations remain final', () {
    const routes = <String, String>{
      'lib/feature/activity/routing/activity_route.dart': 'ActivityRoute',
      'lib/feature/catalog/routing/catalog_route.dart': 'CatalogRoute',
      'lib/feature/demo/routing/demo_route.dart': 'DemoRoute',
      'lib/feature/not_found/routing/not_found_route.dart': 'NotFoundRoute',
    };

    for (final entry in routes.entries) {
      final contents = File(entry.key).readAsStringSync();
      expect(
        contents,
        contains('final class ${entry.value} extends AppRoute'),
        reason: '${entry.value} must be a final AppRoute implementation.',
      );
      expect(contents, isNot(matches(RegExp(r'\bset\s+\w+\s*\('))));
    }
  });

  test('route data stays free of UI composition and owned resources', () {
    final offenders = dartFiles('lib/feature')
        .where((file) => file.path.contains('/routing/'))
        .where((file) => !file.path.contains('/page_composition/'))
        .where((file) {
          final contents = file.readAsStringSync();

          return contents.contains('/view/') ||
              contents.contains('/di/') ||
              contents.contains('package:flutter_bloc/') ||
              contents.contains('Repository') ||
              contents.contains('Facade');
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('route names are owned by feature enums', () {
    const contracts = <String, String>{
      'activity': 'lib/feature/activity/routing',
      'catalog': 'lib/feature/catalog/routing',
      'demo': 'lib/feature/demo/routing',
      'not-found': 'lib/feature/not_found/routing',
    };

    for (final MapEntry(key: wireName, value: root) in contracts.entries) {
      final nameFiles = dartFiles(
        root,
      ).where((file) => file.path.endsWith('_route_name.dart')).toList();
      expect(nameFiles, hasLength(1));
      expect(nameFiles.single.readAsStringSync(), contains("'$wireName'"));

      for (final file in dartFiles(root).where(
        (file) => !file.path.endsWith('_route_name.dart'),
      )) {
        if (file.path.contains('/page_composition/')) {
          continue;
        }
        expect(
          file.readAsStringSync(),
          isNot(contains("'$wireName'")),
          reason: '${file.path} must use the route-name enum value.',
        );
      }
    }
  });

  test('URL safety policy is bounded and never stringifies Page keys', () {
    final contents = File(
      'lib/app/routing/app_route_url_codec.dart',
    ).readAsStringSync();

    expect(contents, contains('_maxLocationLength = 4096'));
    expect(contents, contains('_maxPathSegmentCount = 32'));
    expect(contents, contains("uri.path.split('/')"));
    expect(contents, isNot(contains('uri.pathSegments')));
    expect(contents, contains('_hasInvalidOrDuplicateParameters(uri)'));
    expect(contents, contains('_hasInvalidOrDuplicateParameterChannel'));
    expect(contents, contains('_decodeParameterComponent'));
    expect(contents, contains('Uri.decodeQueryComponent(source)'));
    expect(contents, contains('Uri.decodeComponent(source)'));
    expect(contents, contains('on ArgumentError'));
    expect(
      RegExp(r'\btry\s*\{').allMatches(contents),
      hasLength(1),
    );
    final preflightBody = contents.substring(
      contents.indexOf('bool _hasInvalidOrDuplicateParameters(Uri uri)'),
      contents.indexOf('String? _decodeParameterComponent('),
    );
    expect(preflightBody, isNot(contains('try {')));
    expect(contents, contains('AppRouteFailureReason.invalidRouteTree'));
    expect(contents, contains('List<AppRoute>.unmodifiable(decoded)'));
    expect(contents, isNot(contains('pageKey.toString()')));
    expect(contents, isNot(contains(r'$pageKey')));
    expect(contents, isNot(contains('catch (')));
    final decodeBody = contents.substring(
      contents.indexOf('List<AppRoute> decode(Uri uri)'),
      contents.indexOf('bool _hasInvalidOrDuplicateParameters(Uri uri)'),
    );
    expect(decodeBody, isNot(contains('try {')));
  });

  test('NotFound stores no attempted URI, query, or raw failure', () {
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
    expect(contents, isNot(contains('Object error')));
    expect(contents, isNot(contains('StackTrace')));
  });

  test('root App resolves codec before allocating routing resources', () {
    final contents = File('lib/app/view/app.dart').readAsStringSync();
    final parser = contents.indexOf(
      '_routeInformationParser = RoutingInformationParser<AppRoute>',
    );
    final state = contents.indexOf('_routesState = RoutesState<AppRoute>');
    final delegate = contents.indexOf(
      '_routerDelegate = RoutingDelegate<AppRoute>',
    );

    expect(contents, isNot(contains('package:template/feature/')));
    expect(contents, isNot(contains('package:ui_kit/')));
    expect(contents, contains('appRouteUrlCodec'));
    expect(contents, contains('_pageBuilder = widget.pageBuilder'));
    expect(contents, contains('pageBuilder: _pageBuilder'));
    expect(contents, contains('widget.pageBuilder != _pageBuilder'));
    expect(
      contents,
      contains(
        'App does not support replacing its Page-building strategy.',
      ),
    );
    expect(parser, greaterThanOrEqualTo(0));
    expect(state, greaterThan(parser));
    expect(delegate, greaterThan(state));
    expect(
      contents.indexOf('_routerDelegate.dispose()'),
      greaterThan(delegate),
    );
    expect(
      contents.indexOf('_routesState.dispose()'),
      greaterThan(contents.indexOf('_routerDelegate.dispose()')),
    );
  });

  test('routing phase excludes speculative navigation capabilities', () {
    final contents = dartFiles(
      'lib/app/routing',
    ).map((file) => file.readAsStringSync()).join('\n');

    expect(contents, isNot(contains('GuardedPipeline')));
    expect(contents, isNot(contains('NavigationHistory')));
    expect(contents, isNot(contains('pushForResult')));
    expect(contents, isNot(contains('Base64')));
    expect(contents, isNot(contains('EntryQueryStore')));
    expect(Directory('lib/app/routing/guards').existsSync(), isFalse);
  });

  test('routing dependency and default production URL strategy are exact', () {
    final manifest = File('pubspec.yaml').readAsStringSync();
    final lock = File('pubspec.lock').readAsStringSync();
    final productionEnvironment = File('env/prod.env').readAsStringSync();

    expect(manifest, contains('  rolter: 0.2.1'));
    expect(manifest, isNot(contains('  ui_kit:')));
    expect(lock, contains('version: "0.2.1"'));
    expect(
      lock,
      contains(
        'sha256: "1298704af8fcc8fabab98b9b7af4f04b9b795497c419e85d4cc309a8dc9e3966"',
      ),
    );
    expect(productionEnvironment, contains('APP_URL_STRATEGY=hash'));
  });

  test('Demo-owned navigation extension is isolated from other features', () {
    const path = 'lib/feature/demo/routing/demo_navigation.dart';
    expect(File(path).readAsStringSync(), contains('on AppNavigator'));

    final offenders = dartFiles('lib/feature')
        .where((file) => !file.path.contains('/feature/demo/'))
        .where(
          (file) => file.readAsStringSync().contains(
            'feature/demo/routing/demo_navigation.dart',
          ),
        )
        .map((file) => file.path)
        .toList();
    expect(offenders, isEmpty);
  });
}

Set<String> _packageImports(File file) => RegExp(
  r"^\s*import\s+'([^']+)';",
  multiLine: true,
).allMatches(file.readAsStringSync()).map((match) => match.group(1)!).toSet();
