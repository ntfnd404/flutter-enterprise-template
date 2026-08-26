import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordering/ordering.dart';
import 'package:template/app/events/order_draft_created_app_event.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/orders/bloc/orders_bloc.dart';

import 'support/recording_ordering_facade.dart';

void main() {
  test('projects authoritative orders and retries with stale state', () async {
    final ordering = RecordingOrderingFacade();
    final bus = AppEventBus();
    final bloc = OrdersBloc(
      ordering: ordering,
      eventPublisher: bus,
    )..add(const OrdersStarted());
    addTearDown(() async {
      await bloc.close();
      await ordering.dispose();
      await bus.dispose();
    });

    await ordering.waitForWatchCount(1);
    final order = _order();
    final ready = bloc.stream.firstWhere(
      (state) => state.observationStatus == OrdersObservationStatus.ready,
    );
    ordering.emitOrders(<Order>[order]);
    expect((await ready).orders, <Order>[order]);

    final unavailable = bloc.stream.firstWhere(
      (state) => state.observationStatus == OrdersObservationStatus.unavailable,
    );
    await ordering.emitWatchError(const OrderingPersistenceException());
    expect((await unavailable).orders, <Order>[order]);
    await pumpEventQueue();

    bloc.add(const OrdersRetryRequested());
    await ordering.waitForWatchCount(2);
    expect(bloc.state.orders, <Order>[order]);
    expect(bloc.state.observationStatus, OrdersObservationStatus.loading);
  });

  test('opens monitor before await and publishes only after commit', () async {
    final ordering = RecordingOrderingFacade();
    final commit = Completer<OrderId>();
    ordering.createDraftHandler = () => commit.future;
    final bus = AppEventBus();
    final bloc = OrdersBloc(ordering: ordering, eventPublisher: bus);
    addTearDown(() async {
      await bloc.close();
      await ordering.dispose();
      await bus.dispose();
    });
    final monitor = bloc.actionStream
        .where((action) => action is MonitorOrderDraftCreationAction)
        .cast<MonitorOrderDraftCreationAction>()
        .first;
    final notification = bus.on<OrderDraftCreatedAppEvent>().first;

    bloc
      ..add(const OrdersDraftCreationRequested())
      ..add(const OrdersDraftCreationRequested());

    expect((await monitor).operationSequence, 1);
    expect(ordering.createDraftCount, 1);
    expect(bloc.state.isCreatingDraft, isTrue);
    var notified = false;
    unawaited(notification.then((_) => notified = true));
    await pumpEventQueue();
    expect(notified, isFalse);

    commit.complete(OrderId.fromStored(7));
    final event = await notification;
    expect(event.operationSequence, 1);
    await pumpEventQueue();
    expect(bloc.state.isCreatingDraft, isFalse);
  });

  test('maps every expected create and cancellation failure', () async {
    final scenarios = <({Exception error, OrdersFailure expected})>[
      (
        error: const OrderingOrderNotFoundException(),
        expected: OrdersFailure.orderNotFound,
      ),
      (
        error: const OrderingTransitionException(
          OrderingTransitionFailure.orderAlreadyCancelled,
        ),
        expected: OrdersFailure.alreadyCancelled,
      ),
      (
        error: const OrderingTransitionException(
          OrderingTransitionFailure.concurrentStateChange,
        ),
        expected: OrdersFailure.orderChanged,
      ),
      (
        error: const OrderingPersistenceException(),
        expected: OrdersFailure.storageUnavailable,
      ),
    ];

    for (final scenario in scenarios) {
      final ordering = RecordingOrderingFacade()
        ..cancelHandler = (_) => Future<void>.error(scenario.error);
      final bus = AppEventBus();
      final bloc = OrdersBloc(ordering: ordering, eventPublisher: bus);
      final failure = bloc.actionStream
          .where((action) => action is ShowOrdersFailureAction)
          .cast<ShowOrdersFailureAction>()
          .first;

      bloc.add(OrdersCancellationRequested(OrderId.fromStored(3)));

      expect((await failure).failure, scenario.expected);
      await bloc.close();
      await ordering.dispose();
      await bus.dispose();
    }

    final ordering = RecordingOrderingFacade()
      ..createDraftHandler = () => Future<OrderId>.error(
        const OrderingPersistenceException(),
      );
    final bus = AppEventBus();
    final bloc = OrdersBloc(ordering: ordering, eventPublisher: bus);
    final failure = bloc.actionStream
        .where((action) => action is ShowOrdersFailureAction)
        .cast<ShowOrdersFailureAction>()
        .first;

    bloc.add(const OrdersDraftCreationRequested());

    expect((await failure).failure, OrdersFailure.storageUnavailable);
    await bloc.close();
    await ordering.dispose();
    await bus.dispose();
  });

  test(
    'preserves an unexpected command error and its original stack',
    () async {
      final failure = StateError('unexpected command failure');
      final failureStack = StackTrace.current;
      final reported = Completer<void>();
      Object? reportedError;
      StackTrace? reportedStack;
      late RecordingOrderingFacade ordering;
      late AppEventBus bus;
      late OrdersBloc bloc;

      final run = runZonedGuarded(
        () async {
          ordering = RecordingOrderingFacade()
            ..createDraftHandler = () => Future<OrderId>.error(
              failure,
              failureStack,
            );
          bus = AppEventBus();
          bloc = OrdersBloc(ordering: ordering, eventPublisher: bus);
          bloc.add(const OrdersDraftCreationRequested());
          await reported.future.timeout(const Duration(seconds: 5));
        },
        (error, stackTrace) {
          reportedError = error;
          reportedStack = stackTrace;
          if (!reported.isCompleted) {
            reported.complete();
          }
        },
      );
      if (run == null) {
        fail('Guarded zone did not return the test future.');
      }
      await run;

      expect(reportedError, same(failure));
      expect(reportedStack, same(failureStack));
      await bloc.close();
      await ordering.dispose();
      await bus.dispose();
    },
  );

  test('normal watch completion becomes unavailable', () async {
    final ordering = RecordingOrderingFacade();
    final bus = AppEventBus();
    final bloc = OrdersBloc(
      ordering: ordering,
      eventPublisher: bus,
    )..add(const OrdersStarted());
    addTearDown(() async {
      await bloc.close();
      await ordering.dispose();
      await bus.dispose();
    });

    await ordering.waitForWatchCount(1);
    final unavailable = bloc.stream.firstWhere(
      (state) => state.observationStatus == OrdersObservationStatus.unavailable,
    );
    await ordering.completeWatch();
    expect(
      (await unavailable).observationStatus,
      OrdersObservationStatus.unavailable,
    );
  });
}

Order _order() => Order.fromStored(
  id: 1,
  lines: const [],
  totalMinorUnits: null,
  currencyCode: null,
  statusValue: OrderStatus.draft.value,
  revision: 0,
  createdAtUtcMilliseconds: 1,
  placedAtUtcMilliseconds: null,
  cancelledAtUtcMilliseconds: null,
);
