import 'package:template/app/environment/app_environment.dart';
import 'package:template/app/environment/storage/app_storage_configuration.dart';

/// Typed compile-time configuration consumed only by application startup.
///
/// This aggregate is a composition input, not a dependency catalog. Startup
/// immediately passes [environment] and [storage] to their narrow consumers;
/// widgets, BLoCs, repositories, and packages never receive this object.
///
/// Package-specific configuration is added only with a real consumer, remains
/// owned by that package, and is narrowed to its module factory during
/// composition. Detailed extension recipes belong in `doc/architecture.md`;
/// hypothetical implementations do not belong in this public API reference.
final class AppStartupConfiguration {
  /// Creates a startup configuration from already validated components.
  const AppStartupConfiguration({
    required this.environment,
    required this.storage,
  });

  /// Parses the complete set of raw application dart-define values.
  factory AppStartupConfiguration.fromValues({
    required String environment,
    required String urlStrategy,
    required String storageNamespace,
  }) => AppStartupConfiguration(
    environment: AppEnvironment.fromValues(
      environment: environment,
      urlStrategy: urlStrategy,
    ),
    storage: AppStorageConfiguration.fromValues(
      namespace: storageNamespace,
    ),
  );

  /// App-wide deployment and framework policy.
  final AppEnvironment environment;

  /// App-wide identity policy for local persistent storage.
  final AppStorageConfiguration storage;
}
