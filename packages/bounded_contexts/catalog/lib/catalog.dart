/// Public application API of the catalog bounded context.
///
/// Flutter presentation imports this library. Drift, DAOs, repository
/// implementations, and physical database ownership remain outside this
/// public application API. Expected operational failures and unexpected data
/// integrity failures have distinct public types.
library;

export 'src/application/catalog_facade.dart';
export 'src/domain/catalog_exception.dart'
    show
        CatalogCategoryNotFoundException,
        CatalogDataIntegrityException,
        CatalogException,
        CatalogExpectedException,
        CatalogInvalidCategoryNameException,
        CatalogInvalidDescriptionException,
        CatalogInvalidPriceException,
        CatalogInvalidTitleException,
        CatalogItemNotFoundException,
        CatalogItemPublicationException,
        CatalogItemPublicationFailure,
        CatalogItemTransitionException,
        CatalogItemTransitionFailure,
        CatalogPersistenceException;
export 'src/domain/category/catalog_category.dart';
export 'src/domain/category/value_objects/catalog_category_name.dart';
export 'src/domain/item/catalog_item.dart';
export 'src/domain/item/value_objects/catalog_item_description.dart';
export 'src/domain/item/value_objects/catalog_item_price.dart';
export 'src/domain/item/value_objects/catalog_item_revision.dart';
export 'src/domain/item/value_objects/catalog_item_status.dart';
export 'src/domain/item/value_objects/catalog_item_title.dart';
