import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/demo/bloc/demo_bloc.dart';

/// Example screen whose BLoC is composed inside the feature boundary.
final class DemoScreen extends StatelessWidget {
  /// Creates the demo screen.
  const DemoScreen({
    required this.onOpenActivity,
    required this.onOpenCatalog,
    required this.onOpenOrders,
    super.key,
  });

  /// Opens the Activity monitor for a positive correlation sequence.
  final ValueChanged<int> onOpenActivity;

  /// Opens the Catalog reference feature.
  final VoidCallback onOpenCatalog;

  /// Opens the Orders reference feature.
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) => BlocProvider<DemoBloc>(
    create: (_) => DemoBloc()..add(const DemoStarted()),
    child: _DemoView(
      onOpenActivity: onOpenActivity,
      onOpenCatalog: onOpenCatalog,
      onOpenOrders: onOpenOrders,
    ),
  );
}

final class _DemoView extends StatelessWidget {
  const _DemoView({
    required this.onOpenActivity,
    required this.onOpenCatalog,
    required this.onOpenOrders,
  });

  final ValueChanged<int> onOpenActivity;
  final VoidCallback onOpenCatalog;
  final VoidCallback onOpenOrders;

  @override
  Widget build(BuildContext context) =>
      EphemeralBlocListener<DemoBloc, DemoState, DemoAction>(
        listener: _onAction,
        child: Scaffold(
          appBar: AppBar(title: const Text('Template')),
          body: Center(
            child: BlocBuilder<DemoBloc, DemoState>(
              builder: (context, state) => Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    state.isReady ? 'Template running' : 'Starting template…',
                    key: const ValueKey<String>('normal-app-marker'),
                  ),
                  Text(
                    'Completed actions: ${state.completedActions}',
                    key: const ValueKey<String>('demo-action-count'),
                  ),
                  FilledButton(
                    key: const ValueKey<String>('complete-demo-action'),
                    onPressed: state.isReady
                        ? () => context.read<DemoBloc>().add(
                            const DemoActionRequested(),
                          )
                        : null,
                    child: const Text('Complete demo action'),
                  ),
                  OutlinedButton(
                    key: const ValueKey<String>('open-catalog-route'),
                    onPressed: onOpenCatalog,
                    child: const Text('Open catalog'),
                  ),
                  OutlinedButton(
                    key: const ValueKey<String>('open-orders-route'),
                    onPressed: onOpenOrders,
                    child: const Text('Open orders'),
                  ),
                  OutlinedButton(
                    key: const ValueKey<String>('open-activity-route'),
                    onPressed: state.completedActions == 0
                        ? null
                        : () => onOpenActivity(state.completedActions),
                    child: const Text('Open activity'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  void _onAction(BuildContext context, DemoAction action) {
    switch (action) {
      case ShowDemoActionCompletedAction(:final sequence):
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                'Demo action $sequence completed',
                key: const ValueKey<String>('demo-action-snackbar'),
              ),
            ),
          );
    }
  }
}
