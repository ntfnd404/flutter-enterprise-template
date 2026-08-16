import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/category/catalog_category.dart';
import 'package:catalog/src/domain/item/catalog_item.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_status.dart';

/// Domain policy governing the transition from draft to published product.
final class CatalogItemPublicationPolicy {
  /// Creates the stateless publication policy.
  const CatalogItemPublicationPolicy();

  /// Validates publication when [item] and [category] satisfy every rule.
  void validatePublication({
    required CatalogItem item,
    required CatalogCategory? category,
  }) {
    if (item.status != CatalogItemStatus.draft) {
      throw const CatalogItemPublicationException(
        CatalogItemPublicationFailure.itemNotDraft,
      );
    }
    _validateOffer(item: item, category: category);
  }

  /// Validates the revised details of an already-published product.
  void validatePublishedOffer({
    required CatalogItem item,
    required CatalogCategory? category,
  }) {
    if (item.status != CatalogItemStatus.published) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.itemNotPublished,
      );
    }
    _validateOffer(item: item, category: category);
  }

  void _validateOffer({
    required CatalogItem item,
    required CatalogCategory? category,
  }) {
    item.validateOfferCompleteness();
    if (category == null) {
      throw const CatalogItemPublicationException(
        CatalogItemPublicationFailure.categoryRequired,
      );
    }
    if (category.id != item.categoryId || !category.isActive) {
      throw const CatalogItemPublicationException(
        CatalogItemPublicationFailure.activeCategoryRequired,
      );
    }
  }
}
