import 'package:flutter_bloc/flutter_bloc.dart';

part 'startup_failure_event.dart';
part 'startup_failure_state.dart';

/// Presentation state owner for the isolated pre-DI startup fallback.
///
/// The scaffold intentionally has no concrete events yet. Future safe
/// recovery operations can be added without coupling this feature to the
/// failed normal dependency graph.
final class StartupFailureBloc extends Bloc<StartupFailureEvent, StartupFailureState> {
  /// Creates the BLoC with a privacy-safe support [diagnosticCode].
  StartupFailureBloc({required String diagnosticCode}) : super(StartupFailureState(diagnosticCode: diagnosticCode));
}
