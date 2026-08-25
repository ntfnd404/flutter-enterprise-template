import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  test('DemoBloc construction stays inside its BLoC and feature DI', () {
    final offenders = dartFiles('lib')
        .where(
          (file) =>
              !file.path.endsWith('/feature/demo/bloc/demo_bloc.dart') &&
              !file.path.contains('/feature/demo/di/') &&
              file.readAsStringSync().contains('DemoBloc('),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('ActivityBloc construction stays inside its BLoC and feature DI', () {
    final offenders = dartFiles('lib')
        .where(
          (file) =>
              !file.path.endsWith(
                '/feature/activity/bloc/activity_bloc.dart',
              ) &&
              !file.path.contains('/feature/activity/di/') &&
              file.readAsStringSync().contains('ActivityBloc('),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('CatalogBloc construction stays inside its BLoC and feature DI', () {
    final offenders = dartFiles('lib')
        .where(
          (file) =>
              !file.path.endsWith('/feature/catalog/bloc/catalog_bloc.dart') &&
              !file.path.contains('/feature/catalog/di/') &&
              file.readAsStringSync().contains('CatalogBloc('),
        )
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('NotFound BLoC construction stays inside its BLoC and DI', () {
    const contracts = <String, (String, String)>{
      'NotFoundBloc(': (
        '/feature/not_found/bloc/not_found_bloc.dart',
        '/feature/not_found/di/',
      ),
    };
    final offenders = <String>[];

    for (final file in dartFiles('lib')) {
      final contents = file.readAsStringSync();
      for (final MapEntry(key: constructor, value: locations)
          in contracts.entries) {
        if (contents.contains(constructor) &&
            !file.path.endsWith(locations.$1) &&
            !file.path.contains(locations.$2)) {
          offenders.add(file.path);
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('application shell is not modeled as a feature', () {
    expect(Directory('lib/app').existsSync(), isTrue);
    expect(Directory('lib/feature/app').existsSync(), isFalse);
  });

  test('BLoC roots own action, event, and state part libraries', () {
    const libraries = <String, List<String>>{
      'lib/feature/activity/bloc/activity_bloc.dart': <String>[
        'activity_event.dart',
        'activity_state.dart',
      ],
      'lib/feature/demo/bloc/demo_bloc.dart': <String>[
        'demo_action.dart',
        'demo_event.dart',
        'demo_state.dart',
      ],
      'lib/feature/catalog/bloc/catalog_bloc.dart': <String>[
        'catalog_event.dart',
        'catalog_state.dart',
      ],
      'lib/feature/not_found/bloc/not_found_bloc.dart': <String>[
        'not_found_event.dart',
        'not_found_state.dart',
      ],
    };

    for (final MapEntry(key: root, value: companions) in libraries.entries) {
      final rootContents = File(root).readAsStringSync();
      final rootName = root.split('/').last;

      for (final companion in companions) {
        expect(
          rootContents,
          contains("part '$companion';"),
          reason: '$root must declare $companion as a part.',
        );
        expect(
          File('${File(root).parent.path}/$companion').readAsStringSync(),
          contains("part of '$rootName';"),
          reason: '$companion must belong to $rootName.',
        );
      }
    }
  });

  test('BLoC part libraries are never imported directly', () {
    const partImports = <String>{
      'feature/activity/bloc/activity_event.dart',
      'feature/activity/bloc/activity_state.dart',
      'feature/demo/bloc/demo_action.dart',
      'feature/demo/bloc/demo_event.dart',
      'feature/demo/bloc/demo_state.dart',
      'feature/catalog/bloc/catalog_event.dart',
      'feature/catalog/bloc/catalog_state.dart',
      'feature/not_found/bloc/not_found_event.dart',
      'feature/not_found/bloc/not_found_state.dart',
    };
    final offenders = <String>[];

    for (final file in <File>[...dartFiles('lib'), ...dartFiles('test')]) {
      final importedParts = file
          .readAsLinesSync()
          .where((line) => line.trimLeft().startsWith('import '))
          .where((line) => partImports.any(line.contains));
      if (importedParts.isNotEmpty) {
        offenders.add(file.path);
      }
    }

    expect(offenders, isEmpty);
  });

  test('application events live in the app-owned notification catalog', () {
    final eventFiles = dartFiles('lib/app/events').toList();
    expect(eventFiles, isNotEmpty);
    final invalidEvents = eventFiles
        .where((file) {
          final contents = file.readAsStringSync();

          return !file.path.endsWith('_app_event.dart') ||
              !RegExp(
                r'final\s+class\s+\w+AppEvent\s+extends\s+AppEvent\b',
              ).hasMatch(contents) ||
              contents.contains('package:flutter/') ||
              contents.contains('package:template/feature/');
        })
        .map((file) => file.path);
    expect(invalidEvents, isEmpty);
    expect(Directory('lib/core/event_bus/events').existsSync(), isFalse);

    final appEventDeclaration = RegExp(
      r'(?:final|base|sealed)\s+class\s+\w+AppEvent\s+'
      r'extends\s+AppEvent\b',
    );
    final misplacedEvents = dartFiles('lib')
        .where(
          (file) => appEventDeclaration.hasMatch(file.readAsStringSync()),
        )
        .where((file) => !file.path.contains('/app/events/'))
        .map((file) => file.path)
        .toList();
    expect(misplacedEvents, isEmpty);
  });

  test('business packages do not depend on application-shell events', () {
    const forbidden = <String>[
      'package:template/app/events/',
      'package:template/core/event_bus/app_event.dart',
      'package:template/core/event_bus/app_event_bus.dart',
    ];
    final offenders = dartFiles('packages')
        .where((file) {
          final contents = file.readAsStringSync();
          return forbidden.any(contents.contains);
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('BLoC input events do not inherit application events', () {
    final offenders = dartFiles('lib/feature')
        .where((file) => file.path.endsWith('_event.dart'))
        .where((file) => file.readAsStringSync().contains('AppEvent'))
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });

  test('features do not directly import one another', () {
    final offenders = <String>[];

    for (final file in dartFiles('lib/feature')) {
      final owner = file.path.split('/')[2];
      for (final uri in _packageImports(file).where(
        (uri) => uri.startsWith('package:template/feature/'),
      )) {
        final importedOwner = uri.split('/')[2];
        if (importedOwner != owner) {
          offenders.add('${file.path} -> $uri');
        }
      }
    }

    expect(offenders, isEmpty);
  });

  test('BLoC observer does not own application error reporting', () {
    final contents = File(
      'lib/app/diagnostics/logging/app_bloc_observer.dart',
    ).readAsStringSync();

    expect(contents, isNot(contains('AppErrorReporter')));
    expect(contents, isNot(contains('AppErrorReportKind')));
    expect(contents, isNot(contains('error.toString()')));
    expect(contents, contains('error.runtimeType'));
    expect(contents, isNot(contains(r'$error')));
  });

  test('Activity state is a bounded projection without event history', () {
    final contents = File(
      'lib/feature/activity/bloc/activity_state.dart',
    ).readAsStringSync();

    expect(contents, contains('observedCount'));
    expect(contents, contains('lastObservedSequence'));
    expect(contents, isNot(contains('List<')));
    expect(contents, isNot(contains('observedSequences')));
  });

  test('Activity has screen-owned DI and no app-lifetime flow scope', () {
    expect(
      File('lib/feature/activity/di/activity_scope.dart').existsSync(),
      isTrue,
    );
    expect(
      File('lib/feature/activity/di/activity_flow_scope.dart').existsSync(),
      isFalse,
    );
    final app = File('lib/app/view/app.dart').readAsStringSync();
    expect(app, isNot(contains('ActivityFlowScope')));
  });

  test(
    'views and route data do not use AppEventBus as a UI effect channel',
    () {
      final offenders = dartFiles('lib/feature')
          .where(
            (file) =>
                (file.path.contains('/view/') ||
                    (file.path.contains('/routing/') &&
                        !file.path.endsWith('_route_page.dart'))) &&
                file.readAsStringSync().contains('core/event_bus'),
          )
          .map((file) => file.path)
          .toList();

      expect(offenders, isEmpty);
    },
  );

  test(
    'route data stays UI-free and route Page adapters receive narrow ports',
    () {
      final routingFiles = dartFiles(
        'lib/feature',
      ).where((file) => file.path.contains('/routing/'));
      final routeDataOffenders = routingFiles
          .where((file) {
            final contents = file.readAsStringSync();
            final importsPresentation =
                contents.contains('/view/') || contents.contains('/di/');

            return importsPresentation &&
                !file.path.endsWith('_route_page.dart');
          })
          .map((file) => file.path)
          .toList();
      final routePageOffenders = routingFiles
          .where(
            (file) =>
                file.path.endsWith('_route_page.dart') &&
                file.readAsStringSync().contains(
                  'app/di/app_dependencies.dart',
                ),
          )
          .map((file) => file.path)
          .toList();
      final invalidPageComposition = dartFiles('lib/feature')
          .where(
            (file) =>
                file.path.contains('/page_composition/') &&
                !file.path.endsWith('_route_page.dart'),
          )
          .map((file) => file.path)
          .toList();

      expect(routeDataOffenders, isEmpty);
      expect(routePageOffenders, isEmpty);
      expect(invalidPageComposition, isEmpty);
      expect(
        File(
          'lib/feature/activity/routing/page_composition/'
          'activity_route_page.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/feature/catalog/routing/page_composition/'
          'catalog_route_page.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/feature/demo/routing/page_composition/'
          'demo_route_page.dart',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'lib/feature/not_found/routing/page_composition/'
          'not_found_route_page.dart',
        ).existsSync(),
        isTrue,
      );
    },
  );
}

Set<String> _packageImports(File file) => RegExp(
  r"^\s*import\s+'([^']+)';",
  multiLine: true,
).allMatches(file.readAsStringSync()).map((match) => match.group(1)!).toSet();
