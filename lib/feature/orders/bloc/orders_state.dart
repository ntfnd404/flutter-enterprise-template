part of 'orders_bloc.dart';

/// Lifecycle of the authoritative Orders observation.
enum OrdersObservationStatus {
  /// Initial observation or retry is pending.
  loading,

  /// The authoritative stream is active.
  ready,

  /// The stream failed or completed and requires explicit retry.
  unavailable,
}

/// Immutable persistent state rendered by Orders presentation.
final class OrdersState {
  OrdersState._({
    required List<Order> orders,
    required this.observationStatus,
    required this.isCreatingDraft,
    required this.nextOperationSequence,
  }) : orders = List<Order>.unmodifiable(orders);

  /// Creates initial loading state.
  factory OrdersState.loading() => OrdersState._(
    orders: const [],
    observationStatus: OrdersObservationStatus.loading,
    isCreatingDraft: false,
    nextOperationSequence: 1,
  );

  /// Latest authoritative snapshot, retained while observation is unavailable.
  final List<Order> orders;

  /// Current watch lifecycle.
  final OrdersObservationStatus observationStatus;

  /// Whether one create-draft operation is active.
  final bool isCreatingDraft;

  /// Next positive, presentation-only correlation sequence.
  final int nextOperationSequence;

  OrdersState copyWith({
    List<Order>? orders,
    OrdersObservationStatus? observationStatus,
    bool? isCreatingDraft,
    int? nextOperationSequence,
  }) => OrdersState._(
    orders: orders ?? this.orders,
    observationStatus: observationStatus ?? this.observationStatus,
    isCreatingDraft: isCreatingDraft ?? this.isCreatingDraft,
    nextOperationSequence: nextOperationSequence ?? this.nextOperationSequence,
  );
}
