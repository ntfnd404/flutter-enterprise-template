import 'dart:async';

import 'package:catalog/catalog.dart';
import 'package:catalog/src/application/catalog_service.dart';
import 'package:catalog/src/domain/item/policies/catalog_item_publication_policy.dart';
import 'package:catalog/src/domain/repository/catalog_category_repository.dart';
import 'package:catalog/src/domain/repository/catalog_item_repository.dart';
import 'package:test/test.dart';

void main() {
  late _RecordingCatalogRepositories repository;
  late CatalogService service;

  setUp(() {
    repository = _RecordingCatalogRepositories();
    service = CatalogService(
      repository,
      repository,
      const CatalogItemPublicationPolicy(),
    );
  });

  test('validates a complete draft before persistence', () async {
    repository.categories[7] = _category();

    await service.createDraft(
      title: '  Product  ',
      description: '  Description  ',
      priceMinorUnits: 2500,
      currencyCode: ' usd ',
      categoryId: 7,
    );

    expect(repository.drafts, hasLength(1));
    final draft = repository.drafts.single;
    expect(draft.title.value, 'Product');
    expect(draft.description.value, 'Description');
    expect(draft.price.currencyCode, 'USD');
    expect(draft.categoryId, 7);
  });

  test('invalid draft input never reaches persistence', () async {
    await expectLater(
      service.createDraft(
        title: '   ',
        description: 'Description',
        priceMinorUnits: 100,
        currencyCode: 'USD',
        categoryId: 7,
      ),
      throwsA(isA<CatalogInvalidTitleException>()),
    );

    expect(repository.categoryReads, 0);
    expect(repository.drafts, isEmpty);
  });

  test('rejects an unknown category before creating a draft', () async {
    await expectLater(
      service.createDraft(
        title: 'Product',
        description: 'Description',
        priceMinorUnits: 100,
        currencyCode: 'USD',
        categoryId: 404,
      ),
      throwsA(isA<CatalogCategoryNotFoundException>()),
    );

    expect(repository.drafts, isEmpty);
  });

  test('validates and revises an existing draft', () async {
    repository.items[1] = _item();
    repository.categories[7] = _category();

    await service.updateDraft(
      id: 1,
      expectedRevision: _revision(),
      title: ' Revised ',
      description: ' New description ',
      priceMinorUnits: 3000,
      currencyCode: ' eur ',
      categoryId: 7,
    );

    final revision = repository.revisions.single;
    expect(revision.expectedRevision.value, 0);
    expect(revision.title.value, 'Revised');
    expect(revision.description.value, 'New description');
    expect(revision.price.currencyCode, 'EUR');
    expect(revision.categoryId, 7);
  });

  test('does not revise a published item', () async {
    repository.items[1] = _item(status: CatalogItemStatus.published);

    await expectLater(
      service.updateDraft(
        id: 1,
        expectedRevision: _revision(),
        title: 'Revised',
        description: 'New description',
        priceMinorUnits: 3000,
        currencyCode: 'EUR',
      ),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.itemNotDraft,
        ),
      ),
    );
    expect(repository.revisions, isEmpty);
    expect(repository.categoryReads, 0);
  });

  test('publishes through policy and completes after persistence', () async {
    repository.items[1] = _item();
    repository.categories[7] = _category();

    await service.publishItem(id: 1, expectedRevision: _revision());

    expect(repository.publishedDrafts.single.expectedRevision.value, 0);
    expect(repository.publishedDrafts.single.activeCategoryId, 7);
  });

  test(
    'does not write when publication policy rejects a draft',
    () async {
      repository.items[1] = _item(description: '');
      repository.categories[7] = _category();

      await expectLater(
        service.publishItem(id: 1, expectedRevision: _revision()),
        throwsA(isA<CatalogItemPublicationException>()),
      );
      expect(repository.publishedDrafts, isEmpty);
    },
  );

  test('archives a published item and completes after persistence', () async {
    repository.items[1] = _item(status: CatalogItemStatus.published);

    await service.archiveItem(id: 1, expectedRevision: _revision());

    expect(
      repository.archivedPublished.single,
      (
        id: 1,
        expectedRevision: CatalogItemRevision.fromStored(0),
      ),
    );
  });

  test('updates a published offer and completes after persistence', () async {
    repository.items[1] = _item(status: CatalogItemStatus.published);
    repository.categories[7] = _category();

    await service.updatePublishedOffer(
      id: 1,
      expectedRevision: _revision(),
      title: ' Revised ',
      description: ' Current offer ',
      priceMinorUnits: 400,
      currencyCode: ' eur ',
      categoryId: 7,
    );

    final update = repository.publishedUpdates.single;
    expect(update.expectedRevision.value, 0);
    expect(update.title.value, 'Revised');
    expect(update.description.value, 'Current offer');
    expect(update.price.minorUnits, 400);
    expect(update.price.currencyCode, 'EUR');
    expect(update.categoryId, 7);
  });

  test(
    'stale caller revisions reject every optimistic command before writes',
    () async {
      final staleRevision = _revision();

      repository.items[1] = _item(revision: 1);
      await expectLater(
        service.updateDraft(
          id: 1,
          expectedRevision: staleRevision,
          title: 'Revised',
          description: 'Description',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          categoryId: 0,
        ),
        throwsA(_concurrentStateChange()),
      );

      repository.items[1] = _item(
        status: CatalogItemStatus.published,
        revision: 1,
      );
      await expectLater(
        service.updatePublishedOffer(
          id: 1,
          expectedRevision: staleRevision,
          title: 'Revised',
          description: 'Description',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          categoryId: 0,
        ),
        throwsA(_concurrentStateChange()),
      );

      repository.items[1] = _item(revision: 1);
      await expectLater(
        service.publishItem(id: 1, expectedRevision: staleRevision),
        throwsA(_concurrentStateChange()),
      );

      repository.items[1] = _item(
        status: CatalogItemStatus.published,
        revision: 1,
      );
      await expectLater(
        service.archiveItem(id: 1, expectedRevision: staleRevision),
        throwsA(_concurrentStateChange()),
      );

      repository.items[1] = _item(revision: 1);
      await expectLater(
        service.deleteDraft(id: 1, expectedRevision: staleRevision),
        throwsA(_concurrentStateChange()),
      );

      expect(repository.categoryReads, 0);
      expect(repository.revisions, isEmpty);
      expect(repository.publishedUpdates, isEmpty);
      expect(repository.publishedDrafts, isEmpty);
      expect(repository.archivedPublished, isEmpty);
      expect(repository.deletedDrafts, isEmpty);
    },
  );

  test(
    'missing items reject every optimistic command without category reads',
    () async {
      final commands = <Future<void> Function()>[
        () => service.updateDraft(
          id: 1,
          expectedRevision: _revision(),
          title: 'Revised',
          description: 'Description',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          categoryId: 7,
        ),
        () => service.updatePublishedOffer(
          id: 1,
          expectedRevision: _revision(),
          title: 'Revised',
          description: 'Description',
          priceMinorUnits: 100,
          currencyCode: 'USD',
          categoryId: 7,
        ),
        () => service.publishItem(id: 1, expectedRevision: _revision()),
        () => service.archiveItem(id: 1, expectedRevision: _revision()),
        () => service.deleteDraft(id: 1, expectedRevision: _revision()),
      ];

      for (final command in commands) {
        await expectLater(
          command(),
          throwsA(isA<CatalogItemNotFoundException>()),
        );
      }

      expect(repository.categoryReads, 0);
      expect(repository.revisions, isEmpty);
      expect(repository.publishedUpdates, isEmpty);
      expect(repository.publishedDrafts, isEmpty);
      expect(repository.archivedPublished, isEmpty);
      expect(repository.deletedDrafts, isEmpty);
    },
  );

  test('repeated commands cannot reuse their committed token', () async {
    repository.items[1] = _item();
    repository.categories[7] = _category();

    await service.updateDraft(
      id: 1,
      expectedRevision: _revision(),
      title: 'First revision',
      description: 'Description',
      priceMinorUnits: 100,
      currencyCode: 'USD',
      categoryId: 7,
    );
    repository.items[1] = _item(revision: 1);

    await expectLater(
      service.updateDraft(
        id: 1,
        expectedRevision: _revision(),
        title: 'Repeated stale revision',
        description: 'Description',
        priceMinorUnits: 100,
        currencyCode: 'USD',
        categoryId: 7,
      ),
      throwsA(_concurrentStateChange()),
    );

    repository.items[1] = _item(status: CatalogItemStatus.published);
    await service.updatePublishedOffer(
      id: 1,
      expectedRevision: _revision(),
      title: 'First published revision',
      description: 'Description',
      priceMinorUnits: 100,
      currencyCode: 'USD',
      categoryId: 7,
    );
    repository.items[1] = _item(
      status: CatalogItemStatus.published,
      revision: 1,
    );
    await expectLater(
      service.updatePublishedOffer(
        id: 1,
        expectedRevision: _revision(),
        title: 'Repeated published revision',
        description: 'Description',
        priceMinorUnits: 100,
        currencyCode: 'USD',
        categoryId: 7,
      ),
      throwsA(_concurrentStateChange()),
    );

    repository.items[1] = _item();
    await service.publishItem(id: 1, expectedRevision: _revision());
    repository.items[1] = _item(
      status: CatalogItemStatus.published,
      revision: 1,
    );
    await expectLater(
      service.publishItem(id: 1, expectedRevision: _revision()),
      throwsA(_concurrentStateChange()),
    );

    repository.items[1] = _item(status: CatalogItemStatus.published);
    await service.archiveItem(id: 1, expectedRevision: _revision());
    repository.items[1] = _item(
      status: CatalogItemStatus.archived,
      revision: 1,
    );
    await expectLater(
      service.archiveItem(id: 1, expectedRevision: _revision()),
      throwsA(_concurrentStateChange()),
    );

    repository.items[1] = _item();
    await service.deleteDraft(id: 1, expectedRevision: _revision());
    repository.items.remove(1);
    await expectLater(
      service.deleteDraft(id: 1, expectedRevision: _revision()),
      throwsA(isA<CatalogItemNotFoundException>()),
    );

    expect(repository.revisions, hasLength(1));
    expect(repository.publishedUpdates, hasLength(1));
    expect(repository.publishedDrafts, hasLength(1));
    expect(repository.archivedPublished, hasLength(1));
    expect(repository.deletedDrafts, hasLength(1));
    expect(repository.categoryReads, 3);
  });

  test('lifecycle command futures wait for persistence completion', () async {
    repository.items[1] = _item();
    repository.categories[7] = _category();

    var gate = Completer<void>();
    repository.lifecycleWriteGate = gate;
    var completed = false;
    var command = service
        .publishItem(id: 1, expectedRevision: _revision())
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(repository.publishedDrafts, hasLength(1));
    expect(completed, isFalse);
    gate.complete();
    await command;
    expect(completed, isTrue);

    repository.items[1] = _item();
    gate = Completer<void>();
    repository.lifecycleWriteGate = gate;
    completed = false;
    command = service
        .deleteDraft(id: 1, expectedRevision: _revision())
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(repository.deletedDrafts, hasLength(1));
    expect(completed, isFalse);
    gate.complete();
    await command;
    expect(completed, isTrue);

    repository.items[1] = _item(status: CatalogItemStatus.published);
    gate = Completer<void>();
    repository.lifecycleWriteGate = gate;
    completed = false;
    command = service
        .archiveItem(id: 1, expectedRevision: _revision())
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(repository.archivedPublished, hasLength(1));
    expect(completed, isFalse);
    gate.complete();
    await command;
    expect(completed, isTrue);

    gate = Completer<void>();
    repository.lifecycleWriteGate = gate;
    completed = false;
    command = service
        .updatePublishedOffer(
          id: 1,
          expectedRevision: _revision(),
          title: 'Revised',
          description: 'Current offer',
          priceMinorUnits: 400,
          currencyCode: 'EUR',
          categoryId: 7,
        )
        .then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);

    expect(repository.publishedUpdates, hasLength(1));
    expect(completed, isFalse);
    gate.complete();
    await command;
    expect(completed, isTrue);
  });

  test('inactive category rejects offer update before persistence', () async {
    repository.items[1] = _item(status: CatalogItemStatus.published);
    repository.categories[7] = _category(active: false);

    await expectLater(
      service.updatePublishedOffer(
        id: 1,
        expectedRevision: _revision(),
        title: 'Revised',
        description: 'Current offer',
        priceMinorUnits: 400,
        currencyCode: 'EUR',
        categoryId: 7,
      ),
      throwsA(
        isA<CatalogItemPublicationException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemPublicationFailure.activeCategoryRequired,
        ),
      ),
    );
    expect(repository.publishedUpdates, isEmpty);
  });

  test('offer update checks item lifecycle before category lookup', () async {
    repository.items[1] = _item(status: CatalogItemStatus.archived);

    await expectLater(
      service.updatePublishedOffer(
        id: 1,
        expectedRevision: _revision(),
        title: 'Revised',
        description: 'Current offer',
        priceMinorUnits: 400,
        currencyCode: 'EUR',
        categoryId: 404,
      ),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.itemNotPublished,
        ),
      ),
    );

    expect(repository.categoryReads, 0);
    expect(repository.publishedUpdates, isEmpty);
  });

  test(
    'revision exhaustion rejects optimistic writes before persistence',
    () async {
      repository.items[1] = _item(
        status: CatalogItemStatus.published,
        revision: CatalogItemRevision.maxValue,
      );
      repository.categories[7] = _category();

      await expectLater(
        service.updatePublishedOffer(
          id: 1,
          expectedRevision: _revision(CatalogItemRevision.maxValue),
          title: 'Revised',
          description: 'Current offer',
          priceMinorUnits: 400,
          currencyCode: 'EUR',
          categoryId: 7,
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
      await expectLater(
        service.archiveItem(
          id: 1,
          expectedRevision: _revision(CatalogItemRevision.maxValue),
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );

      repository.items[1] = _item(revision: CatalogItemRevision.maxValue);
      await expectLater(
        service.updateDraft(
          id: 1,
          expectedRevision: _revision(CatalogItemRevision.maxValue),
          title: 'Revised',
          description: 'Current offer',
          priceMinorUnits: 400,
          currencyCode: 'EUR',
          categoryId: 7,
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
      await expectLater(
        service.publishItem(
          id: 1,
          expectedRevision: _revision(CatalogItemRevision.maxValue),
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
      await expectLater(
        service.deleteDraft(
          id: 1,
          expectedRevision: _revision(CatalogItemRevision.maxValue),
        ),
        throwsA(isA<CatalogDataIntegrityException>()),
      );

      expect(repository.revisions, isEmpty);
      expect(repository.publishedUpdates, isEmpty);
      expect(repository.publishedDrafts, isEmpty);
      expect(repository.archivedPublished, isEmpty);
    },
  );

  test('validates and delegates category commands', () async {
    await service.createCategory('  Hardware  ');
    await service.setCategoryActive(id: 7, isActive: false);

    expect(repository.createdCategories.single.value, 'Hardware');
    expect(repository.categoryChanges, <(int, bool)>[(7, false)]);
  });

  test('deletes only a draft using its authoritative revision', () async {
    repository.items[1] = _item(revision: 3);

    await service.deleteDraft(id: 1, expectedRevision: _revision(3));

    expect(
      repository.deletedDrafts.single,
      (id: 1, expectedRevision: CatalogItemRevision.fromStored(3)),
    );
  });

  test('rejects deleting a non-draft before persistence', () async {
    repository.items[1] = _item(status: CatalogItemStatus.published);

    await expectLater(
      service.deleteDraft(id: 1, expectedRevision: _revision()),
      throwsA(
        isA<CatalogItemTransitionException>().having(
          (error) => error.failure,
          'failure',
          CatalogItemTransitionFailure.itemNotDraft,
        ),
      ),
    );

    expect(repository.deletedDrafts, isEmpty);
  });

  test(
    'invalid command identifiers complete their Future with failure',
    () async {
      await expectLater(
        service.publishItem(id: 0, expectedRevision: _revision()),
        throwsA(isA<CatalogItemNotFoundException>()),
      );
      await expectLater(
        service.setCategoryActive(id: 0, isActive: true),
        throwsA(isA<CatalogCategoryNotFoundException>()),
      );
    },
  );
}

final class _RecordingCatalogRepositories
    implements CatalogItemRepository, CatalogCategoryRepository {
  final Map<int, CatalogItem> items = <int, CatalogItem>{};
  final Map<int, CatalogCategory> categories = <int, CatalogCategory>{};
  final List<
    ({
      CatalogItemTitle title,
      CatalogItemDescription description,
      CatalogItemPrice price,
      int? categoryId,
    })
  >
  drafts = [];
  final List<CatalogCategoryName> createdCategories = [];
  final List<(int, bool)> categoryChanges = [];
  final List<
    ({
      int id,
      CatalogItemRevision expectedRevision,
      int activeCategoryId,
    })
  >
  publishedDrafts = [];
  final List<({int id, CatalogItemRevision expectedRevision})>
  archivedPublished = [];
  final List<
    ({
      int id,
      CatalogItemRevision expectedRevision,
      CatalogItemTitle title,
      CatalogItemDescription description,
      CatalogItemPrice price,
      int? categoryId,
    })
  >
  revisions = [];
  final List<
    ({
      int id,
      CatalogItemRevision expectedRevision,
      CatalogItemTitle title,
      CatalogItemDescription description,
      CatalogItemPrice price,
      int categoryId,
    })
  >
  publishedUpdates = [];
  int categoryReads = 0;
  final List<({int id, CatalogItemRevision expectedRevision})> deletedDrafts =
      [];
  Completer<void>? lifecycleWriteGate;

  @override
  Future<void> createCategory(CatalogCategoryName name) async {
    createdCategories.add(name);
  }

  @override
  Future<void> createDraft({
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) async {
    drafts.add((
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    ));
  }

  @override
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    deletedDrafts.add((id: id, expectedRevision: expectedRevision));
    await lifecycleWriteGate?.future;
  }

  @override
  Future<CatalogCategory?> getCategory(int id) async {
    categoryReads += 1;
    return categories[id];
  }

  @override
  Future<CatalogItem> getItem(int id) async =>
      items[id] ?? (throw const CatalogItemNotFoundException());

  @override
  Future<List<CatalogItem>> findItemsByIds(Set<int> ids) async => items.entries
      .where((entry) => ids.contains(entry.key))
      .map((entry) => entry.value)
      .toList(growable: false);

  @override
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    categoryChanges.add((id, isActive));
  }

  @override
  Future<void> publishDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required int requiredActiveCategoryId,
  }) async {
    publishedDrafts.add((
      id: id,
      expectedRevision: expectedRevision,
      activeCategoryId: requiredActiveCategoryId,
    ));
    await lifecycleWriteGate?.future;
  }

  @override
  Future<void> archivePublished({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    archivedPublished.add((id: id, expectedRevision: expectedRevision));
    await lifecycleWriteGate?.future;
  }

  @override
  Future<void> updateDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int? categoryId,
  }) async {
    revisions.add((
      id: id,
      expectedRevision: expectedRevision,
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    ));
  }

  @override
  Future<void> updatePublishedOffer({
    required int id,
    required CatalogItemRevision expectedRevision,
    required CatalogItemTitle title,
    required CatalogItemDescription description,
    required CatalogItemPrice price,
    required int categoryId,
  }) async {
    publishedUpdates.add((
      id: id,
      expectedRevision: expectedRevision,
      title: title,
      description: description,
      price: price,
      categoryId: categoryId,
    ));
    await lifecycleWriteGate?.future;
  }

  @override
  Stream<List<CatalogCategory>> watchCategories() =>
      Stream<List<CatalogCategory>>.value(categories.values.toList());

  @override
  Stream<List<CatalogItem>> watchItems() =>
      Stream<List<CatalogItem>>.value(items.values.toList());
}

CatalogItem _item({
  int id = 1,
  String description = 'Description',
  CatalogItemStatus status = CatalogItemStatus.draft,
  int revision = 0,
}) => CatalogItem.fromValues(
  id: id,
  title: 'Product',
  description: description,
  priceMinorUnits: 100,
  currencyCode: 'USD',
  statusValue: status.value,
  categoryId: 7,
  revision: revision,
);

CatalogCategory _category({bool active = true}) => CatalogCategory.fromValues(
  id: 7,
  name: 'Hardware',
  isActive: active,
);

CatalogItemRevision _revision([int value = 0]) =>
    CatalogItemRevision.fromStored(value);

Matcher _concurrentStateChange() =>
    isA<CatalogItemTransitionException>().having(
      (error) => error.failure,
      'failure',
      CatalogItemTransitionFailure.concurrentStateChange,
    );
