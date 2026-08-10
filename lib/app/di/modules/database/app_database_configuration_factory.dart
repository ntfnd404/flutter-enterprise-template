import 'package:app_database/app_database_composition.dart';
import 'package:template/app/environment/storage/app_storage_namespace.dart';

import 'database_native_path.dart';

/// Creates platform-specific configuration for the shared application database.
///
/// Derives an isolated storage identity from [storageNamespace], resolves an
/// absolute application-owned path on native platforms, and requires persistent
/// storage on Web.
Future<AppDatabaseConfiguration> createAppDatabaseConfiguration({
  required AppStorageNamespace storageNamespace,
}) async {
  final databaseName = 'template_${storageNamespace.value}';
  final nativePath = await resolveNativeDatabasePath(
    fileName: '$databaseName.sqlite',
  );

  return AppDatabaseConfiguration(
    databaseName: databaseName,
    nativePath: nativePath,
    webStoragePolicy: AppDatabaseWebStoragePolicy.requirePersistent,
  );
}
