import 'package:app_database/stores/catalog.dart';
import 'package:catalog/src/application/catalog_service.dart';
import 'package:catalog/src/application/product_offers/catalog_product_offer_service.dart';
import 'package:catalog/src/composition/catalog_application.dart';
import 'package:catalog/src/domain/item/policies/catalog_item_publication_policy.dart';
import 'package:catalog/src/infrastructure/persistence/store_catalog_category_repository.dart';
import 'package:catalog/src/infrastructure/persistence/store_catalog_item_repository.dart';

/// Composes Catalog's internal application implementation over borrowed stores.
///
/// This is the bounded context's composition boundary: it hides the concrete
/// repository, domain policy, and application service from app-owned DI. The
/// shared application database retains ownership of [itemsStore] and
/// [categoriesStore]; every object created here is lifecycle-free and closes
/// neither store.
///
/// The returned [CatalogApplication] is a temporary composition view, not a
/// dependency for presentation or another bounded context. App-owned DI must
/// immediately narrow the same instance to `CatalogFacade` for presentation
/// and `CatalogProductOfferReader` for an authorized downstream integration.
/// It must not expose `CatalogApplication` through `AppDependencies`.
CatalogApplication createCatalogApplication({
  required CatalogItemsStore itemsStore,
  required CatalogCategoriesStore categoriesStore,
}) {
  final items = StoreCatalogItemRepository(itemsStore);
  final categories = StoreCatalogCategoryRepository(categoriesStore);
  final facade = CatalogService(
    items,
    categories,
    const CatalogItemPublicationPolicy(),
  );

  return CatalogApplication(
    facade: facade,
    productOffers: CatalogProductOfferService(items),
  );
}
