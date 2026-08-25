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
    on<CatalogDraftCreated>(_onDraftCreated);
    on<CatalogItemDeleted>(_onItemDeleted);
  }

  final CatalogFacade _catalog;
  bool _isObserving = false;

  Future<void> _onObservationRequested(
    _CatalogObservationRequested event,
    Emitter<CatalogState> emit,
  ) async {
    if (_isObserving) {
      return;
    }
    _isObserving = true;
    emit(CatalogState.loading(items: state.items));

    try {
      await emit.forEach<List<CatalogItem>>(
        _catalog.watchItems(),
        onData: (items) => CatalogState.ready(items: items),
      );
      if (!emit.isDone) {
        emit(CatalogState.unavailable(items: state.items));
      }
    } on CatalogPersistenceException {
      if (!emit.isDone) {
        emit(CatalogState.unavailable(items: state.items));
      }
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isObserving = false;
    }
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
}
