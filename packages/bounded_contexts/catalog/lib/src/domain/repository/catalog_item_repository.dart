import 'package:catalog/src/domain/item/catalog_item.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_description.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_price.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_revision.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_title.dart';

/// Domain-owned persistence port for the Catalog item aggregate.
abstract interface class CatalogItemRepository {
  /// Observes authoritative items in stable identifier order.
  Stream<List<CatalogItem>> watchItems();

  /// Loads one item or throws the context-owned not-found failure.
  Future<CatalogItem> getItem(int id);

  /// Loads existing items without interpreting their lifecycle state.
  Future<List<CatalogItem>> findItemsByIds(Set<int> ids);

  /// Stores a new draft from validated domain values.
  Future<void> createDraft({
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  });

  /// Replaces draft details optimistically.
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  });

  /// Replaces a published offer optimistically.
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int categoryId,
  });

  /// Publishes a draft while its assigned category remains active.
  Future<void> publishDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required int requiredActiveCategoryId,
  });

  /// Archives a published item optimistically.
  Future<void> archivePublished({
    required int id,
    required CatalogItemRevision expectedRevision,
  });

  /// Deletes a draft optimistically.
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  });
}
