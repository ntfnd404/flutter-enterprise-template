import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ordering/ordering.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';
import 'package:template/feature/orders/bloc/orders_bloc.dart';

import '../feature/orders/support/recording_ordering_facade.dart';

void main() {
  test('projects a draft committed after the monitor starts', () async {
    final ordering = RecordingOrderingFacade();
    final commit = Completer<OrderId>();
    ordering.createDraftHandler = () => commit.future;
    final bus = AppEventBus();
    final orders = OrdersBloc(ordering: ordering, eventPublisher: bus);
    ActivityBloc? activity;

    try {
      final monitor = orders.actionStream
          .where((action) => action is MonitorOrderDraftCreationAction)
          .cast<MonitorOrderDraftCreationAction>()
          .first;
      orders.add(const OrdersDraftCreationRequested());
      final operationSequence = (await monitor).operationSequence;

      activity = ActivityBloc(eventBus: bus);
      final observed = activity.stream.firstWhere(
        (state) => state.lastObservedSequence == operationSequence,
      );
      commit.complete(OrderId.fromStored(7));

      final state = await observed;
      expect(state.observedCount, 1);
      expect(state.lastObservedSequence, operationSequence);
    } finally {
      await activity?.close();
      await orders.close();
      await ordering.dispose();
      await bus.dispose();
    }
  });

  test('does not replay a completion committed before monitoring', () async {
    final ordering = RecordingOrderingFacade();
    final bus = AppEventBus();
    final orders = OrdersBloc(ordering: ordering, eventPublisher: bus);
    ActivityBloc? activity;

    try {
      final monitor = orders.actionStream
          .where((action) => action is MonitorOrderDraftCreationAction)
          .cast<MonitorOrderDraftCreationAction>()
          .first;
      orders.add(const OrdersDraftCreationRequested());
      await monitor;
      await pumpEventQueue();

      activity = ActivityBloc(eventBus: bus);
      await pumpEventQueue();

      expect(activity.state.observedCount, 0);
      expect(activity.state.lastObservedSequence, isNull);
    } finally {
      await activity?.close();
      await orders.close();
      await ordering.dispose();
      await bus.dispose();
    }
  });
}
