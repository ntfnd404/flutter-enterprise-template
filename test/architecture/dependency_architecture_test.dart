import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  const graphPath = 'lib/app/di/app_dependency_graph.dart';
  const ownerPath = 'lib/app/di/app_dependency_graph_owner.dart';
  const registrarPath = 'lib/app/di/app_resource_registrar.dart';
  const failurePath = 'lib/app/di/app_resource_disposal_exception.dart';
  const compositionPath = 'lib/app/di/app_dependencies_factory.dart';
  const startupCompositionPath = 'lib/app/startup/run_application.dart';

  test('generic graph primitives remain Flutter and business neutral', () {
    final offenders =
        [
          graphPath,
          registrarPath,
          failurePath,
        ].where((path) {
          final contents = File(path).readAsStringSync();

          return contents.contains('package:flutter/') ||
              contents.contains('app_dependencies.dart') ||
              contents.contains('package:app_database/') ||
              contents.contains('package:catalog/') ||
              contents.contains('package:ordering/') ||
              contents.contains('/diagnostics/') ||
              contents.contains('/routing/') ||
              contents.contains('package:template/feature/');
        }).toList();

    expect(offenders, isEmpty);
  });

  test('the root graph owner is the only Flutter-aware DI primitive', () {
    final flutterAware = dartFiles('lib/app/di')
        .where(
          (file) => file.readAsStringSync().contains('package:flutter/'),
        )
        .map((file) => file.path)
        .toList();

    expect(flutterAware, [ownerPath]);
  });

  test('database platform dependency stays in its concrete adapter', () {
    final pathProviderImporters = dartFiles('lib/app/di')
        .where(
          (file) => file.readAsStringSync().contains('package:path_provider/'),
        )
        .map((file) => file.path)
        .toList();

    expect(pathProviderImporters, [
      'lib/app/di/modules/database/database_native_path_io.dart',
    ]);
  });

  test(
    'resource registrar exposes registration without lifecycle authority',
    () {
      final registrar = File(registrarPath).readAsStringSync();

      expect(
        registrar,
        contains('abstract interface class AppResourceRegistrar'),
      );
      expect(registrar, contains('R register<R extends Object>('));
      expect(
        registrar,
        isNot(matches(RegExp(r'\b(?:seal|dispose|isSealed)\s*\('))),
      );
    },
  );

  test('private ledger and graph construction cannot be bypassed', () {
    final graph = File(graphPath).readAsStringSync();
    final externalLedgerUsers = dartFiles('lib/app/di')
        .where((file) => file.path != graphPath)
        .where(
          (file) => file.readAsStringSync().contains('_AppResourceLedger'),
        )
        .map((file) => file.path)
        .toList();

    expect(graph, contains('final class _AppResourceLedger'));
    expect(graph, contains('AppDependencyGraph._('));
    expect(graph, isNot(contains('AppDependencyGraph.owned')));
    expect(externalLedgerUsers, isEmpty);
    expect(
      File('lib/app/di/app_dependency_graph_builder.dart').existsSync(),
      isFalse,
    );
    expect(
      File('lib/app/di/app_resource_disposal_stack.dart').existsSync(),
      isFalse,
    );
  });

  test('only the Flutter owner claims root graph ownership', () {
    final callers = dartFiles('lib')
        .where((file) => file.path != graphPath && file.path != ownerPath)
        .where(
          (file) => file.readAsStringSync().contains('.claimRootOwnership()'),
        )
        .map((file) => file.path)
        .toList();
    final owner = File(ownerPath).readAsStringSync();

    expect(callers, isEmpty);
    expect(owner, contains('_graph.claimRootOwnership()'));
    expect(owner, isNot(matches(RegExp(r'extends\s+InheritedWidget\b'))));
    expect(owner, isNot(contains('AppDependencies get')));
  });

  test('production graph disposal is limited to the Flutter owner', () {
    final callers = dartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains('_graph.dispose()'),
        )
        .map((file) => file.path)
        .toList();

    expect(callers, [ownerPath]);
  });

  test('business composition is isolated from graph primitives', () {
    const entrypoints = {
      'package:app_database/app_database_composition.dart': [
        compositionPath,
        'lib/app/di/modules/database/app_database_configuration_factory.dart',
      ],
      'package:catalog/catalog_composition.dart': [compositionPath],
      'package:ordering/ordering_composition.dart': [compositionPath],
    };

    for (final MapEntry(key: entrypoint, value: expected)
        in entrypoints.entries) {
      final importers = dartFiles('lib')
          .where(
            (file) => file.readAsStringSync().contains(entrypoint),
          )
          .map((file) => file.path)
          .toList();

      expect(importers, unorderedEquals(expected));
    }
  });

  test('dependency catalog is typed and lifecycle-free', () {
    final dependencies = File(
      'lib/app/di/app_dependencies.dart',
    ).readAsStringSync();

    expect(dependencies, contains('final class const AppDependencies({'));
    expect(dependencies, contains('required final CatalogFacade catalog,'));
    expect(dependencies, contains('required final OrderingFacade ordering,'));
    expect(dependencies, isNot(contains('AppEventBus')));
    expect(dependencies, isNot(contains('AppEventPublisher')));
    expect(dependencies, isNot(contains('AppEventSubscriber')));
    expect(dependencies, isNot(contains('AppResourceRegistrar')));
    expect(dependencies, isNot(matches(RegExp(r'Future<void>\s+dispose\('))));
    expect(dependencies, isNot(matches(RegExp(r'\b(?:Map|dynamic)\b'))));
    expect(dependencies, isNot(matches(RegExp(r'\bget<T>\s*\('))));
    expect(dependencies, isNot(contains('BlocFactory')));
  });

  test('the DI snapshot does not compose the future EventBus', () {
    final eventBusImporters = dartFiles('lib/app/di')
        .where(
          (file) => file.readAsStringSync().contains('/event_bus/'),
        )
        .map((file) => file.path)
        .toList();

    expect(eventBusImporters, isEmpty);
  });

  test('only app DI and the composition root may read the full graph API', () {
    final offenders = dartFiles('lib')
        .where((file) => !file.path.startsWith('lib/app/di/'))
        .where((file) {
          final contents = file.readAsStringSync();

          return contents.contains(
                'package:template/app/di/app_dependencies.dart',
              ) ||
              contents.contains(
                'package:template/app/di/app_dependency_graph.dart',
              ) ||
              contents.contains(
                'package:template/app/di/app_resource_registrar.dart',
              );
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, [startupCompositionPath]);
  });

  test('no accepted production caller reads dependency catalog fields yet', () {
    final consumers = dartFiles('lib')
        .where((file) => !file.path.startsWith('lib/app/di/'))
        .where((file) {
          final contents = file.readAsStringSync();

          return contents.contains('dependencies.catalog') ||
              contents.contains('dependencies.ordering');
        })
        .map((file) => file.path)
        .toList();

    expect(consumers, isEmpty);
  });

  test('core and workspace packages remain independent of app DI', () {
    final coreOffenders = dartFiles('lib/core')
        .where((file) {
          final contents = file.readAsStringSync();

          return contents.contains('package:template/app/') ||
              contents.contains('package:template/feature/');
        })
        .map((file) => file.path)
        .toList();
    final packageOffenders = dartFiles('packages')
        .where(
          (file) => file.readAsStringSync().contains('package:template/'),
        )
        .map((file) => file.path)
        .toList();

    expect(coreOffenders, isEmpty);
    expect(packageOffenders, isEmpty);
  });

  test('obsolete lookup and ownership APIs remain absent', () {
    final offenders = dartFiles('lib')
        .where((file) {
          final contents = file.readAsStringSync();

          return contents.contains('AppDependencyGraphHandle') ||
              contents.contains('AppDependenciesBuilder') ||
              contents.contains('AppScope.of(') ||
              contents.contains('AppDependencyGraphOwner.of(') ||
              contents.contains('package:template/core/di/app_');
        })
        .map((file) => file.path)
        .toList();

    expect(offenders, isEmpty);
  });
}
