import 'dart:async';

import 'package:catalog/catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/catalog/bloc/catalog_bloc.dart';

import '../support/recording_catalog_facade.dart';

void main() {
  test('closes before observation starts', () async {
    final facade = RecordingCatalogFacade();
    final bloc = CatalogBloc(catalog: facade);

    await bloc.close();
    await facade.dispose();
  });

  test(
    'projects the authoritative facade stream into persistent state',
    () async {
      final facade = RecordingCatalogFacade();
      final bloc = CatalogBloc(catalog: facade)..add(const CatalogStarted());
      addTearDown(facade.dispose);
      addTearDown(bloc.close);

      final items = <CatalogItem>[
        _item(),
      ];
      final ready = bloc.stream.firstWhere(
        (state) => state.observationStatus == CatalogObservationStatus.ready,
      );
      await facade.whenWatchStarted;
      facade.emitItems(items);

      expect((await ready).items, items);
    },
  );

  test('emits command failures as actions without changing state', () async {
    final scenarios =
        <
          ({
            CatalogException failure,
            CatalogEvent event,
            CatalogFailure expected,
            bool isAdd,
          })
        >[
          (
            failure: const CatalogInvalidTitleException(),
            event: const CatalogDraftCreated(
              title: '',
              description: 'Description',
              priceMinorUnits: 100,
              currencyCode: 'USD',
            ),
            expected: CatalogFailure.invalidTitle,
            isAdd: true,
          ),
          (
            failure: const CatalogPersistenceException(),
            event: const CatalogDraftCreated(
              title: 'Item',
              description: 'Description',
              priceMinorUnits: 100,
              currencyCode: 'USD',
            ),
            expected: CatalogFailure.storageUnavailable,
            isAdd: true,
          ),
          (
            failure: const CatalogItemNotFoundException(),
            event: CatalogItemDeleted(
              id: 1,
              expectedRevision: _item().revision,
            ),
            expected: CatalogFailure.itemNotFound,
            isAdd: false,
          ),
          (
            failure: const CatalogPersistenceException(),
            event: CatalogItemDeleted(
              id: 1,
              expectedRevision: _item().revision,
            ),
            expected: CatalogFailure.storageUnavailable,
            isAdd: false,
          ),
          (
            failure: const CatalogItemTransitionException(
              CatalogItemTransitionFailure.concurrentStateChange,
            ),
            event: CatalogItemDeleted(
              id: 1,
              expectedRevision: _item().revision,
            ),
            expected: CatalogFailure.itemChanged,
            isAdd: false,
          ),
        ];

    for (final scenario in scenarios) {
      final facade = RecordingCatalogFacade();
      final bloc = CatalogBloc(catalog: facade);
      final previousState = bloc.state;
      if (scenario.isAdd) {
        facade.addFailure = scenario.failure;
      } else {
        facade.mutationFailure = scenario.failure;
      }
      final action = bloc.actionStream.first;

      bloc.add(scenario.event);

      expect(
        await action,
        isA<ShowCatalogFailureAction>().having(
          (value) => value.failure,
          'failure',
          scenario.expected,
        ),
      );
      expect(identical(bloc.state, previousState), isTrue);
      await bloc.close();
      await facade.dispose();
    }
  });

  test(
    'preserves stale items and retries an unavailable observation',
    () async {
      final facade = RecordingCatalogFacade();
      final bloc = CatalogBloc(catalog: facade)..add(const CatalogStarted());
      addTearDown(facade.dispose);
      addTearDown(bloc.close);
      final item = _item();

      await facade.whenWatchStarted;
      final ready = bloc.stream.firstWhere(
        (state) => state.observationStatus == CatalogObservationStatus.ready,
      );
      facade.emitItems(<CatalogItem>[item]);
      await ready;

      final unavailable = bloc.stream.firstWhere(
        (state) =>
            state.observationStatus == CatalogObservationStatus.unavailable,
      );
      await facade.emitError(const CatalogPersistenceException());
      expect((await unavailable).items, <CatalogItem>[item]);
      await pumpEventQueue();

      bloc.add(const CatalogRetryRequested());
      await facade.waitForWatchCount(2);
      expect(bloc.state.observationStatus, CatalogObservationStatus.loading);
      expect(bloc.state.items, <CatalogItem>[item]);

      final retried = bloc.stream.firstWhere(
        (state) => state.observationStatus == CatalogObservationStatus.ready,
      );
      facade.emitItems(<CatalogItem>[item]);
      await retried;
    },
  );

  test('normal authoritative-stream completion becomes unavailable', () async {
    final facade = RecordingCatalogFacade();
    final bloc = CatalogBloc(catalog: facade)..add(const CatalogStarted());
    addTearDown(facade.dispose);
    addTearDown(bloc.close);

    await facade.whenWatchStarted;
    final unavailable = bloc.stream.firstWhere(
      (state) =>
          state.observationStatus == CatalogObservationStatus.unavailable,
    );
    await facade.completeWatch();

    expect(
      (await unavailable).observationStatus,
      CatalogObservationStatus.unavailable,
    );
  });

  test('closing an active observation does not emit unavailable', () async {
    final facade = RecordingCatalogFacade();
    final bloc = CatalogBloc(catalog: facade)..add(const CatalogStarted());
    addTearDown(facade.dispose);
    final states = <CatalogState>[];
    final subscription = bloc.stream.listen(states.add);
    addTearDown(subscription.cancel);

    await facade.whenWatchStarted;
    await bloc.close();
    await pumpEventQueue();

    expect(
      states.where(
        (state) =>
            state.observationStatus == CatalogObservationStatus.unavailable,
      ),
      isEmpty,
    );
  });

  test(
    'duplicate observation requests do not create parallel streams',
    () async {
      final facade = RecordingCatalogFacade();
      final bloc = CatalogBloc(catalog: facade);
      addTearDown(facade.dispose);
      addTearDown(bloc.close);

      bloc
        ..add(const CatalogStarted())
        ..add(const CatalogStarted())
        ..add(const CatalogRetryRequested());
      await facade.whenWatchStarted;
      await pumpEventQueue();

      expect(facade.watchCount, 1);
    },
  );

  test('unexpected observation failure reaches the owner zone once', () async {
    const failure = CatalogDataIntegrityException();
    final zoneErrors = <Object>[];
    final reported = Completer<void>();
    late RecordingCatalogFacade facade;
    late CatalogBloc bloc;

    final run = runZonedGuarded(
      () async {
        facade = RecordingCatalogFacade();
        bloc = CatalogBloc(catalog: facade);
        bloc.add(const CatalogStarted());
        await facade.whenWatchStarted;
        await facade.emitError(failure);
        await reported.future.timeout(const Duration(seconds: 5));
      },
      (error, _) {
        zoneErrors.add(error);
        if (!reported.isCompleted) {
          reported.complete();
        }
      },
    );
    if (run == null) {
      fail('Guarded zone did not return the test future.');
    }
    await run;

    expect(zoneErrors, <Object>[failure]);
    expect(bloc.state.observationStatus, CatalogObservationStatus.loading);
    await bloc.close();
    await facade.dispose();
  });
}

CatalogItem _item() => CatalogItem.fromValues(
  id: 1,
  title: 'Item',
  description: 'Description',
  priceMinorUnits: 100,
  currencyCode: 'USD',
  statusValue: CatalogItemStatus.draft.value,
  categoryId: null,
  revision: 0,
);
