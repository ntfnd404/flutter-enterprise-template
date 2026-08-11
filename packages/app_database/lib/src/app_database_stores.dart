import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/contexts/catalog/catalog_database_stores.dart';

/// Typed context store catalog published by a ready database module.
///
/// This object groups borrowed, lifecycle-free context views. Application
/// composition must narrow it immediately and must not pass it to bounded
/// contexts or presentation.
final class AppDatabaseStores {
  AppDatabaseStores._({required this.catalog});

  /// Catalog-owned persistence stores.
  final CatalogDatabaseStores catalog;
}

/// Creates all context store views over an initialized [database].
///
/// The assembly is synchronous, performs no queries, and creates no
/// independently disposable resources. It is package-internal by placement
/// under `lib/src` and is intentionally absent from public entrypoints.
AppDatabaseStores createAppDatabaseStores(ApplicationDatabase database) =>
    AppDatabaseStores._(catalog: createCatalogDatabaseStores(database));
