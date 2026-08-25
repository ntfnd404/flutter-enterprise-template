import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/events/demo_action_completed_app_event.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';

void main() {
  test(
    'projects cross-feature facts and cancels its subscription on close',
    () async {
      final eventBus = AppEventBus();
      final bloc = ActivityBloc(eventBus: eventBus);

      final observed = bloc.stream.firstWhere(
        (state) => state.observedCount == 1,
      );
      eventBus.emit(const DemoActionCompletedAppEvent(sequence: 4));

      final state = await observed;
      expect(state.observedCount, 1);
      expect(state.lastObservedSequence, 4);

      await bloc.close();
      eventBus.emit(const DemoActionCompletedAppEvent(sequence: 5));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.observedCount, 1);
      expect(bloc.state.lastObservedSequence, 4);
      await eventBus.dispose();
    },
  );

  test('does not replay a fact published before subscription', () async {
    final eventBus = AppEventBus();
    eventBus.emit(const DemoActionCompletedAppEvent(sequence: 3));
    await Future<void>.delayed(Duration.zero);

    final bloc = ActivityBloc(eventBus: eventBus);
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.observedCount, 0);
    expect(bloc.state.lastObservedSequence, isNull);
    await bloc.close();
    await eventBus.dispose();
  });

  test(
    'recreation starts a new non-authoritative observation window',
    () async {
      final eventBus = AppEventBus();
      final first = ActivityBloc(eventBus: eventBus);
      final firstObserved = first.stream.firstWhere(
        (state) => state.observedCount == 1,
      );
      eventBus.emit(const DemoActionCompletedAppEvent(sequence: 1));
      await firstObserved;
      await first.close();

      eventBus.emit(const DemoActionCompletedAppEvent(sequence: 7));
      await Future<void>.delayed(Duration.zero);
      final recreated = ActivityBloc(eventBus: eventBus);
      expect(recreated.state.observedCount, 0);
      expect(recreated.state.lastObservedSequence, isNull);

      final recreatedObserved = recreated.stream.firstWhere(
        (state) => state.observedCount == 1,
      );
      eventBus.emit(const DemoActionCompletedAppEvent(sequence: 9));
      final state = await recreatedObserved;
      expect(state.observedCount, 1);
      expect(state.lastObservedSequence, 9);

      await recreated.close();
      await eventBus.dispose();
    },
  );
}
