import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/events/demo_action_completed_app_event.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';

part 'demo_action.dart';
part 'demo_event.dart';
part 'demo_state.dart';

/// Presentation logic for the template's BLoC ownership example.
final class DemoBloc extends Bloc<DemoEvent, DemoState>
    with EphemeralBlocMixin<DemoState, DemoAction> {
  /// Creates a demo BLoC that publishes successful cross-feature facts.
  DemoBloc({required this._eventBus})
    : super(
        const DemoState(
          isReady: false,
          completedActions: 0,
        ),
      ) {
    on<DemoStarted>(_onStarted);
    on<DemoActionRequested>(_onActionRequested);
  }

  final AppEventPublisher _eventBus;

  void _onStarted(DemoStarted event, Emitter<DemoState> emit) {
    emit(
      DemoState(
        isReady: true,
        completedActions: state.completedActions,
      ),
    );
  }

  void _onActionRequested(
    DemoActionRequested event,
    Emitter<DemoState> emit,
  ) {
    if (!state.isReady) {
      return;
    }

    final sequence = state.completedActions + 1;
    emit(DemoState(isReady: true, completedActions: sequence));

    // The persistent state, cross-feature fact, and same-feature UI command
    // are deliberately separate channels with different delivery semantics.
    _eventBus.emit(DemoActionCompletedAppEvent(sequence: sequence));
    emitAction(ShowDemoActionCompletedAction(sequence: sequence));
  }
}
