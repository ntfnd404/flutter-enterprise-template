import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/di/app_dependencies_factory.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/di/app_resource_disposal_exception.dart';
import 'package:template/app/di/app_resource_registrar.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_formatter.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/diagnostics/logging/developer_app_logger.dart';
import 'package:template/app/diagnostics/logging/records/app_startup_log_records.dart';
import 'package:template/app/environment/app_environment.dart';
import 'package:template/app/environment/app_environment_loader.dart';
import 'package:template/app/environment/app_startup_configuration.dart';
import 'package:template/app/startup/initialize_app_framework.dart';
import 'package:template/app/view/app.dart';
import 'package:template/app/view/startup_failure_app.dart';

/// Creates the one root-isolate error boundary used by application startup.
typedef AppErrorBoundaryFactory = AppErrorBoundary Function({
  required AppLogger logger,
  required AppErrorReporter reporter,
});

/// Starts the application inside one root diagnostics and ownership boundary.
///
/// Optional collaborators are narrow test seams. Production calls this
/// function without overrides. The function intentionally returns `void` so a
/// Future never crosses the guarded error-Zone boundary. A supplied boundary
/// factory receives the exact resolved logger and reporter identities and must
/// not substitute either collaborator. Tests own a boundary they create
/// through that factory and dispose it only after report and graph quiescence.
/// [dependenciesFactory] is the sole graph-construction seam; production uses
/// [buildAppDependencies].
void runApplication({
  AppLogger? logger,
  AppErrorReporter? errorReporter,
  AppErrorBoundaryFactory? errorBoundaryFactory,
  AppStartupConfiguration Function() configurationLoader =
      loadAppStartupConfiguration,
  Future<void> Function({
        required AppEnvironment environment,
        required AppLogger logger,
      })
      frameworkInitializer =
      initializeAppFramework,
  Future<AppDependencies> Function(AppResourceRegistrar resources)?
  dependenciesFactory,
}) {
  final resolvedLogger = logger ?? DeveloperAppLogger();
  final resolvedReporter =
      errorReporter ??
      LocalAppErrorReporter(formatter: AppErrorFormatter.forCurrentBuild());
  final boundary = (errorBoundaryFactory ?? _createAppErrorBoundary)(
    logger: resolvedLogger,
    reporter: resolvedReporter,
  );

  boundary.run(
    () => _startApplication(
      boundary: boundary,
      logger: resolvedLogger,
      configurationLoader: configurationLoader,
      frameworkInitializer: frameworkInitializer,
      dependenciesFactory: dependenciesFactory,
    ),
  );
}

AppErrorBoundary _createAppErrorBoundary({
  required AppLogger logger,
  required AppErrorReporter reporter,
}) => AppErrorBoundary(logger: logger, reporter: reporter);

Future<void> _startApplication({
  required AppErrorBoundary boundary,
  required AppLogger logger,
  required AppStartupConfiguration Function() configurationLoader,
  required Future<void> Function({
    required AppEnvironment environment,
    required AppLogger logger,
  })
  frameworkInitializer,
  required Future<AppDependencies> Function(AppResourceRegistrar resources)?
  dependenciesFactory,
}) async {
  var bindingInitialized = false;
  var primaryKind = AppErrorReportKind.startup;
  AppDependencyGraph<AppDependencies>? graph;
  final rollbackFailures = <_StartupCleanupFailure>[];

  try {
    if (kDebugMode) {
      BindingBase.debugZoneErrorsAreFatal = true;
    }
    WidgetsFlutterBinding.ensureInitialized();
    bindingInitialized = true;

    final stopwatch = Stopwatch()..start();
    logger.log(const AppStartupStartedLogRecord());

    primaryKind = AppErrorReportKind.environment;
    final configuration = configurationLoader();

    primaryKind = AppErrorReportKind.startup;
    await frameworkInitializer(
      environment: configuration.environment,
      logger: logger,
    );

    // Graph construction finishes its own rollback before it throws. This
    // callback records only secondary cleanup failures so outward reporting
    // remains primary-first.
    graph = await buildAppDependencyGraph(
      dependenciesFactory:
          dependenciesFactory ??
          (resources) => buildAppDependencies(
            resources,
            storageConfiguration: configuration.storage,
          ),
      captureRollbackFailure: (error, stackTrace) {
        rollbackFailures.add(_StartupCleanupFailure(error, stackTrace));
      },
    );

    final builtGraph = graph;
    runApp(
      AppDependencyGraphOwner(
        graph: builtGraph,
        onDisposalFailure: (error, stackTrace) => boundary.report(
          error,
          stackTrace,
          kind: AppErrorReportKind.dependencyDisposal,
        ),
        child: App(dependencies: builtGraph.dependencies),
      ),
    );
    graph = null;

    stopwatch.stop();
    logger.log(AppStartupCompletedLogRecord(stopwatch.elapsed));
  } catch (error, stackTrace) {
    await boundary.report(error, stackTrace, kind: primaryKind);

    final unclaimedGraph = graph;
    if (unclaimedGraph != null) {
      final cleanupFailure = await _disposePreHandoffGraph(unclaimedGraph);
      if (cleanupFailure != null) {
        rollbackFailures.add(cleanupFailure);
      }
    }

    for (final failure in rollbackFailures) {
      await boundary.report(
        failure.error,
        failure.stackTrace,
        kind: AppErrorReportKind.dependencyRollback,
      );
    }

    // Do not catch fallback mounting with another startup handler. If the safe
    // fallback itself cannot mount, that terminal failure must escape to the
    // root Zone instead of recursively attempting the same fallback.
    if (bindingInitialized) {
      runApp(StartupFailureApp(diagnosticCode: primaryKind.code));
    }
  }
}

Future<_StartupCleanupFailure?> _disposePreHandoffGraph(
  AppDependencyGraph<AppDependencies> graph,
) async {
  try {
    await graph.dispose();

    return null;
  } on AppResourceDisposalException catch (error, stackTrace) {
    return _StartupCleanupFailure(error, stackTrace);
  } catch (error, stackTrace) {
    return _StartupCleanupFailure(
      AppResourceDisposalException([
        AppResourceDisposalFailure(error: error, stackTrace: stackTrace),
      ]),
      stackTrace,
    );
  }
}

final class _StartupCleanupFailure {
  const _StartupCleanupFailure(this.error, this.stackTrace);

  final AppResourceDisposalException error;
  final StackTrace stackTrace;
}
