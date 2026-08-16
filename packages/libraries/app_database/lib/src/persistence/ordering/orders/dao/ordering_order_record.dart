import 'package:app_database/src/application_database.dart';

/// Internal result of loading one Order row with its persisted line rows.
///
/// This type crosses only the private DAO-to-store boundary and never leaves
/// the database package.
final class OrderingOrderRecord({
  /// Generated parent row.
  required final OrderingOrder order,

  required List<OrderingOrderLine> lines,
}) {
  /// Creates an internal aggregate persistence record.
  this;

  /// Generated line rows ordered by Catalog product identifier.
  final List<OrderingOrderLine> lines = List<OrderingOrderLine>.unmodifiable(
    lines,
  );
}
