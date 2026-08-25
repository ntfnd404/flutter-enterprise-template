import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/bloc/not_found_bloc.dart';

/// Screen-lifetime composition boundary for route recovery.
///
/// The scope creates no application dependency and exposes no service
/// locator. [BlocProvider] owns and closes the BLoC with the route subtree.
final class NotFoundScope extends StatelessWidget {
  /// Creates the route-recovery boundary for a sanitized [reason].
  const NotFoundScope({
    required this.reason,
    required this.child,
    super.key,
  });

  /// Privacy-safe reason supplied by application routing composition.
  final AppRouteFailureReason reason;

  /// Route subtree that consumes `NotFoundBloc`.
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<NotFoundBloc>(
    create: (_) => NotFoundBloc(reason: reason),
    child: child,
  );
}
