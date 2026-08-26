import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_description.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_price.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_revision.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_status.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_title.dart';

/// Immutable catalog entity exposed by the catalog application API.
///
/// Entity equality is based only on [id]. A newer authoritative snapshot may
/// therefore contain an equal entity with different renderable fields. Callers
/// that detect presentation changes must compare those fields explicitly.
final class CatalogItem {
  const CatalogItem._({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.categoryId,
    required this.revision,
  });

  /// Creates an item after validating context-owned invariants.
  ///
  /// This factory is also the only reconstitution path used by persistence
  /// adapters. Invalid stored data is rejected without retaining its value.
  factory CatalogItem.fromValues({
    required int id,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int statusValue,
    required int? categoryId,
    required int revision,
  }) {
    if (id <= 0) {
      throw const CatalogDataIntegrityException();
    }
    if (categoryId != null && categoryId <= 0) {
      throw const CatalogDataIntegrityException();
    }
    final validatedTitle = CatalogItemTitle.fromStored(title);
    final validatedDescription = CatalogItemDescription.fromStored(
      description,
    );
    final validatedPrice = CatalogItemPrice.fromStored(
      minorUnits: priceMinorUnits,
      currencyCode: currencyCode,
    );
    final validatedStatus = CatalogItemStatus.fromStored(statusValue);
    if (validatedStatus != CatalogItemStatus.draft &&
        _offerCompletenessFailure(
              description: validatedDescription,
              price: validatedPrice,
              categoryId: categoryId,
            ) !=
            null) {
      throw const CatalogDataIntegrityException();
    }

    return CatalogItem._(
      id: id,
      title: validatedTitle,
      description: validatedDescription,
      price: validatedPrice,
      status: validatedStatus,
      categoryId: categoryId,
      revision: CatalogItemRevision.fromStored(revision),
    );
  }

  /// Stable identifier assigned by the owning catalog context.
  final int id;

  /// Canonical user-visible title accepted by the domain.
  final CatalogItemTitle title;

  /// Canonical product description. Drafts may keep it empty.
  final CatalogItemDescription description;

  /// Non-negative price represented in minor currency units.
  final CatalogItemPrice price;

  /// Current lifecycle state with a stable persistence representation.
  final CatalogItemStatus status;

  /// Assigned category, or `null` while a draft is incomplete.
  final int? categoryId;

  /// Optimistic concurrency token of this authoritative snapshot.
  final CatalogItemRevision revision;

  /// Returns a revised copy when this item is still a draft.
  CatalogItem reviseDraft({
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) {
    if (status != CatalogItemStatus.draft) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.itemNotDraft,
      );
    }
    if (categoryId != null && categoryId <= 0) {
      throw const CatalogCategoryNotFoundException();
    }

    return CatalogItem._(
      id: id,
      title: title,
      description: description,
      price: price,
      status: status,
      categoryId: categoryId,
      revision: revision,
    );
  }

  /// Returns revised details when this item is currently published.
  CatalogItem revisePublishedOffer({
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int categoryId,
  }) {
    if (status != CatalogItemStatus.published) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.itemNotPublished,
      );
    }
    if (categoryId <= 0) {
      throw const CatalogCategoryNotFoundException();
    }

    final revised = CatalogItem._(
      id: id,
      title: title,
      description: description,
      price: price,
      status: status,
      categoryId: categoryId,
      revision: revision,
    );
    revised.validateOfferCompleteness();

    return revised;
  }

  /// Validates the item-owned requirements of a publishable offer.
  ///
  /// Category activation is a cross-aggregate rule and remains the
  /// responsibility of `CatalogItemPublicationPolicy`.
  void validateOfferCompleteness() {
    final failure = _offerCompletenessFailure(
      description: description,
      price: price,
      categoryId: categoryId,
    );
    if (failure != null) {
      throw CatalogItemPublicationException(failure);
    }
  }

  /// Returns an archived copy when this item is currently published.
  CatalogItem archive() {
    if (status != CatalogItemStatus.published) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.itemNotPublished,
      );
    }

    return _withStatus(CatalogItemStatus.archived);
  }

  CatalogItem _withStatus(CatalogItemStatus nextStatus) => CatalogItem._(
    id: id,
    title: title,
    description: description,
    price: price,
    status: nextStatus,
    categoryId: categoryId,
    revision: revision,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CatalogItem && id == other.id;

  @override
  int get hashCode => id.hashCode;

  static CatalogItemPublicationFailure? _offerCompletenessFailure({
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) {
    if (description.isEmpty) {
      return CatalogItemPublicationFailure.descriptionRequired;
    }
    if (price.minorUnits <= 0) {
      return CatalogItemPublicationFailure.positivePriceRequired;
    }
    if (price.currencyCode == 'XXX') {
      return CatalogItemPublicationFailure.concreteCurrencyRequired;
    }
    if (categoryId == null) {
      return CatalogItemPublicationFailure.categoryRequired;
    }

    return null;
  }
}
