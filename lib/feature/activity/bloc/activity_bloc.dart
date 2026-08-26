import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/events/demo_action_completed_app_event.dart';
import 'package:template/core/event_bus/app_event_subscriber.dart';

part 'activity_event.dart';
part 'activity_state.dart';

/// Non-authoritative screen-lifetime projection of live best-effort facts.
///
/// It does not reconstruct missed history. Sequence gaps and a reset after
/// recreating the screen are expected and must not drive business decisions.
final class ActivityBloc extends Bloc<_ActivityEvent, ActivityState> {
  /// Creates an event-bus consumer without replay or historical state.
  ActivityBloc({required AppEventSubscriber eventBus})
    : super(const ActivityState(observedCount: 0)) {
    on<_DemoActionObserved>(_onDemoActionObserved);
    _subscription = eventBus.on<DemoActionCompletedAppEvent>().listen((event) {
      if (!isClosed) {
        add(_DemoActionObserved(event.sequence));
      }
    });
  }

  late final StreamSubscription<DemoActionCompletedAppEvent> _subscription;

  void _onDemoActionObserved(
    _DemoActionObserved event,
    Emitter<ActivityState> emit,
  ) {
    emit(
      ActivityState(
        observedCount: state.observedCount + 1,
        lastObservedSequence: event.sequence,
      ),
    );
  }

  @override
  Future<void> close() async {
    // Cancellation starts before the first asynchronous gap. Required
    // business persistence belongs in awaited operations, never in teardown.
    await _subscription.cancel();
    await super.close();
  }
}
