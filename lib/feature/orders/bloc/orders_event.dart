part of 'orders_bloc.dart';

/// Base type for Orders presentation intents.
sealed class OrdersEvent {
  const OrdersEvent();
}

sealed class _OrdersObservationRequested extends OrdersEvent {
  const _OrdersObservationRequested();
}

/// Starts the authoritative Orders observation.
final class OrdersStarted extends _OrdersObservationRequested {
  /// Creates the initial observation request.
  const OrdersStarted();
}

/// Retries an observation after failure or normal completion.
final class OrdersRetryRequested extends _OrdersObservationRequested {
  /// Creates an explicit retry request.
  const OrdersRetryRequested();
}

final class _OrdersSnapshotReceived extends OrdersEvent {
  const _OrdersSnapshotReceived(this.orders);

  final List<Order> orders;
}

final class _OrdersObservationFailed extends OrdersEvent {
  const _OrdersObservationFailed(this.error, this.stackTrace);

  final Object error;
  final StackTrace stackTrace;
}

final class _OrdersObservationCompleted extends OrdersEvent {
  const _OrdersObservationCompleted();
}

/// Requests persistence of one empty draft.
final class OrdersDraftCreationRequested extends OrdersEvent {
  /// Creates a draft command intent.
  const OrdersDraftCreationRequested();
}

/// Requests cancellation of one authoritative Order.
final class OrdersCancellationRequested extends OrdersEvent {
  /// Creates a cancellation intent for [orderId].
  const OrdersCancellationRequested(this.orderId);

  /// Stable domain identity selected from current state.
  final OrderId orderId;
}
