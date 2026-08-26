import 'package:flutter_test/flutter_test.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';
import 'package:template/feature/demo/bloc/demo_bloc.dart';

void main() {
  test(
    'application composition demonstrates live cross-feature delivery',
    () async {
      final eventBus = AppEventBus();
      final demoBloc = DemoBloc(eventBus: eventBus);
      final activityBloc = ActivityBloc(eventBus: eventBus);
      addTearDown(() async {
        await demoBloc.close();
        await activityBloc.close();
        await eventBus.dispose();
      });

      demoBloc.add(const DemoStarted());
      await demoBloc.stream.firstWhere((state) => state.isReady);
      final observed = activityBloc.stream.firstWhere(
        (state) => state.observedCount == 1,
      );

      demoBloc.add(const DemoActionRequested());

      final activityState = await observed;
      expect(activityState.observedCount, 1);
      expect(activityState.lastObservedSequence, 1);
    },
  );
}
