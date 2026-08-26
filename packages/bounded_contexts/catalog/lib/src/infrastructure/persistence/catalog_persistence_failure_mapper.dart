import 'package:app_database/stores/catalog.dart';
import 'package:catalog/src/domain/catalog_exception.dart';

/// Executes [operation] and translates only expected Catalog store contention.
Future<T> guardCatalogPersistence<T>(Future<T> Function() operation) async {
  try {
    return await operation();
  } on CatalogStoreException catch (_, stackTrace) {
    throwCatalogPersistence(stackTrace);
  }
}

/// Throws Catalog's sanitized persistence failure with [stackTrace].
Never throwCatalogPersistence(StackTrace stackTrace) =>
    Error.throwWithStackTrace(const CatalogPersistenceException(), stackTrace);
