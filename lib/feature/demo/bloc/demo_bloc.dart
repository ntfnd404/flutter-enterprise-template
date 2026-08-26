import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'demo_action.dart';
part 'demo_event.dart';
part 'demo_state.dart';

/// Presentation logic for the template's BLoC ownership example.
final class DemoBloc extends Bloc<DemoEvent, DemoState>
    with EphemeralBlocMixin<DemoState, DemoAction> {
  /// Creates the reference presentation BLoC.
  DemoBloc()
    : super(
        const DemoState(
          isReady: false,
          completedActions: 0,
        ),
      ) {
    on<DemoStarted>(_onStarted);
    on<DemoActionRequested>(_onActionRequested);
  }

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

    emitAction(ShowDemoActionCompletedAction(sequence: sequence));
  }
}
