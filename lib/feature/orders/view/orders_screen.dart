import 'package:ephemeral_bloc/ephemeral_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ordering/ordering.dart';
import 'package:template/feature/orders/bloc/orders_bloc.dart';

/// Orders list with draft creation, cancellation, and live monitoring intent.
final class OrdersScreen extends StatelessWidget {
  /// Creates the reference Orders presentation.
  const OrdersScreen({required this.onMonitorDraftCreation, super.key});

  /// Opens a non-authoritative monitor for one operation sequence.
  final ValueChanged<int> onMonitorDraftCreation;

  @override
  Widget build(BuildContext context) =>
      EphemeralBlocListener<OrdersBloc, OrdersState, OrdersAction>(
        listener: (context, action) => _onAction(context, action),
        child: Scaffold(
          appBar: AppBar(title: const Text('Orders')),
          body: BlocBuilder<OrdersBloc, OrdersState>(
            builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (state.observationStatus == OrdersObservationStatus.loading)
                  const LinearProgressIndicator(
                    key: ValueKey<String>('orders-loading-progress'),
                  ),
                if (state.observationStatus ==
                    OrdersObservationStatus.unavailable)
                  const _OrdersUnavailablePanel(),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton(
                    key: const ValueKey<String>('orders-create-draft'),
                    onPressed: state.isCreatingDraft
                        ? null
                        : () => context.read<OrdersBloc>().add(
                            const OrdersDraftCreationRequested(),
                          ),
                    child: Text(
                      state.isCreatingDraft
                          ? 'Creating draft…'
                          : 'Create draft and monitor',
                    ),
                  ),
                ),
                Expanded(
                  child: state.orders.isEmpty
                      ? const Center(
                          child: Text(
                            'No orders',
                            key: ValueKey<String>('orders-empty'),
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.orders.length,
                          itemBuilder: (context, index) =>
                              _OrderTile(order: state.orders[index]),
                        ),
                ),
              ],
            ),
          ),
        ),
      );

  void _onAction(BuildContext context, OrdersAction action) {
    switch (action) {
      case MonitorOrderDraftCreationAction(:final operationSequence):
        onMonitorDraftCreation(operationSequence);
      case ShowOrdersFailureAction(:final failure):
        final message = switch (failure) {
          OrdersFailure.storageUnavailable =>
            'Orders storage is temporarily unavailable.',
          OrdersFailure.orderNotFound => 'The Order no longer exists.',
          OrdersFailure.orderChanged =>
            'The Order changed. Review the latest state and try again.',
          OrdersFailure.alreadyCancelled => 'The Order was already cancelled.',
        };
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
    }
  }
}

final class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) => ListTile(
    key: ValueKey<String>('order-${order.id.value}'),
    title: Text('Order ${order.id.value}'),
    subtitle: Text('${order.status.name} · ${order.lines.length} lines'),
    trailing: order.status == OrderStatus.cancelled
        ? const Icon(Icons.cancel_outlined)
        : IconButton(
            key: ValueKey<String>('cancel-order-${order.id.value}'),
            tooltip: 'Cancel Order',
            onPressed: () => context.read<OrdersBloc>().add(
              OrdersCancellationRequested(order.id),
            ),
            icon: const Icon(Icons.cancel_outlined),
          ),
  );
}

final class _OrdersUnavailablePanel extends StatelessWidget {
  const _OrdersUnavailablePanel();

  @override
  Widget build(BuildContext context) => Material(
    key: const ValueKey<String>('orders-unavailable'),
    color: Theme.of(context).colorScheme.errorContainer,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          const Expanded(
            child: Text('Orders updates are temporarily unavailable.'),
          ),
          TextButton(
            key: const ValueKey<String>('orders-retry'),
            onPressed: () => context.read<OrdersBloc>().add(
              const OrdersRetryRequested(),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}
