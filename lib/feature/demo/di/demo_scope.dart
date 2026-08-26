import 'package:flutter/widgets.dart';
import 'package:template/core/di/typedefs/factory.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';
import 'package:template/feature/demo/bloc/demo_bloc.dart';

/// Reusable feature composition scope that exposes a `DemoBloc` factory.
///
/// This intentionally demonstrates the multi-screen/subtree Factory Scope
/// pattern. A feature used by only one route may instead use a smaller static
/// composition helper. The scope creates no BLoC instance and owns no BLoC
/// lifecycle; `BlocProvider(create: ...)` remains the owner.
final class DemoScope extends StatelessWidget {
  /// Creates a demo feature composition boundary.
  const DemoScope({required this.eventBus, required this.child, super.key});

  /// Creates a new `DemoBloc` from the nearest [DemoScope].
  static DemoBloc createBloc(BuildContext context) {
    final scope = context.getInheritedWidgetOfExactType<_InheritedDemoScope>();
    if (scope == null) {
      throw StateError('DemoScope not found in widget tree.');
    }

    return scope.blocFactory();
  }

  /// Best-effort application event port captured by this feature boundary.
  final AppEventPublisher eventBus;

  /// The feature subtree that may request BLoC instances.
  final Widget child;

  DemoBloc _createBloc() => DemoBloc(eventBus: eventBus);

  @override
  Widget build(BuildContext context) => _InheritedDemoScope(
    blocFactory: _createBloc,
    child: child,
  );
}

final class _InheritedDemoScope extends InheritedWidget {
  const _InheritedDemoScope({
    required this.blocFactory,
    required super.child,
  });

  final Factory<DemoBloc> blocFactory;

  @override
  bool updateShouldNotify(_InheritedDemoScope oldWidget) => false;
}
