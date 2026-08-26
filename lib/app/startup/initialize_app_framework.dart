import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/diagnostics/logging/app_bloc_observer.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/environment/app_environment.dart';
import 'package:template/app/startup/url_strategy.dart';

/// Applies required process-global framework policy before graph construction.
///
/// This stage owns no application-lifetime resources. Binding initialization,
/// configuration loading, dependency construction, and UI mounting remain the
/// responsibility of the composition root. Production invokes this function
/// once per root application startup. Its `Future<void>` contract remains
/// intentional while the current implementation is synchronous because a
/// future required SDK step may need awaited initialization.
///
/// Example:
/// ```dart
/// final configuration = loadAppStartupConfiguration();
/// await initializeAppFramework(
///   environment: configuration.environment,
///   logger: logger,
/// );
/// ```
Future<void> initializeAppFramework({
  required AppEnvironment environment,
  required AppLogger logger,
}) => Future.sync(() {
  configureUrlStrategy(environment.urlStrategy);
  Bloc.observer = AppBlocObserver(logger: logger);

  // Required process-global SDK initialization belongs here.
  //
  // Examples:
  // - await Firebase.initializeApp() when Firebase is required by the graph;
  // - register an FCM background handler when the plugin requires a top-level
  //   process callback;
  // - await a native database engine's process-global preparation when the
  //   selected engine explicitly requires it before opening connections. The
  //   current Drift integration does not require this step.
  //
  // Before adding an initializer, document whether repeated calls are
  // idempotent or unsafe, whether retry is supported, which failures are
  // terminal, and how its policy composes with other initializers. Do not
  // introduce one generic lifecycle policy for unrelated SDKs.
  //
  // A required step propagates its failure. An optional analytics or
  // observability provider owns a reviewed degradation and reporting policy
  // when the app can continue without it; raw failures never enter AppLogger.
  //
  // Do not open a Drift database, obtain SharedPreferences for a repository,
  // create a notifications service, start a socket/session, or construct a
  // Sentry/Crashlytics transport here. Those objects have root, graph/module,
  // feature, page, or operation ownership. Never retain FirebaseApp,
  // repositories, adapters, SDK clients, or another disposable handle inside
  // initializeAppFramework.
});
