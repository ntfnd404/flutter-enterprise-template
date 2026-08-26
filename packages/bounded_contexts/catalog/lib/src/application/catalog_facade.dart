import 'package:catalog/src/domain/catalog_exception.dart';
import 'package:catalog/src/domain/category/catalog_category.dart';
import 'package:catalog/src/domain/item/catalog_item.dart';
import 'package:catalog/src/domain/item/value_objects/catalog_item_revision.dart';

/// Public application boundary of the catalog bounded context.
///
/// Implementations are lifecycle-free. Callers own stream subscriptions but
/// never the borrowed persistence resources behind this facade.
/// Every command future completes only after its local write commits; commands
/// without a useful caller-owned payload return `Future<void>`.
/// Unexpected failures, including [CatalogDataIntegrityException], propagate
/// unchanged to the owning error boundary.
abstract interface class CatalogFacade {
  /// Creates a single-subscription stream of authoritative catalog snapshots.
  ///
  /// Each call creates an independent observation. Subscription first emits
  /// the current immutable snapshot and then changes in ascending
  /// database-assigned ID order. Cancellation propagates to the source.
  ///
  /// The stream does not retry or resubscribe. A persistence failure,
  /// unexpected failure, or normal completion terminates this observation. A
  /// caller retries by invoking [watchItems] again. Temporary persistence
  /// contention is reported as [CatalogPersistenceException]; data-integrity
  /// and other unexpected failures propagate unchanged.
  Stream<List<CatalogItem>> watchItems();

  /// Creates an independent observation of authoritative categories.
  ///
  /// It has the same ownership, termination, and retry contract as
  /// [watchItems], including [CatalogPersistenceException] for temporary
  /// contention and propagation of unexpected failures.
  Stream<List<CatalogCategory>> watchCategories();

  /// Validates and creates an unpublished product draft.
  ///
  /// Throws [CatalogInvalidTitleException],
  /// [CatalogInvalidDescriptionException], or [CatalogInvalidPriceException]
  /// for invalid input; [CatalogCategoryNotFoundException] for an invalid or
  /// missing category; and [CatalogPersistenceException] for expected
  /// temporary contention.
  Future<void> createDraft({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  });

  /// Validates and replaces the details of an existing draft.
  ///
  /// [expectedRevision] must come from the authoritative item snapshot on
  /// which the caller based this command. Throws the matching invalid-value
  /// exception, [CatalogItemNotFoundException],
  /// [CatalogCategoryNotFoundException], or [CatalogPersistenceException]. A
  /// non-draft item or stale/concurrently changed revision produces
  /// [CatalogItemTransitionException].
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  });

  /// Validates and replaces details of an already-published product.
  ///
  /// [expectedRevision] must come from the authoritative item snapshot on
  /// which the caller based this command. The update preserves published
  /// status and rechecks an active category at commit time.
  ///
  /// Throws the matching invalid-value exception,
  /// [CatalogItemNotFoundException], [CatalogCategoryNotFoundException],
  /// [CatalogItemPublicationException], [CatalogItemTransitionException], or
  /// [CatalogPersistenceException].
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    required int categoryId,
  });

  /// Validates and creates an active product category.
  ///
  /// Throws [CatalogInvalidCategoryNameException] or an expected
  /// [CatalogPersistenceException].
  Future<void> createCategory(String name);

  /// Changes whether products may be published in one category.
  ///
  /// Throws [CatalogCategoryNotFoundException] for an invalid or missing ID,
  /// or [CatalogPersistenceException] for expected temporary contention.
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  });

  /// Publishes a complete draft.
  ///
  /// [expectedRevision] must come from the authoritative draft snapshot on
  /// which the caller based this command. [CatalogItemNotFoundException]
  /// identifies an invalid or missing item.
  /// [CatalogItemPublicationException] identifies the rejected policy rule.
  /// [CatalogItemTransitionException] indicates stale state or a concurrent
  /// change before commit. Temporary contention produces
  /// [CatalogPersistenceException].
  Future<void> publishItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  });

  /// Archives a published product.
  ///
  /// [expectedRevision] must come from the authoritative published snapshot.
  /// Throws [CatalogItemNotFoundException] for an invalid or missing item,
  /// [CatalogItemTransitionException] when the item is not published or its
  /// state is stale, and [CatalogPersistenceException] for temporary
  /// contention.
  Future<void> archiveItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  });

  /// Deletes one draft optimistically.
  ///
  /// [expectedRevision] must come from the authoritative draft snapshot.
  /// Throws [CatalogItemNotFoundException] for a non-positive or missing [id],
  /// [CatalogItemTransitionException] when it is no longer a draft or its
  /// revision is stale, and [CatalogPersistenceException] for temporary
  /// contention.
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  });
}
