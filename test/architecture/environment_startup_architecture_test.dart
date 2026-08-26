import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/architecture_files.dart';

void main() {
  const mainPath = 'lib/main.dart';
  const startupRoot = 'lib/app/startup';
  const initializerPath = '$startupRoot/initialize_app_framework.dart';
  const runApplicationPath = '$startupRoot/run_application.dart';
  const normalAppPath = 'lib/app/view/app.dart';
  const fallbackPath = 'lib/app/view/startup_failure_app.dart';

  test('Startup has the exact reviewed runtime surface', () {
    final startupFiles = dartFiles(
      startupRoot,
    ).map((file) => file.path).toList()..sort();

    expect(startupFiles, [
      initializerPath,
      runApplicationPath,
      '$startupRoot/url_strategy.dart',
      '$startupRoot/url_strategy_stub.dart',
      '$startupRoot/url_strategy_web.dart',
    ]);
    expect(File('lib/app/startup/app_bootstrap.dart').existsSync(), isFalse);

    final production = dartFiles('lib')
        .map((file) => file.readAsStringSync())
        .join('\n');
    expect(production, isNot(contains('class AppBootstrap')));
    expect(production, isNot(contains('AppBootstrap.')));
  });

  test(
    'framework initialization is narrow, synchronous-entry, and non-owning',
    () {
      final initializer = File(initializerPath).readAsStringSync();
      final imports = RegExp(
        r"^import '([^']+)';$",
        multiLine: true,
      ).allMatches(initializer).map((match) => match.group(1)).toList();

      expect(initializer, contains('Future<void> initializeAppFramework({'));
      expect(initializer, contains('}) => Future.sync(() {'));
      expect(imports, [
        'package:flutter_bloc/flutter_bloc.dart',
        'package:template/app/diagnostics/logging/app_bloc_observer.dart',
        'package:template/app/diagnostics/logging/app_logger.dart',
        'package:template/app/environment/app_environment.dart',
        'package:template/app/startup/url_strategy.dart',
      ]);
      expect(
        initializer.indexOf('configureUrlStrategy(environment.urlStrategy);'),
        lessThan(initializer.indexOf('Bloc.observer = AppBlocObserver')),
      );
      for (final forbidden in [
        'WidgetsFlutterBinding',
        'String.fromEnvironment',
        'buildAppDependencies',
        'runApp(',
      ]) {
        expect(initializer, isNot(contains(forbidden)));
      }
    },
  );

  test(
    'the entrypoint delegates and runApplication preserves Startup order',
    () {
      final main = File(mainPath).readAsStringSync();
      final runApplication = File(runApplicationPath).readAsStringSync();
      final startupBody = runApplication.substring(
        runApplication.indexOf('Future<void> _startApplication'),
      );
      final orderedFragments = [
        'BindingBase.debugZoneErrorsAreFatal = true;',
        'WidgetsFlutterBinding.ensureInitialized();',
        'final stopwatch = Stopwatch()..start();',
        'logger.log(const AppStartupStartedLogRecord());',
        'final configuration = configurationLoader();',
        'await frameworkInitializer(',
        'graph = await buildAppDependencyGraph(',
        'runApp(',
        'graph = null;',
        'logger.log(AppStartupCompletedLogRecord(stopwatch.elapsed));',
      ];
      var previousIndex = -1;
      for (final fragment in orderedFragments) {
        final index = startupBody.indexOf(fragment);
        expect(index, greaterThan(previousIndex), reason: fragment);
        previousIndex = index;
      }

      expect(main, contains('void main() => runApplication();'));
      expect(
        main,
        contains(
          "import 'package:template/app/startup/run_application.dart';",
        ),
      );
      expect(main, isNot(contains('AppErrorBoundary')));
      expect(main, isNot(contains('AppDependencyGraph')));
      expect(runApplication, contains('boundary.run('));
      expect(runApplication, contains('logger: resolvedLogger'));
      expect(runApplication, contains('reporter: resolvedReporter'));
      expect(
        runApplication.indexOf('final boundary ='),
        lessThan(runApplication.indexOf('boundary.run(')),
      );
    },
  );

  test('only runApplication composes and disposes the pre-handoff graph', () {
    final graphImporters = dartFiles('lib')
        .where((file) => !file.path.startsWith('lib/app/di/'))
        .where((file) {
          final source = file.readAsStringSync();

          return source.contains('app_dependencies.dart') ||
              source.contains('app_dependency_graph.dart') ||
              source.contains('app_resource_registrar.dart');
        })
        .map((file) => file.path)
        .toList();
    final runApplication = File(runApplicationPath).readAsStringSync();

    expect(graphImporters, [runApplicationPath]);
    expect(runApplication, contains('await graph.dispose();'));
    expect(
      File('lib/app/di/app_dependency_graph_owner.dart').readAsStringSync(),
      contains('await _graph.dispose();'),
    );
  });

  test('normal and fallback root views remain graph and router free', () {
    for (final path in [normalAppPath, fallbackPath]) {
      final source = File(path).readAsStringSync();

      expect(source, contains("import 'package:flutter/material.dart';"));
      for (final forbidden in [
        '/app/di/',
        '/routing/',
        '/feature/',
        'ui_kit',
        'flutter_bloc',
        'AppDependencies',
        'AppDependencyGraph',
      ]) {
        expect(source, isNot(contains(forbidden)));
      }
    }
  });

  test(
    'URL setup is conditional and every tracked profile defaults to hash',
    () {
      final dispatcher = File('$startupRoot/url_strategy.dart')
          .readAsStringSync();
      final web = File('$startupRoot/url_strategy_web.dart').readAsStringSync();
      final webPluginImporters = dartFiles('lib')
          .where(
            (file) => file.readAsStringSync().contains(
              'package:flutter_web_plugins/',
            ),
          )
          .map((file) => file.path)
          .toList();

      expect(dispatcher, contains('if (dart.library.js_interop)'));
      expect(webPluginImporters, [
        '$startupRoot/url_strategy_web.dart',
      ]);
      expect(web, contains('HashUrlStrategy'));
      expect(web, contains('usePathUrlStrategy'));

      for (final profile in [
        'env/local.env',
        'env/dev.env',
        'env/test.env',
        'env/prod.env',
      ]) {
        expect(
          File(profile).readAsStringSync(),
          contains('APP_URL_STRATEGY=hash'),
          reason: profile,
        );
      }
    },
  );

  test('the Web plugin is the only Startup dependency contract', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final lockfile = File('pubspec.lock').readAsStringSync();

    expect(
      pubspec,
      contains('flutter_web_plugins:\n    sdk: flutter'),
    );
    expect(lockfile, contains('flutter_web_plugins:'));
    expect(pubspec, isNot(contains('go_router:')));
    expect(pubspec, isNot(contains('rolter:')));
    expect(pubspec, isNot(contains('ui_kit:')));
  });
}
