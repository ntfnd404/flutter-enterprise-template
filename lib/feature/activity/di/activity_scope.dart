import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/core/event_bus/app_event_subscriber.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';

/// Screen-lifetime composition boundary for Activity.
///
/// The BLoC subscribes when the route is built and is closed by BlocProvider
/// when the route leaves the tree. Events published before this scope exists
/// are intentionally not replayed by AppEventBus.
final class ActivityScope extends StatelessWidget {
  /// Creates the Activity composition boundary.
  const ActivityScope({
    required this.eventBus,
    required this.child,
    super.key,
  });

  /// Best-effort application event port observed by this screen.
  final AppEventSubscriber eventBus;

  /// The Activity subtree owned by this scope.
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<ActivityBloc>(
    create: (_) => ActivityBloc(eventBus: eventBus),
    child: child,
  );
}
