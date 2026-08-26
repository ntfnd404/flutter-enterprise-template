import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/events/order_draft_created_app_event.dart';
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
    on<_DraftCreationObserved>(_onDraftCreationObserved);
    _subscription = eventBus.on<OrderDraftCreatedAppEvent>().listen((event) {
      if (!isClosed) {
        add(_DraftCreationObserved(event.operationSequence));
      }
    });
  }

  late final StreamSubscription<OrderDraftCreatedAppEvent> _subscription;
  Future<void>? _closeFuture;

  void _onDraftCreationObserved(
    _DraftCreationObserved event,
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
  Future<void> close() {
    final existing = _closeFuture;
    if (existing != null) {
      return existing;
    }
    // Both phases start before returning because widget disposal cannot await
    // this Future. Graph teardown can still await the combined completion.
    final cancellation = _subscription.cancel();
    final blocClose = super.close();

    return _closeFuture = Future.wait(<Future<void>>[
      cancellation,
      blocClose,
    ]);
  }
}
