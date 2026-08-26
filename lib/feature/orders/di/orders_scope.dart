import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ordering/ordering.dart';
import 'package:template/core/event_bus/app_event_publisher.dart';
import 'package:template/feature/orders/bloc/orders_bloc.dart';

/// Route-lifetime owner that narrows app dependencies into `OrdersBloc`.
final class OrdersScope extends StatelessWidget {
  /// Creates an Orders feature scope.
  const OrdersScope({
    required this.ordering,
    required this.eventPublisher,
    required this.child,
    super.key,
  });

  /// Borrowed Ordering application facade.
  final OrderingFacade ordering;

  /// Borrowed best-effort publication role.
  final AppEventPublisher eventPublisher;

  /// Feature subtree whose BLoC is owned by this provider.
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<OrdersBloc>(
    create: (_) => OrdersBloc(
      ordering: ordering,
      eventPublisher: eventPublisher,
    )..add(const OrdersStarted()),
    child: child,
  );
}
