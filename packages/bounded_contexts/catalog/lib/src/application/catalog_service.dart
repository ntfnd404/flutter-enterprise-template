import 'package:catalog/src/application/catalog_facade.dart';
import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/category/catalog_category.dart';
import 'package:catalog/src/domain/category/value_objects/catalog_category_name.dart';
import 'package:catalog/src/domain/item/catalog_item.dart';
import 'package:catalog/src/domain/item/policies/catalog_item_publication_policy.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_description.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_price.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_revision.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_status.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_title.dart';
import 'package:catalog/src/domain/repository/catalog_category_repository.dart';
import 'package:catalog/src/domain/repository/catalog_item_repository.dart';

/// Default catalog application service.
final class CatalogService implements CatalogFacade {
  /// Creates the service over the context-owned persistence port.
  const CatalogService(
    this._items,
    this._categories,
    this._publicationPolicy,
  );

  final CatalogItemRepository _items;
  final CatalogCategoryRepository _categories;
  final CatalogItemPublicationPolicy _publicationPolicy;

  @override
  Stream<List<CatalogItem>> watchItems() => _items.watchItems();

  @override
  Stream<List<CatalogCategory>> watchCategories() =>
      _categories.watchCategories();

  @override
  Future<void> createDraft({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  }) async {
    final validatedTitle = CatalogItemTitle.fromUserInput(title);
    final validatedDescription = CatalogItemDescription.fromUserInput(
      description,
    );
    final validatedPrice = CatalogItemPrice.fromUserInput(
      minorUnits: priceMinorUnits,
      currencyCode: currencyCode,
    );
    if (categoryId != null) {
      _validateIdentifier(categoryId, isCategory: true);
      if (await _categories.getCategory(categoryId) == null) {
        throw const CatalogCategoryNotFoundException();
      }
    }

    await _items.createDraft(
      title: validatedTitle,
      description: validatedDescription,
      price: validatedPrice,
      categoryId: categoryId,
    );
  }

  @override
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  }) async {
    _validateIdentifier(id);
    final validatedTitle = CatalogItemTitle.fromUserInput(title);
    final validatedDescription = CatalogItemDescription.fromUserInput(
      description,
    );
    final validatedPrice = CatalogItemPrice.fromUserInput(
      minorUnits: priceMinorUnits,
      currencyCode: currencyCode,
    );
    final current = await _items.getItem(id);
    _requireExpectedRevision(current, expectedRevision);
    final revised = current.reviseDraft(
      title: validatedTitle,
      description: validatedDescription,
      price: validatedPrice,
      categoryId: categoryId,
    );
    if (categoryId != null) {
      _validateIdentifier(categoryId, isCategory: true);
      if (await _categories.getCategory(categoryId) == null) {
        throw const CatalogCategoryNotFoundException();
      }
    }
    current.revision.next();

    await _items.updateDraft(
      id: id,
      expectedRevision: expectedRevision,
      title: revised.title,
      description: revised.description,
      price: revised.price,
      categoryId: revised.categoryId,
    );
  }

  @override
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  }) async {
    _validateIdentifier(id);
    final validatedTitle = CatalogItemTitle.fromUserInput(title);
    final validatedDescription = CatalogItemDescription.fromUserInput(
      description,
    );
    final validatedPrice = CatalogItemPrice.fromUserInput(
      minorUnits: priceMinorUnits,
      currencyCode: currencyCode,
    );
    final current = await _items.getItem(id);
    _requireExpectedRevision(current, expectedRevision);
    final revised = current.revisePublishedOffer(
      title: validatedTitle,
      description: validatedDescription,
      price: validatedPrice,
      categoryId: categoryId,
    );
    final category = await _categories.getCategory(categoryId);
    if (category == null) {
      throw const CatalogCategoryNotFoundException();
    }
    _publicationPolicy.validatePublishedOffer(
      item: revised,
      category: category,
    );
    current.revision.next();

    await _items.updatePublishedOffer(
      id: id,
      expectedRevision: expectedRevision,
      title: revised.title,
      description: revised.description,
      price: revised.price,
      categoryId: categoryId,
    );
  }

  @override
  Future<void> createCategory(String name) async {
    final validatedName = CatalogCategoryName.fromUserInput(name);
    await _categories.createCategory(validatedName);
  }

  @override
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    _validateIdentifier(id, isCategory: true);
    await _categories.setCategoryActive(id: id, isActive: isActive);
  }

  @override
  Future<void> publishItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    _validateIdentifier(id);
    final item = await _items.getItem(id);
    _requireExpectedRevision(item, expectedRevision);
    final categoryId = item.categoryId;
    final category = categoryId == null
        ? null
        : await _categories.getCategory(categoryId);
    _publicationPolicy.validatePublication(
      item: item,
      category: category,
    );
    item.revision.next();
    await _items.publishDraft(
      id: item.id,
      expectedRevision: expectedRevision,
      requiredActiveCategoryId: item.categoryId!,
    );
  }

  @override
  Future<void> archiveItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    _validateIdentifier(id);
    final item = await _items.getItem(id);
    _requireExpectedRevision(item, expectedRevision);
    final archived = item.archive();
    archived.revision.next();
    await _items.archivePublished(
      id: archived.id,
      expectedRevision: expectedRevision,
    );
  }

  @override
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    _validateIdentifier(id);
    final item = await _items.getItem(id);
    _requireExpectedRevision(item, expectedRevision);
    if (item.status != CatalogItemStatus.draft) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.itemNotDraft,
      );
    }
    item.revision.next();
    await _items.deleteDraft(id: id, expectedRevision: expectedRevision);
  }

  void _requireExpectedRevision(
    CatalogItem item,
    CatalogItemRevision expectedRevision,
  ) {
    if (item.revision != expectedRevision) {
      throw const CatalogItemTransitionException(
        CatalogItemTransitionFailure.concurrentStateChange,
      );
    }
  }

  void _validateIdentifier(int id, {bool isCategory = false}) {
    if (id > 0) {
      return;
    }
    if (isCategory) {
      throw const CatalogCategoryNotFoundException();
    }
    throw const CatalogItemNotFoundException();
  }
}
