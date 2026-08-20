import 'package:template/app/diagnostics/logging/app_log_record.dart';

/// Stable application-owned kinds of unhandled failure reports.
///
/// A kind identifies the root or orchestration boundary that observed a
/// failure. It is not an exception taxonomy, severity, analytics dimension,
/// or provider-routing instruction.
enum AppErrorReportKind {
  /// A failure that escaped through the guarded root application Zone.
  rootZone('root_zone', 'APP-ROOT-001', 'Root zone'),

  /// A failure raised while loading or validating the Environment.
  environment('environment', 'APP-ENVIRONMENT-001', 'Environment'),

  /// A synchronous or asynchronous startup failure.
  startup('startup', 'APP-STARTUP-001', 'Startup'),

  /// A failure routed through Flutter's framework error callback.
  flutterFramework(
    'flutter_framework',
    'APP-FRAMEWORK-001',
    'Flutter framework',
  ),

  /// A failure routed through the root isolate platform dispatcher.
  platformDispatcher(
    'platform_dispatcher',
    'APP-PLATFORM-001',
    'Platform dispatcher',
  ),

  /// A secondary failure raised while rolling back graph construction.
  dependencyRollback(
    'dependency_rollback',
    'APP-DI-ROLLBACK-001',
    'Dependency rollback',
  ),

  /// A failure raised while disposing a successfully built application graph.
  dependencyDisposal(
    'dependency_disposal',
    'APP-DI-DISPOSE-001',
    'Dependency disposal',
  );

  const AppErrorReportKind(this.wireValue, this.code, this.label);

  /// Stable machine-readable report-origin value.
  final String wireValue;

  /// Stable, non-sensitive support identifier.
  final String code;

  /// Static English label suitable for support-only diagnostics.
  final String label;

  /// Typed support code used by safe operational breadcrumbs.
  AppLogStableCode get supportCode => AppLogStableCode(code);
}
