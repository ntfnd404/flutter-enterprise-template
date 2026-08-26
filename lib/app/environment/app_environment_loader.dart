import 'package:template/app/environment/app_environment_keys.dart';
import 'package:template/app/environment/app_startup_configuration.dart';

/// Loads and validates the complete compile-time startup configuration.
///
/// This is the only production source file that reads `String.fromEnvironment`.
/// It cannot inspect the original dart-define file after compilation, so CI/CD
/// must validate that exact file before invoking Flutter. The injected values
/// are independently checked through [AppStartupConfiguration.fromValues].
AppStartupConfiguration loadAppStartupConfiguration() =>
    AppStartupConfiguration.fromValues(
      environment: const String.fromEnvironment(
        AppEnvironmentKeys.environment,
      ),
      urlStrategy: const String.fromEnvironment(
        AppEnvironmentKeys.urlStrategy,
      ),
      storageNamespace: const String.fromEnvironment(
        AppEnvironmentKeys.storageNamespace,
      ),
    );
