import 'package:template/app/environment/app_environment.dart';
import 'package:template/app/environment/app_environment_keys.dart';

/// Loads and validates the compile-time application environment.
///
/// This is the only production source file that reads `String.fromEnvironment`.
/// It cannot inspect the original dart-define file after compilation, so CI/CD
/// must validate that exact file before invoking Flutter. The injected values
/// are independently checked through [AppEnvironment.fromValues] at startup.
AppEnvironment loadEnvironment() => AppEnvironment.fromValues(
  environment: const String.fromEnvironment(
    AppEnvironmentKeys.environment,
  ),
  urlStrategy: const String.fromEnvironment(
    AppEnvironmentKeys.urlStrategy,
  ),
);
