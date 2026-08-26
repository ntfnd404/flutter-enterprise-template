// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ordering_orders_dao.dart';

// ignore_for_file: type=lint
mixin _$OrderingOrdersDaoMixin on DatabaseAccessor<ApplicationDatabase> {
  OrderingOrders get orderingOrders => attachedDatabase.orderingOrders;
  OrderingOrderLines get orderingOrderLines =>
      attachedDatabase.orderingOrderLines;
  OrderingOrdersDaoManager get managers => OrderingOrdersDaoManager(this);
}

class OrderingOrdersDaoManager {
  final _$OrderingOrdersDaoMixin _db;
  OrderingOrdersDaoManager(this._db);
  $OrderingOrdersTableManager get orderingOrders =>
      $OrderingOrdersTableManager(_db.attachedDatabase, _db.orderingOrders);
  $OrderingOrderLinesTableManager get orderingOrderLines =>
      $OrderingOrderLinesTableManager(
        _db.attachedDatabase,
        _db.orderingOrderLines,
      );
}
