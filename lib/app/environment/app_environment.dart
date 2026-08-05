import 'package:template/app/environment/app_environment_exception.dart';
import 'package:template/app/environment/app_environment_keys.dart';
import 'package:template/app/environment/app_environment_kind.dart';
import 'package:template/app/environment/app_url_strategy.dart';

/// Immutable public client configuration selected before application startup.
///
/// Only non-secret values that may safely be compiled into a client
/// application belong here. Runtime services and SDK instances are created by
/// the dependency graph instead.
final class AppEnvironment {
  const AppEnvironment._({
    required this.kind,
    required this.urlStrategy,
  });

  /// Parses and validates raw dart-define values.
  ///
  /// A future business bounded context owns its capability configuration. For
  /// example, a context introduced with a real use case may expose:
  /// ```dart
  /// final configuration = CapabilityConfiguration.fromValues(
  ///   mode: rawMode,
  /// );
  /// ```
  ///
  /// `CapabilityConfiguration` is an illustrative name, not a type supplied by
  /// the scaffold. The real type belongs to its owning `packages/<context>`.
  /// The application loader remains the only production source that reads
  /// compile-time dart-defines. Context factories receive raw values explicitly
  /// and create typed immutable configuration, concrete SDK objects are created
  /// later by their composition layer, and this root factory owns only
  /// cross-capability validation.
  factory AppEnvironment.fromValues({
    required String environment,
    required String urlStrategy,
  }) {
    final kind = switch (environment) {
      'local' => AppEnvironmentKind.local,
      'dev' => AppEnvironmentKind.dev,
      'prod' => AppEnvironmentKind.prod,
      _ => throw const AppEnvironmentException(
        'Invalid ${AppEnvironmentKeys.environment}. Expected local, dev, or prod.',
      ),
    };
    final parsedUrlStrategy = switch (urlStrategy) {
      'hash' => AppUrlStrategy.hash,
      'path' => AppUrlStrategy.path,
      _ => throw const AppEnvironmentException(
        'Invalid ${AppEnvironmentKeys.urlStrategy}. Expected hash or path.',
      ),
    };

    return AppEnvironment._(
      kind: kind,
      urlStrategy: parsedUrlStrategy,
    );
  }

  /// The deployment environment used by capability configuration.
  final AppEnvironmentKind kind;

  /// The browser URL strategy; non-Web platforms safely ignore this value.
  final AppUrlStrategy urlStrategy;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AppEnvironment && other.kind == kind && other.urlStrategy == urlStrategy;

  @override
  int get hashCode => Object.hash(kind, urlStrategy);
}
