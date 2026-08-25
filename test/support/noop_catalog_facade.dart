import 'package:catalog/catalog.dart';

/// Lifecycle-free catalog test double for tests unrelated to catalog behavior.
final class NoopCatalogFacade implements CatalogFacade {
  /// Creates a no-op facade.
  const NoopCatalogFacade();

  @override
  Future<void> archiveItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) => Future<void>.value();

  @override
  Future<void> createCategory(String name) => Future<void>.value();

  @override
  Future<void> createDraft({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  }) => Future<void>.value();

  @override
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) => Future<void>.value();

  @override
  Future<void> publishItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) => Future<void>.value();

  @override
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) => Future<void>.value();

  @override
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  }) => Future<void>.value();

  @override
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  }) => Future<void>.value();

  @override
  Stream<List<CatalogCategory>> watchCategories() =>
      const Stream<List<CatalogCategory>>.empty();

  @override
  Stream<List<CatalogItem>> watchItems() =>
      const Stream<List<CatalogItem>>.empty();
}
