import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/bloc/not_found_bloc.dart';

/// Privacy-safe recovery screen for unknown or malformed application routes.
final class NotFoundScreen extends StatelessWidget {
  /// Creates the route-recovery screen.
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<NotFoundBloc, NotFoundState>(
        builder: (context, state) => switch (state.reason) {
          AppRouteFailureReason.unknownRoute ||
          AppRouteFailureReason.invalidParameters ||
          AppRouteFailureReason.invalidRouteTree => const Scaffold(
            body: Center(
              child: Text(
                'Page not found',
                key: ValueKey<String>('not-found-marker'),
              ),
            ),
          ),
        },
      );
}
