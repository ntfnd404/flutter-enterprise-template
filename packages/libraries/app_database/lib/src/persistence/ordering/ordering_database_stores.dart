import 'package:app_database/src/application_database.dart';
import 'package:app_database/src/persistence/ordering/orders/store/drift_ordering_orders_store.dart';
import 'package:app_database/src/persistence/ordering/orders/store/ordering_orders_store.dart';

/// Borrowed persistence stores owned by the Ordering context boundary.
///
/// The bundle is immutable and lifecycle-free. The application database
/// module remains the owner of the physical connection.
final class OrderingDatabaseStores._({
  /// Ordering aggregate persistence.
  required final OrderingOrdersStore orders,
});

/// Creates the Ordering store views over an initialized [database].
///
/// This package-internal assembly is synchronous and performs no I/O.
OrderingDatabaseStores createOrderingDatabaseStores(
  ApplicationDatabase database,
) => OrderingDatabaseStores._(
  orders: DriftOrderingOrdersStore(dao: database.orderingOrdersDao),
);
