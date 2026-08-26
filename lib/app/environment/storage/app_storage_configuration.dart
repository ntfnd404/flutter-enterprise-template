import 'package:template/app/environment/storage/app_storage_namespace.dart';

/// App-wide configuration shared by local persistence composition adapters.
///
/// This type owns storage identity policy but no database, preferences, cache,
/// or other runtime resource. Concrete modules derive their provider-specific
/// configuration from [namespace] and retain their own lifecycle.
final class AppStorageConfiguration {
  /// Creates storage configuration from an already validated [namespace].
  const AppStorageConfiguration({required this.namespace});

  /// Parses raw compile-time storage values.
  factory AppStorageConfiguration.fromValues({required String namespace}) =>
      AppStorageConfiguration(
        namespace: AppStorageNamespace.fromValue(namespace),
      );

  /// Namespace separating all app-owned local storage between profiles.
  final AppStorageNamespace namespace;
}
