import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/routing/app_route_fallback.dart';

part 'not_found_event.dart';
part 'not_found_state.dart';

/// Presentation state owner for privacy-safe route recovery.
///
/// The scaffold intentionally has no concrete events yet. Future recovery
/// behavior can extend this feature without moving state into app routing.
final class NotFoundBloc extends Bloc<NotFoundEvent, NotFoundState> {
  /// Creates the BLoC with the already-sanitized routing failure [reason].
  NotFoundBloc({required AppRouteFailureReason reason}) : super(NotFoundState(reason: reason));
}
