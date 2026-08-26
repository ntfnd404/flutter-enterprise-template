import 'package:ordering/src/domain/order/order.dart';
import 'package:ordering/src/domain/order/order_line.dart';
import 'package:ordering/src/domain/order/value_objects/order_status.dart';
import 'package:ordering/src/domain/ordering_exception.dart';

/// Ensures offer refresh changes snapshots, not the commercial intent.
final class OrderPlacementPolicy {
  /// Creates the stateless placement policy.
  const OrderPlacementPolicy();

  /// Verifies that refresh retained exactly the draft products and quantities.
  void validateRefresh({
    required Order draft,
    required List<OrderLine> refreshedLines,
  }) {
    if (draft.status != OrderStatus.draft) {
      throw const OrderingTransitionException(
        OrderingTransitionFailure.orderNotDraft,
      );
    }
    if (draft.lines.isEmpty || refreshedLines.isEmpty) {
      throw const OrderingEmptyOrderException();
    }
    final quantities = <int, int>{
      for (final line in draft.lines) line.product.value: line.quantity.value,
    };
    if (quantities.length != refreshedLines.length) {
      throw const OrderingProductUnavailableException();
    }
    for (final line in refreshedLines) {
      if (quantities[line.product.value] != line.quantity.value) {
        throw const OrderingProductUnavailableException();
      }
    }
  }
}
