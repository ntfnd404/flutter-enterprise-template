part of 'orders_bloc.dart';

/// One-shot instruction from Orders presentation logic to its own view.
sealed class OrdersAction {
  const OrdersAction();
}

/// Requests immediate navigation to a live operation monitor.
final class MonitorOrderDraftCreationAction extends OrdersAction {
  /// Creates a navigation intent for [operationSequence].
  const MonitorOrderDraftCreationAction(this.operationSequence);

  /// Positive, screen-lifetime correlation sequence.
  final int operationSequence;
}

/// Expected Orders command failure that can be shown transiently.
enum OrdersFailure {
  /// Local persistence is temporarily unavailable.
  storageUnavailable,

  /// The Order disappeared before cancellation.
  orderNotFound,

  /// Another operation changed the Order first.
  orderChanged,

  /// The Order was already terminally cancelled.
  alreadyCancelled,
}

/// Requests transient presentation of [failure].
final class ShowOrdersFailureAction extends OrdersAction {
  /// Creates an expected failure action.
  const ShowOrdersFailureAction(this.failure);

  /// Safe presentation classification.
  final OrdersFailure failure;
}
