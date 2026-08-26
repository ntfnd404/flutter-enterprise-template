import 'dart:async';

import 'package:catalog/catalog.dart';
import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'catalog_action.dart';
part 'catalog_event.dart';
part 'catalog_state.dart';

/// Presentation state machine for the catalog application facade.
final class CatalogBloc extends Bloc<CatalogEvent, CatalogState>
    with EphemeralBlocMixin<CatalogState, CatalogAction> {
  /// Creates a catalog BLoC over a narrow application API.
  CatalogBloc({required this._catalog}) : super(CatalogState.loading()) {
    on<_CatalogObservationRequested>(_onObservationRequested);
    on<_CatalogSnapshotReceived>(_onSnapshotReceived);
    on<_CatalogObservationFailed>(_onObservationFailed);
    on<_CatalogObservationCompleted>(_onObservationCompleted);
    on<CatalogDraftCreated>(_onDraftCreated);
    on<CatalogItemDeleted>(_onItemDeleted);
  }

  final CatalogFacade _catalog;
  late StreamSubscription<List<CatalogItem>> _observation;
  var _isObserving = false;
  Future<void>? _closeFuture;

  void _onObservationRequested(
    _CatalogObservationRequested event,
    Emitter<CatalogState> emit,
  ) {
    if (_isObserving) {
      return;
    }
    _isObserving = true;
    emit(CatalogState.loading(items: state.items));
    _observation = _catalog.watchItems().listen(
      (items) => _addObservationEvent(_CatalogSnapshotReceived(items)),
      onError: (Object error, StackTrace stackTrace) {
        _addObservationEvent(_CatalogObservationFailed(error, stackTrace));
      },
      onDone: () {
        _addObservationEvent(const _CatalogObservationCompleted());
      },
      cancelOnError: true,
    );
  }

  void _addObservationEvent(CatalogEvent event) {
    if (!isClosed) {
      add(event);
    }
  }

  void _onSnapshotReceived(
    _CatalogSnapshotReceived event,
    Emitter<CatalogState> emit,
  ) {
    emit(CatalogState.ready(items: event.items));
  }

  void _onObservationFailed(
    _CatalogObservationFailed event,
    Emitter<CatalogState> emit,
  ) {
    _isObserving = false;
    if (event.error case CatalogPersistenceException()) {
      emit(CatalogState.unavailable(items: state.items));

      return;
    }
    Error.throwWithStackTrace(event.error, event.stackTrace);
  }

  void _onObservationCompleted(
    _CatalogObservationCompleted event,
    Emitter<CatalogState> emit,
  ) {
    _isObserving = false;
    emit(CatalogState.unavailable(items: state.items));
  }

  Future<void> _stopObservation() {
    if (!_isObserving) {
      return Future.value();
    }
    _isObserving = false;

    return _observation.cancel();
  }

  Future<void> _onDraftCreated(
    CatalogDraftCreated event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      await _catalog.createDraft(
        title: event.title,
        description: event.description,
        priceMinorUnits: event.priceMinorUnits,
        currencyCode: event.currencyCode,
      );
    } on CatalogInvalidTitleException {
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.invalidTitle),
      );
    } on CatalogInvalidDescriptionException {
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.invalidDescription),
      );
    } on CatalogInvalidPriceException {
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.invalidPrice),
      );
    } on CatalogPersistenceException {
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.storageUnavailable),
      );
    }
  }

  Future<void> _onItemDeleted(
    CatalogItemDeleted event,
    Emitter<CatalogState> emit,
  ) => _runMutation(
    () => _catalog.deleteDraft(
      id: event.id,
      expectedRevision: event.expectedRevision,
    ),
  );

  Future<void> _runMutation(
    Future<void> Function() mutation,
  ) async {
    try {
      await mutation();
    } on CatalogItemNotFoundException {
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.itemNotFound),
      );
    } on CatalogItemTransitionException catch (error, stackTrace) {
      if (error.failure != CatalogItemTransitionFailure.concurrentStateChange) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.itemChanged),
      );
    } on CatalogPersistenceException {
      emitAction(
        const ShowCatalogFailureAction(CatalogFailure.storageUnavailable),
      );
    }
  }

  @override
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) {
      return existing;
    }
    final cancellation = _stopObservation();
    final blocClose = super.close();

    return _closeFuture = Future.wait(<Future<void>>[
      cancellation,
      blocClose,
    ]);
  }
}
