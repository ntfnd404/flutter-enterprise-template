import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/logging/records/app_startup_log_records.dart';
import 'package:template/app/startup/run_application.dart';

import 'support/run_application_test_support.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'returns before graph readiness then mounts and disposes one owned graph',
    (tester) async {
      final originalObserver = Bloc.observer;
      final originalFlutterHandler = FlutterError.onError;
      final originalPlatformHandler = binding.platformDispatcher.onError;
      final logger = StartupTestLogger();
      final reporter = StartupTestReporter();
      final boundaryCapture = StartupBoundaryCapture();
      final graphReady = Completer<AppDependencies>();
      final graphStarted = Completer<void>();
      final operations = <String>[];
      var resourceDisposed = false;
      var graphWasMounted = false;

      try {
        runApplication(
          logger: logger,
          errorReporter: reporter,
          errorBoundaryFactory: boundaryCapture.create,
          configurationLoader: () {
            operations.add('configuration');
            expect(WidgetsBinding.instance, isNotNull);
            expect(FlutterError.onError, isNot(originalFlutterHandler));
            expect(
              binding.platformDispatcher.onError,
              isNot(originalPlatformHandler),
            );

            return validStartupConfiguration();
          },
          frameworkInitializer:
              ({required environment, required logger}) async {
                operations.add('framework');
              },
          dependenciesFactory: (resources) {
            operations.add('graph');
            graphStarted.complete();
            resources.register(Object(), (_) {
              resourceDisposed = true;
            });

            return graphReady.future;
          },
        );

        expect(identical(boundaryCapture.logger, logger), isTrue);
        expect(identical(boundaryCapture.reporter, reporter), isTrue);
        expect(
          find.byKey(const ValueKey('normal-app-marker')),
          findsNothing,
        );
        expect(
          logger.records.whereType<AppStartupStartedLogRecord>(),
          hasLength(1),
        );
        expect(
          logger.records.whereType<AppStartupCompletedLogRecord>(),
          isEmpty,
        );
        expect(operations, ['configuration', 'framework']);

        await graphStarted.future;
        expect(operations, ['configuration', 'framework', 'graph']);
        expect(
          find.byKey(const ValueKey('normal-app-marker')),
          findsNothing,
        );

        graphReady.complete(testAppDependencies());
        await logger.waitForCount(2);
        await pumpUntilFound(
          tester,
          find.byKey(const ValueKey('normal-app-marker')),
        );
        graphWasMounted = true;

        expect(find.text('Template running'), findsOneWidget);
        expect(reporter.reports, isEmpty);
        expect(
          logger.records.whereType<AppStartupCompletedLogRecord>(),
          hasLength(1),
        );

        await unmountAndDisposeGraph(tester);
        graphWasMounted = false;
        expect(resourceDisposed, isTrue);
      } finally {
        try {
          if (graphWasMounted) {
            await unmountAndDisposeGraph(tester);
          }
        } finally {
          restoreStartupGlobals(
            observer: originalObserver,
            boundaryCapture: boundaryCapture,
          );
        }
      }

      expect(FlutterError.onError, same(originalFlutterHandler));
      expect(
        binding.platformDispatcher.onError,
        same(originalPlatformHandler),
      );
    },
  );

  testWidgets('reports normal graph disposal failure with its exact kind', (
    tester,
  ) async {
    final originalObserver = Bloc.observer;
    final logger = StartupTestLogger();
    final reporter = StartupTestReporter();
    final boundaryCapture = StartupBoundaryCapture();
    final disposalFailure = StateError('private teardown detail');

    try {
      runApplication(
        logger: logger,
        errorReporter: reporter,
        errorBoundaryFactory: boundaryCapture.create,
        configurationLoader: validStartupConfiguration,
        frameworkInitializer: ({required environment, required logger}) =>
            Future.value(),
        dependenciesFactory: (resources) async {
          resources.register(Object(), (_) => throw disposalFailure);

          return testAppDependencies();
        },
      );
      await logger.waitForCount(2);
      await pumpUntilFound(
        tester,
        find.byType(AppDependencyGraphOwner),
      );
      final owner = tester.widget<AppDependencyGraphOwner>(
        find.byType(AppDependencyGraphOwner),
      );
      final graph = owner.graph;

      await tester.pumpWidget(const SizedBox.shrink());
      await expectLater(graph.dispose(), throwsA(isA<Exception>()));
      await reporter.waitForCompletedCount(1);

      expect(
        reporter.reports.single.kind,
        AppErrorReportKind.dependencyDisposal,
      );
    } finally {
      restoreStartupGlobals(
        observer: originalObserver,
        boundaryCapture: boundaryCapture,
      );
    }
  });
}
