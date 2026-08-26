import 'dart:async';

import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ordering/ordering.dart';
import 'package:template/app/events/order_draft_created_app_event.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';

part 'orders_action.dart';
part 'orders_event.dart';
part 'orders_state.dart';

/// Presentation state machine for the Ordering application facade.
final class OrdersBloc extends Bloc<OrdersEvent, OrdersState>
    with EphemeralBlocMixin<OrdersState, OrdersAction> {
  /// Creates an Orders presentation over narrow borrowed application roles.
  OrdersBloc({
    required this._ordering,
    required this._eventPublisher,
  }) : super(OrdersState.loading()) {
    on<_OrdersObservationRequested>(_onObservationRequested);
    on<_OrdersSnapshotReceived>(_onSnapshotReceived);
    on<_OrdersObservationFailed>(_onObservationFailed);
    on<_OrdersObservationCompleted>(_onObservationCompleted);
    on<OrdersDraftCreationRequested>(_onDraftCreationRequested);
    on<OrdersCancellationRequested>(_onCancellationRequested);
  }

  static const _maxOperationSequence = 2147483647;

  final OrderingFacade _ordering;
  final AppEventPublisher _eventPublisher;
  late StreamSubscription<List<Order>> _observation;
  var _isObserving = false;
  var _isCreatingDraft = false;
  Future<void>? _closeFuture;

  void _onObservationRequested(
    _OrdersObservationRequested event,
    Emitter<OrdersState> emit,
  ) {
    if (_isObserving) {
      return;
    }
    _isObserving = true;
    emit(state.copyWith(observationStatus: OrdersObservationStatus.loading));
    _observation = _ordering.watchOrders().listen(
      (orders) => _addObservationEvent(_OrdersSnapshotReceived(orders)),
      onError: (Object error, StackTrace stackTrace) {
        _addObservationEvent(_OrdersObservationFailed(error, stackTrace));
      },
      onDone: () {
        _addObservationEvent(const _OrdersObservationCompleted());
      },
      cancelOnError: true,
    );
  }

  void _addObservationEvent(OrdersEvent event) {
    if (!isClosed) {
      add(event);
    }
  }

  void _onSnapshotReceived(
    _OrdersSnapshotReceived event,
    Emitter<OrdersState> emit,
  ) {
    emit(
      state.copyWith(
        orders: event.orders,
        observationStatus: OrdersObservationStatus.ready,
      ),
    );
  }

  void _onObservationFailed(
    _OrdersObservationFailed event,
    Emitter<OrdersState> emit,
  ) {
    _isObserving = false;
    if (event.error case OrderingPersistenceException()) {
      emit(
        state.copyWith(
          observationStatus: OrdersObservationStatus.unavailable,
        ),
      );

      return;
    }
    Error.throwWithStackTrace(event.error, event.stackTrace);
  }

  void _onObservationCompleted(
    _OrdersObservationCompleted event,
    Emitter<OrdersState> emit,
  ) {
    _isObserving = false;
    emit(
      state.copyWith(
        observationStatus: OrdersObservationStatus.unavailable,
      ),
    );
  }

  Future<void> _stopObservation() {
    if (!_isObserving) {
      return Future.value();
    }
    _isObserving = false;

    return _observation.cancel();
  }

  Future<void> _onDraftCreationRequested(
    OrdersDraftCreationRequested event,
    Emitter<OrdersState> emit,
  ) async {
    if (_isCreatingDraft) {
      return;
    }
    _isCreatingDraft = true;
    final operationSequence = state.nextOperationSequence;
    final nextOperationSequence = operationSequence == _maxOperationSequence
        ? 1
        : operationSequence + 1;
    emit(
      state.copyWith(
        isCreatingDraft: true,
        nextOperationSequence: nextOperationSequence,
      ),
    );
    emitAction(MonitorOrderDraftCreationAction(operationSequence));

    try {
      await _ordering.createDraft();
      _eventPublisher.emit(
        OrderDraftCreatedAppEvent(operationSequence: operationSequence),
      );
    } on OrderingPersistenceException {
      emitAction(
        const ShowOrdersFailureAction(OrdersFailure.storageUnavailable),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
    } finally {
      _isCreatingDraft = false;
      if (!emit.isDone) {
        emit(state.copyWith(isCreatingDraft: false));
      }
    }
  }

  Future<void> _onCancellationRequested(
    OrdersCancellationRequested event,
    Emitter<OrdersState> emit,
  ) async {
    try {
      await _ordering.cancelOrder(event.orderId);
    } on OrderingOrderNotFoundException {
      emitAction(
        const ShowOrdersFailureAction(OrdersFailure.orderNotFound),
      );
    } on OrderingTransitionException catch (error, stackTrace) {
      switch (error.failure) {
        case OrderingTransitionFailure.orderAlreadyCancelled:
          emitAction(
            const ShowOrdersFailureAction(OrdersFailure.alreadyCancelled),
          );
        case OrderingTransitionFailure.concurrentStateChange:
          emitAction(
            const ShowOrdersFailureAction(OrdersFailure.orderChanged),
          );
        case OrderingTransitionFailure.orderNotDraft:
          Error.throwWithStackTrace(error, stackTrace);
      }
    } on OrderingPersistenceException {
      emitAction(
        const ShowOrdersFailureAction(OrdersFailure.storageUnavailable),
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(error, stackTrace);
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
