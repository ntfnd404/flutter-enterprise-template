import 'dart:async';

import 'package:catalog/catalog.dart';

final class RecordingCatalogFacade implements CatalogFacade {
  final List<StreamController<List<CatalogItem>>> _watchControllers = [];
  final StreamController<int> _watchCounts = StreamController<int>.broadcast();

  final List<
    ({
      String title,
      String description,
      int priceMinorUnits,
      String currencyCode,
      int? categoryId,
    })
  >
  createdDrafts = [];
  final List<
    ({
      int id,
      String title,
      String description,
      int priceMinorUnits,
      String currencyCode,
      int? categoryId,
    })
  >
  updatedDrafts = [];
  final List<String> createdCategories = <String>[];
  final List<(int, bool)> categoryChanges = <(int, bool)>[];
  final List<int> publishedIds = <int>[];
  final List<int> archivedIds = <int>[];
  final List<int> deletedIds = <int>[];
  final List<int> updatedPublishedIds = <int>[];

  CatalogException? addFailure;
  CatalogException? mutationFailure;

  int get watchCount => _watchControllers.length;

  Future<void> get whenWatchStarted => waitForWatchCount(1);

  Future<void> waitForWatchCount(int expected) async {
    if (watchCount >= expected) {
      return;
    }
    await _watchCounts.stream.firstWhere((count) => count >= expected);
  }

  void emitItems(List<CatalogItem> items) {
    _activeWatch.add(List<CatalogItem>.unmodifiable(items));
  }

  Future<void> emitError(Object error, [StackTrace? stackTrace]) async {
    final controller = _activeWatch;
    controller.addError(error, stackTrace);
    await controller.close();
  }

  Future<void> completeWatch() => _activeWatch.close();

  Future<void> dispose() async {
    for (final controller in _watchControllers) {
      if (!controller.isClosed) {
        await controller.close();
      }
    }
    await _watchCounts.close();
  }

  @override
  Future<void> archiveItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    final failure = mutationFailure;
    if (failure != null) throw failure;
    archivedIds.add(id);
  }

  @override
  Future<void> createCategory(String name) async {
    final failure = addFailure;
    if (failure != null) throw failure;
    createdCategories.add(name);
  }

  @override
  Future<void> createDraft({
    required String title,
    required String description,
    required int priceMinorUnits,
    required String currencyCode,
    int? categoryId,
  }) async {
    final failure = addFailure;
    if (failure != null) throw failure;
    createdDrafts.add((
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ));
  }

  @override
  Future<void> deleteDraft({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    final failure = mutationFailure;
    if (failure != null) throw failure;
    deletedIds.add(id);
  }

  @override
  Future<void> publishItem({
    required int id,
    required CatalogItemRevision expectedRevision,
  }) async {
    final failure = mutationFailure;
    if (failure != null) throw failure;
    publishedIds.add(id);
  }

  @override
  Future<void> setCategoryActive({
    required int id,
    required bool isActive,
  }) async {
    final failure = mutationFailure;
    if (failure != null) throw failure;
    categoryChanges.add((id, isActive));
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
    final failure = mutationFailure;
    if (failure != null) throw failure;
    updatedDrafts.add((
      id: id,
      title: title,
      description: description,
      priceMinorUnits: priceMinorUnits,
      currencyCode: currencyCode,
      categoryId: categoryId,
    ));
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
    final failure = mutationFailure;
    if (failure != null) throw failure;
    updatedPublishedIds.add(id);
  }

  @override
  Stream<List<CatalogCategory>> watchCategories() =>
      const Stream<List<CatalogCategory>>.empty();

  @override
  Stream<List<CatalogItem>> watchItems() {
    final controller = StreamController<List<CatalogItem>>();
    _watchControllers.add(controller);
    _watchCounts.add(watchCount);

    return controller.stream;
  }

  StreamController<List<CatalogItem>> get _activeWatch {
    if (_watchControllers case [..., final active]) {
      return active;
    }
    throw StateError('Catalog observation has not started.');
  }
}
