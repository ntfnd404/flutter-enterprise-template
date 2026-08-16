import 'package:ordering/src/domain/ordering_exception.dart';

/// Optimistic concurrency token of an Order snapshot.
final class const OrderRevision._(
  /// Non-negative revision value.
  final int value,
) {
  /// Reconstitutes a persisted revision.
  factory OrderRevision.fromStored(int value) {
    if (value < 0 || value > maxValue) {
      throw const OrderingDataIntegrityException();
    }

    return OrderRevision._(value);
  }

  /// Initial revision assigned to a new persistent draft.
  static const OrderRevision initial = OrderRevision._(0);

  /// Largest integer exactly represented by Dart VM and Web runtimes.
  static const int maxValue = 9007199254740991;

  /// Returns the next revision or rejects exhausted persisted state.
  OrderRevision next() {
    if (value >= maxValue) {
      throw const OrderingDataIntegrityException();
    }

    return OrderRevision._(value + 1);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is OrderRevision && value == other.value;

  @override
  int get hashCode => value.hashCode;
}
