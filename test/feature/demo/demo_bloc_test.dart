import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/events/demo_action_completed_app_event.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/demo/bloc/demo_bloc.dart';

void main() {
  test('separates persistent state, cross-feature fact, and UI action', () async {
    final eventBus = AppEventBus();
    final bloc = DemoBloc(eventBus: eventBus);
    addTearDown(() async {
      await bloc.close();
      await eventBus.dispose();
    });

    bloc.add(const DemoStarted());
    await bloc.stream.firstWhere((state) => state.isReady);

    final emittedStates = <DemoState>[];
    final stateSubscription = bloc.stream.listen(emittedStates.add);
    final appEvent = eventBus.on<DemoActionCompletedAppEvent>().first;
    final action = bloc.actionStream.first;

    bloc.add(const DemoActionRequested());

    final completedState = await bloc.stream.firstWhere(
      (state) => state.completedActions == 1,
    );
    final completedEvent = await appEvent;
    final completedAction = await action;
    await Future<void>.delayed(Duration.zero);

    expect(completedState.completedActions, 1);
    expect(completedEvent.sequence, 1);
    expect(
      completedAction,
      isA<ShowDemoActionCompletedAction>().having(
        (value) => value.sequence,
        'sequence',
        1,
      ),
    );
    expect(
      emittedStates.where((state) => state.completedActions > 0),
      hasLength(1),
      reason: 'The transient UI command must not require a reset state.',
    );

    await stateSubscription.cancel();
  });

  test('does not replay an action to a late listener', () async {
    final eventBus = AppEventBus();
    final bloc = DemoBloc(eventBus: eventBus);
    addTearDown(() async {
      await bloc.close();
      await eventBus.dispose();
    });

    bloc.add(const DemoStarted());
    await bloc.stream.firstWhere((state) => state.isReady);
    final firstAction = bloc.actionStream.first;
    bloc.add(const DemoActionRequested());
    await firstAction;

    final lateActions = <DemoAction>[];
    final lateSubscription = bloc.actionStream.listen(lateActions.add);
    bloc.add(const DemoStarted());
    await Future<void>.delayed(Duration.zero);

    expect(lateActions, isEmpty);
    await lateSubscription.cancel();
  });
}
