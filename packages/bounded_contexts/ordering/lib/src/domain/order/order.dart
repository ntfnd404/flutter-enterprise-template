import 'dart:collection';

import 'package:ordering/src/domain/order/order_line.dart';
import 'package:ordering/src/domain/order/value_objects/order_id.dart';
import 'package:ordering/src/domain/order/value_objects/order_money.dart';
import 'package:ordering/src/domain/order/value_objects/order_revision.dart';
import 'package:ordering/src/domain/order/value_objects/order_status.dart';
import 'package:ordering/src/domain/ordering_exception.dart';

/// Persistent multi-line Order aggregate.
final class Order {
  Order._({
    required this.id,
    required List<OrderLine> lines,
    required this.money,
    required this.status,
    required this.revision,
    required this.createdAt,
    required this.placedAt,
    required this.cancelledAt,
  }) : lines = UnmodifiableListView<OrderLine>(lines);

  /// Reconstitutes an authoritative persisted aggregate strictly.
  factory Order.fromStored({
    required int id,
    required List<OrderLine> lines,
    required int? totalMinorUnits,
    required String? currencyCode,
    required int statusValue,
    required int revision,
    required int createdAtUtcMilliseconds,
    required int? placedAtUtcMilliseconds,
    required int? cancelledAtUtcMilliseconds,
  }) {
    final copiedLines = List<OrderLine>.unmodifiable(lines);
    final status = OrderStatus.fromStored(statusValue);
    final money = _moneyFromStored(
      lines: copiedLines,
      totalMinorUnits: totalMinorUnits,
      currencyCode: currencyCode,
    );
    final createdAt = _storedTime(createdAtUtcMilliseconds);
    final placedAt = placedAtUtcMilliseconds == null
        ? null
        : _storedTime(placedAtUtcMilliseconds);
    final cancelledAt = cancelledAtUtcMilliseconds == null
        ? null
        : _storedTime(cancelledAtUtcMilliseconds);
    _validateLifecycle(
      status: status,
      lines: copiedLines,
      money: money,
      placedAt: placedAt,
      cancelledAt: cancelledAt,
    );
    if (copiedLines.length > maxLineCount) {
      throw const OrderingDataIntegrityException();
    }
    _validateDistinctProducts(copiedLines, integrityFailure: true);

    return Order._(
      id: OrderId.fromStored(id),
      lines: copiedLines,
      money: money,
      status: status,
      revision: OrderRevision.fromStored(revision),
      createdAt: createdAt,
      placedAt: placedAt,
      cancelledAt: cancelledAt,
    );
  }

  /// Maximum number of distinct product lines in one Order.
  static const int maxLineCount = 100;

  /// Stable aggregate identity.
  final OrderId id;

  /// Immutable point-in-time line snapshots.
  final List<OrderLine> lines;

  /// Calculated money, absent only while an empty draft was retained.
  final OrderMoney? money;

  /// Current lifecycle state.
  final OrderStatus status;

  /// Optimistic concurrency token.
  final OrderRevision revision;

  /// UTC draft creation time.
  final DateTime createdAt;

  /// UTC placement time, when placement occurred.
  final DateTime? placedAt;

  /// UTC cancellation time, when cancellation occurred.
  final DateTime? cancelledAt;

  /// Returns a draft copy with the complete line set replaced.
  Order replaceDraftLines(List<OrderLine> replacement) {
    _requireDraft();
    final copied = List<OrderLine>.unmodifiable(replacement);
    _validateCommandLines(copied);
    final replacementMoney = copied.isEmpty
        ? null
        : OrderMoney.fromLines(copied);

    return Order._(
      id: id,
      lines: copied,
      money: replacementMoney,
      status: status,
      revision: revision.next(),
      createdAt: createdAt,
      placedAt: placedAt,
      cancelledAt: cancelledAt,
    );
  }

  /// Returns a placed snapshot using refreshed Catalog offer lines.
  Order placeWithRefreshedLines({
    required List<OrderLine> refreshedLines,
    required DateTime placedAt,
  }) {
    _requireDraft();
    final copied = List<OrderLine>.unmodifiable(refreshedLines);
    if (copied.isEmpty) {
      throw const OrderingEmptyOrderException();
    }
    _validateCommandLines(copied);

    return Order._(
      id: id,
      lines: copied,
      money: OrderMoney.fromLines(copied),
      status: OrderStatus.placed,
      revision: revision.next(),
      createdAt: createdAt,
      placedAt: placedAt.toUtc(),
      cancelledAt: null,
    );
  }

  /// Returns the terminal cancelled snapshot.
  Order cancel(DateTime cancelledAt) {
    if (status == OrderStatus.cancelled) {
      throw const OrderingTransitionException(
        OrderingTransitionFailure.orderAlreadyCancelled,
      );
    }

    return Order._(
      id: id,
      lines: lines,
      money: money,
      status: OrderStatus.cancelled,
      revision: revision.next(),
      createdAt: createdAt,
      placedAt: placedAt,
      cancelledAt: cancelledAt.toUtc(),
    );
  }

  void _requireDraft() {
    if (status != OrderStatus.draft) {
      throw const OrderingTransitionException(
        OrderingTransitionFailure.orderNotDraft,
      );
    }
  }

  static void _validateCommandLines(List<OrderLine> lines) {
    if (lines.length > maxLineCount) {
      throw const OrderingTooManyLinesException();
    }
    _validateDistinctProducts(lines, integrityFailure: false);
  }

  static void _validateDistinctProducts(
    List<OrderLine> lines, {
    required bool integrityFailure,
  }) {
    final products = <int>{};
    for (final line in lines) {
      if (!products.add(line.product.value)) {
        if (integrityFailure) {
          throw const OrderingDataIntegrityException();
        }
        throw const OrderingDuplicateProductException();
      }
    }
  }

  static OrderMoney? _moneyFromStored({
    required List<OrderLine> lines,
    required int? totalMinorUnits,
    required String? currencyCode,
  }) {
    if ((totalMinorUnits == null) != (currencyCode == null)) {
      throw const OrderingDataIntegrityException();
    }
    if (totalMinorUnits == null) {
      if (lines.isNotEmpty) {
        throw const OrderingDataIntegrityException();
      }

      return null;
    }

    final stored = OrderMoney.fromStored(
      minorUnits: totalMinorUnits,
      currencyCode: currencyCode!,
    );
    OrderMoney calculated;
    try {
      calculated = OrderMoney.fromLines(lines);
    } on OrderingExpectedException {
      throw const OrderingDataIntegrityException();
    }
    if (stored.minorUnits != calculated.minorUnits ||
        stored.currency != calculated.currency) {
      throw const OrderingDataIntegrityException();
    }

    return stored;
  }

  static void _validateLifecycle({
    required OrderStatus status,
    required List<OrderLine> lines,
    required OrderMoney? money,
    required DateTime? placedAt,
    required DateTime? cancelledAt,
  }) {
    final valid = switch (status) {
      OrderStatus.draft => placedAt == null && cancelledAt == null,
      OrderStatus.placed =>
        lines.isNotEmpty &&
            money != null &&
            placedAt != null &&
            cancelledAt == null,
      OrderStatus.cancelled =>
        cancelledAt != null &&
            (placedAt == null || (lines.isNotEmpty && money != null)),
    };
    if (!valid) {
      throw const OrderingDataIntegrityException();
    }
  }

  static DateTime _storedTime(int milliseconds) {
    if (milliseconds < 0 || milliseconds > _maxUtcMilliseconds) {
      throw const OrderingDataIntegrityException();
    }

    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  static const int _maxUtcMilliseconds = 8640000000000000;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Order && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
