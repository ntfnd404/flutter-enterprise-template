// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_database.dart';

// ignore_for_file: type=lint
class OrderingOrders extends Table
    with TableInfo<OrderingOrders, OrderingOrder> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  OrderingOrders(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT CHECK (id > 0)',
  );
  static const VerificationMeta _statusValueMeta = const VerificationMeta(
    'statusValue',
  );
  late final GeneratedColumn<int> statusValue = GeneratedColumn<int>(
    'status_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (status_value IN (0, 1, 2))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _totalMinorUnitsMeta = const VerificationMeta(
    'totalMinorUnits',
  );
  late final GeneratedColumn<int> totalMinorUnits = GeneratedColumn<int>(
    'total_minor_units',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (total_minor_units IS NULL OR total_minor_units BETWEEN 1 AND 9007199254740991)',
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (currency_code IS NULL OR(currency_code GLOB \'[A-Z][A-Z][A-Z]\' AND currency_code <> \'XXX\'))',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (revision BETWEEN 0 AND 9007199254740991)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtUtcMillisecondsMeta =
      const VerificationMeta('createdAtUtcMilliseconds');
  late final GeneratedColumn<int> createdAtUtcMilliseconds =
      GeneratedColumn<int>(
        'created_at_utc_milliseconds',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL CHECK (created_at_utc_milliseconds BETWEEN 0 AND 8640000000000000)',
      );
  static const VerificationMeta _placedAtUtcMillisecondsMeta =
      const VerificationMeta('placedAtUtcMilliseconds');
  late final GeneratedColumn<int> placedAtUtcMilliseconds =
      GeneratedColumn<int>(
        'placed_at_utc_milliseconds',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'CHECK (placed_at_utc_milliseconds IS NULL OR placed_at_utc_milliseconds BETWEEN 0 AND 8640000000000000)',
      );
  static const VerificationMeta _cancelledAtUtcMillisecondsMeta =
      const VerificationMeta('cancelledAtUtcMilliseconds');
  late final GeneratedColumn<int> cancelledAtUtcMilliseconds =
      GeneratedColumn<int>(
        'cancelled_at_utc_milliseconds',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'CHECK (cancelled_at_utc_milliseconds IS NULL OR cancelled_at_utc_milliseconds BETWEEN 0 AND 8640000000000000)',
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    statusValue,
    totalMinorUnits,
    currencyCode,
    revision,
    createdAtUtcMilliseconds,
    placedAtUtcMilliseconds,
    cancelledAtUtcMilliseconds,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ordering_orders';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderingOrder> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('status_value')) {
      context.handle(
        _statusValueMeta,
        statusValue.isAcceptableOrUnknown(
          data['status_value']!,
          _statusValueMeta,
        ),
      );
    }
    if (data.containsKey('total_minor_units')) {
      context.handle(
        _totalMinorUnitsMeta,
        totalMinorUnits.isAcceptableOrUnknown(
          data['total_minor_units']!,
          _totalMinorUnitsMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    if (data.containsKey('created_at_utc_milliseconds')) {
      context.handle(
        _createdAtUtcMillisecondsMeta,
        createdAtUtcMilliseconds.isAcceptableOrUnknown(
          data['created_at_utc_milliseconds']!,
          _createdAtUtcMillisecondsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMillisecondsMeta);
    }
    if (data.containsKey('placed_at_utc_milliseconds')) {
      context.handle(
        _placedAtUtcMillisecondsMeta,
        placedAtUtcMilliseconds.isAcceptableOrUnknown(
          data['placed_at_utc_milliseconds']!,
          _placedAtUtcMillisecondsMeta,
        ),
      );
    }
    if (data.containsKey('cancelled_at_utc_milliseconds')) {
      context.handle(
        _cancelledAtUtcMillisecondsMeta,
        cancelledAtUtcMilliseconds.isAcceptableOrUnknown(
          data['cancelled_at_utc_milliseconds']!,
          _cancelledAtUtcMillisecondsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  OrderingOrder map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderingOrder(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      statusValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_value'],
      )!,
      totalMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_minor_units'],
      ),
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
      createdAtUtcMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_milliseconds'],
      )!,
      placedAtUtcMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}placed_at_utc_milliseconds'],
      ),
      cancelledAtUtcMilliseconds: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cancelled_at_utc_milliseconds'],
      ),
    );
  }

  @override
  OrderingOrders createAlias(String alias) {
    return OrderingOrders(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((total_minor_units IS NULL AND currency_code IS NULL)OR(total_minor_units IS NOT NULL AND currency_code IS NOT NULL))',
    'CHECK((status_value = 0 AND placed_at_utc_milliseconds IS NULL AND cancelled_at_utc_milliseconds IS NULL)OR(status_value = 1 AND total_minor_units IS NOT NULL AND currency_code IS NOT NULL AND placed_at_utc_milliseconds IS NOT NULL AND cancelled_at_utc_milliseconds IS NULL)OR(status_value = 2 AND cancelled_at_utc_milliseconds IS NOT NULL AND(placed_at_utc_milliseconds IS NULL OR(total_minor_units IS NOT NULL AND currency_code IS NOT NULL))))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class OrderingOrder extends DataClass implements Insertable<OrderingOrder> {
  final int id;
  final int statusValue;
  final int? totalMinorUnits;
  final String? currencyCode;
  final int revision;
  final int createdAtUtcMilliseconds;
  final int? placedAtUtcMilliseconds;
  final int? cancelledAtUtcMilliseconds;
  const OrderingOrder({
    required this.id,
    required this.statusValue,
    this.totalMinorUnits,
    this.currencyCode,
    required this.revision,
    required this.createdAtUtcMilliseconds,
    this.placedAtUtcMilliseconds,
    this.cancelledAtUtcMilliseconds,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['status_value'] = Variable<int>(statusValue);
    if (!nullToAbsent || totalMinorUnits != null) {
      map['total_minor_units'] = Variable<int>(totalMinorUnits);
    }
    if (!nullToAbsent || currencyCode != null) {
      map['currency_code'] = Variable<String>(currencyCode);
    }
    map['revision'] = Variable<int>(revision);
    map['created_at_utc_milliseconds'] = Variable<int>(
      createdAtUtcMilliseconds,
    );
    if (!nullToAbsent || placedAtUtcMilliseconds != null) {
      map['placed_at_utc_milliseconds'] = Variable<int>(
        placedAtUtcMilliseconds,
      );
    }
    if (!nullToAbsent || cancelledAtUtcMilliseconds != null) {
      map['cancelled_at_utc_milliseconds'] = Variable<int>(
        cancelledAtUtcMilliseconds,
      );
    }
    return map;
  }

  OrderingOrdersCompanion toCompanion(bool nullToAbsent) {
    return OrderingOrdersCompanion(
      id: Value(id),
      statusValue: Value(statusValue),
      totalMinorUnits: totalMinorUnits == null && nullToAbsent
          ? const Value.absent()
          : Value(totalMinorUnits),
      currencyCode: currencyCode == null && nullToAbsent
          ? const Value.absent()
          : Value(currencyCode),
      revision: Value(revision),
      createdAtUtcMilliseconds: Value(createdAtUtcMilliseconds),
      placedAtUtcMilliseconds: placedAtUtcMilliseconds == null && nullToAbsent
          ? const Value.absent()
          : Value(placedAtUtcMilliseconds),
      cancelledAtUtcMilliseconds:
          cancelledAtUtcMilliseconds == null && nullToAbsent
          ? const Value.absent()
          : Value(cancelledAtUtcMilliseconds),
    );
  }

  factory OrderingOrder.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderingOrder(
      id: serializer.fromJson<int>(json['id']),
      statusValue: serializer.fromJson<int>(json['status_value']),
      totalMinorUnits: serializer.fromJson<int?>(json['total_minor_units']),
      currencyCode: serializer.fromJson<String?>(json['currency_code']),
      revision: serializer.fromJson<int>(json['revision']),
      createdAtUtcMilliseconds: serializer.fromJson<int>(
        json['created_at_utc_milliseconds'],
      ),
      placedAtUtcMilliseconds: serializer.fromJson<int?>(
        json['placed_at_utc_milliseconds'],
      ),
      cancelledAtUtcMilliseconds: serializer.fromJson<int?>(
        json['cancelled_at_utc_milliseconds'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'status_value': serializer.toJson<int>(statusValue),
      'total_minor_units': serializer.toJson<int?>(totalMinorUnits),
      'currency_code': serializer.toJson<String?>(currencyCode),
      'revision': serializer.toJson<int>(revision),
      'created_at_utc_milliseconds': serializer.toJson<int>(
        createdAtUtcMilliseconds,
      ),
      'placed_at_utc_milliseconds': serializer.toJson<int?>(
        placedAtUtcMilliseconds,
      ),
      'cancelled_at_utc_milliseconds': serializer.toJson<int?>(
        cancelledAtUtcMilliseconds,
      ),
    };
  }

  OrderingOrder copyWith({
    int? id,
    int? statusValue,
    Value<int?> totalMinorUnits = const Value.absent(),
    Value<String?> currencyCode = const Value.absent(),
    int? revision,
    int? createdAtUtcMilliseconds,
    Value<int?> placedAtUtcMilliseconds = const Value.absent(),
    Value<int?> cancelledAtUtcMilliseconds = const Value.absent(),
  }) => OrderingOrder(
    id: id ?? this.id,
    statusValue: statusValue ?? this.statusValue,
    totalMinorUnits: totalMinorUnits.present
        ? totalMinorUnits.value
        : this.totalMinorUnits,
    currencyCode: currencyCode.present ? currencyCode.value : this.currencyCode,
    revision: revision ?? this.revision,
    createdAtUtcMilliseconds:
        createdAtUtcMilliseconds ?? this.createdAtUtcMilliseconds,
    placedAtUtcMilliseconds: placedAtUtcMilliseconds.present
        ? placedAtUtcMilliseconds.value
        : this.placedAtUtcMilliseconds,
    cancelledAtUtcMilliseconds: cancelledAtUtcMilliseconds.present
        ? cancelledAtUtcMilliseconds.value
        : this.cancelledAtUtcMilliseconds,
  );
  OrderingOrder copyWithCompanion(OrderingOrdersCompanion data) {
    return OrderingOrder(
      id: data.id.present ? data.id.value : this.id,
      statusValue: data.statusValue.present
          ? data.statusValue.value
          : this.statusValue,
      totalMinorUnits: data.totalMinorUnits.present
          ? data.totalMinorUnits.value
          : this.totalMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      revision: data.revision.present ? data.revision.value : this.revision,
      createdAtUtcMilliseconds: data.createdAtUtcMilliseconds.present
          ? data.createdAtUtcMilliseconds.value
          : this.createdAtUtcMilliseconds,
      placedAtUtcMilliseconds: data.placedAtUtcMilliseconds.present
          ? data.placedAtUtcMilliseconds.value
          : this.placedAtUtcMilliseconds,
      cancelledAtUtcMilliseconds: data.cancelledAtUtcMilliseconds.present
          ? data.cancelledAtUtcMilliseconds.value
          : this.cancelledAtUtcMilliseconds,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderingOrder(')
          ..write('id: $id, ')
          ..write('statusValue: $statusValue, ')
          ..write('totalMinorUnits: $totalMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('revision: $revision, ')
          ..write('createdAtUtcMilliseconds: $createdAtUtcMilliseconds, ')
          ..write('placedAtUtcMilliseconds: $placedAtUtcMilliseconds, ')
          ..write('cancelledAtUtcMilliseconds: $cancelledAtUtcMilliseconds')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    statusValue,
    totalMinorUnits,
    currencyCode,
    revision,
    createdAtUtcMilliseconds,
    placedAtUtcMilliseconds,
    cancelledAtUtcMilliseconds,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderingOrder &&
          other.id == this.id &&
          other.statusValue == this.statusValue &&
          other.totalMinorUnits == this.totalMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.revision == this.revision &&
          other.createdAtUtcMilliseconds == this.createdAtUtcMilliseconds &&
          other.placedAtUtcMilliseconds == this.placedAtUtcMilliseconds &&
          other.cancelledAtUtcMilliseconds == this.cancelledAtUtcMilliseconds);
}

class OrderingOrdersCompanion extends UpdateCompanion<OrderingOrder> {
  final Value<int> id;
  final Value<int> statusValue;
  final Value<int?> totalMinorUnits;
  final Value<String?> currencyCode;
  final Value<int> revision;
  final Value<int> createdAtUtcMilliseconds;
  final Value<int?> placedAtUtcMilliseconds;
  final Value<int?> cancelledAtUtcMilliseconds;
  const OrderingOrdersCompanion({
    this.id = const Value.absent(),
    this.statusValue = const Value.absent(),
    this.totalMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.revision = const Value.absent(),
    this.createdAtUtcMilliseconds = const Value.absent(),
    this.placedAtUtcMilliseconds = const Value.absent(),
    this.cancelledAtUtcMilliseconds = const Value.absent(),
  });
  OrderingOrdersCompanion.insert({
    this.id = const Value.absent(),
    this.statusValue = const Value.absent(),
    this.totalMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.revision = const Value.absent(),
    required int createdAtUtcMilliseconds,
    this.placedAtUtcMilliseconds = const Value.absent(),
    this.cancelledAtUtcMilliseconds = const Value.absent(),
  }) : createdAtUtcMilliseconds = Value(createdAtUtcMilliseconds);
  static Insertable<OrderingOrder> custom({
    Expression<int>? id,
    Expression<int>? statusValue,
    Expression<int>? totalMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? revision,
    Expression<int>? createdAtUtcMilliseconds,
    Expression<int>? placedAtUtcMilliseconds,
    Expression<int>? cancelledAtUtcMilliseconds,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (statusValue != null) 'status_value': statusValue,
      if (totalMinorUnits != null) 'total_minor_units': totalMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (revision != null) 'revision': revision,
      if (createdAtUtcMilliseconds != null)
        'created_at_utc_milliseconds': createdAtUtcMilliseconds,
      if (placedAtUtcMilliseconds != null)
        'placed_at_utc_milliseconds': placedAtUtcMilliseconds,
      if (cancelledAtUtcMilliseconds != null)
        'cancelled_at_utc_milliseconds': cancelledAtUtcMilliseconds,
    });
  }

  OrderingOrdersCompanion copyWith({
    Value<int>? id,
    Value<int>? statusValue,
    Value<int?>? totalMinorUnits,
    Value<String?>? currencyCode,
    Value<int>? revision,
    Value<int>? createdAtUtcMilliseconds,
    Value<int?>? placedAtUtcMilliseconds,
    Value<int?>? cancelledAtUtcMilliseconds,
  }) {
    return OrderingOrdersCompanion(
      id: id ?? this.id,
      statusValue: statusValue ?? this.statusValue,
      totalMinorUnits: totalMinorUnits ?? this.totalMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      revision: revision ?? this.revision,
      createdAtUtcMilliseconds:
          createdAtUtcMilliseconds ?? this.createdAtUtcMilliseconds,
      placedAtUtcMilliseconds:
          placedAtUtcMilliseconds ?? this.placedAtUtcMilliseconds,
      cancelledAtUtcMilliseconds:
          cancelledAtUtcMilliseconds ?? this.cancelledAtUtcMilliseconds,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (statusValue.present) {
      map['status_value'] = Variable<int>(statusValue.value);
    }
    if (totalMinorUnits.present) {
      map['total_minor_units'] = Variable<int>(totalMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    if (createdAtUtcMilliseconds.present) {
      map['created_at_utc_milliseconds'] = Variable<int>(
        createdAtUtcMilliseconds.value,
      );
    }
    if (placedAtUtcMilliseconds.present) {
      map['placed_at_utc_milliseconds'] = Variable<int>(
        placedAtUtcMilliseconds.value,
      );
    }
    if (cancelledAtUtcMilliseconds.present) {
      map['cancelled_at_utc_milliseconds'] = Variable<int>(
        cancelledAtUtcMilliseconds.value,
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderingOrdersCompanion(')
          ..write('id: $id, ')
          ..write('statusValue: $statusValue, ')
          ..write('totalMinorUnits: $totalMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('revision: $revision, ')
          ..write('createdAtUtcMilliseconds: $createdAtUtcMilliseconds, ')
          ..write('placedAtUtcMilliseconds: $placedAtUtcMilliseconds, ')
          ..write('cancelledAtUtcMilliseconds: $cancelledAtUtcMilliseconds')
          ..write(')'))
        .toString();
  }
}

class OrderingOrderLines extends Table
    with TableInfo<OrderingOrderLines, OrderingOrderLine> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  OrderingOrderLines(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _orderIdMeta = const VerificationMeta(
    'orderId',
  );
  late final GeneratedColumn<int> orderId = GeneratedColumn<int>(
    'order_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES ordering_orders(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _catalogProductIdMeta = const VerificationMeta(
    'catalogProductId',
  );
  late final GeneratedColumn<int> catalogProductId = GeneratedColumn<int>(
    'catalog_product_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (catalog_product_id > 0)',
  );
  static const VerificationMeta _productTitleSnapshotMeta =
      const VerificationMeta('productTitleSnapshot');
  late final GeneratedColumn<String> productTitleSnapshot =
      GeneratedColumn<String>(
        'product_title_snapshot',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (length(product_title_snapshot) > 0)',
      );
  static const VerificationMeta _unitPriceMinorUnitsMeta =
      const VerificationMeta('unitPriceMinorUnits');
  late final GeneratedColumn<int> unitPriceMinorUnits = GeneratedColumn<int>(
    'unit_price_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (unit_price_minor_units BETWEEN 1 AND 9007199254740991)',
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (currency_code GLOB \'[A-Z][A-Z][A-Z]\' AND currency_code <> \'XXX\')',
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  late final GeneratedColumn<int> quantity = GeneratedColumn<int>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (quantity BETWEEN 1 AND 9007199254740991)',
  );
  static const VerificationMeta _catalogRevisionMeta = const VerificationMeta(
    'catalogRevision',
  );
  late final GeneratedColumn<int> catalogRevision = GeneratedColumn<int>(
    'catalog_revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (catalog_revision BETWEEN 0 AND 9007199254740991)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    orderId,
    catalogProductId,
    productTitleSnapshot,
    unitPriceMinorUnits,
    currencyCode,
    quantity,
    catalogRevision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ordering_order_lines';
  @override
  VerificationContext validateIntegrity(
    Insertable<OrderingOrderLine> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('order_id')) {
      context.handle(
        _orderIdMeta,
        orderId.isAcceptableOrUnknown(data['order_id']!, _orderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_orderIdMeta);
    }
    if (data.containsKey('catalog_product_id')) {
      context.handle(
        _catalogProductIdMeta,
        catalogProductId.isAcceptableOrUnknown(
          data['catalog_product_id']!,
          _catalogProductIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogProductIdMeta);
    }
    if (data.containsKey('product_title_snapshot')) {
      context.handle(
        _productTitleSnapshotMeta,
        productTitleSnapshot.isAcceptableOrUnknown(
          data['product_title_snapshot']!,
          _productTitleSnapshotMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_productTitleSnapshotMeta);
    }
    if (data.containsKey('unit_price_minor_units')) {
      context.handle(
        _unitPriceMinorUnitsMeta,
        unitPriceMinorUnits.isAcceptableOrUnknown(
          data['unit_price_minor_units']!,
          _unitPriceMinorUnitsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMinorUnitsMeta);
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_currencyCodeMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('catalog_revision')) {
      context.handle(
        _catalogRevisionMeta,
        catalogRevision.isAcceptableOrUnknown(
          data['catalog_revision']!,
          _catalogRevisionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_catalogRevisionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {orderId, catalogProductId};
  @override
  OrderingOrderLine map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OrderingOrderLine(
      orderId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}order_id'],
      )!,
      catalogProductId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_product_id'],
      )!,
      productTitleSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}product_title_snapshot'],
      )!,
      unitPriceMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unit_price_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantity'],
      )!,
      catalogRevision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}catalog_revision'],
      )!,
    );
  }

  @override
  OrderingOrderLines createAlias(String alias) {
    return OrderingOrderLines(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(order_id, catalog_product_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class OrderingOrderLine extends DataClass
    implements Insertable<OrderingOrderLine> {
  final int orderId;
  final int catalogProductId;
  final String productTitleSnapshot;
  final int unitPriceMinorUnits;
  final String currencyCode;
  final int quantity;
  final int catalogRevision;
  const OrderingOrderLine({
    required this.orderId,
    required this.catalogProductId,
    required this.productTitleSnapshot,
    required this.unitPriceMinorUnits,
    required this.currencyCode,
    required this.quantity,
    required this.catalogRevision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['order_id'] = Variable<int>(orderId);
    map['catalog_product_id'] = Variable<int>(catalogProductId);
    map['product_title_snapshot'] = Variable<String>(productTitleSnapshot);
    map['unit_price_minor_units'] = Variable<int>(unitPriceMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['quantity'] = Variable<int>(quantity);
    map['catalog_revision'] = Variable<int>(catalogRevision);
    return map;
  }

  OrderingOrderLinesCompanion toCompanion(bool nullToAbsent) {
    return OrderingOrderLinesCompanion(
      orderId: Value(orderId),
      catalogProductId: Value(catalogProductId),
      productTitleSnapshot: Value(productTitleSnapshot),
      unitPriceMinorUnits: Value(unitPriceMinorUnits),
      currencyCode: Value(currencyCode),
      quantity: Value(quantity),
      catalogRevision: Value(catalogRevision),
    );
  }

  factory OrderingOrderLine.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OrderingOrderLine(
      orderId: serializer.fromJson<int>(json['order_id']),
      catalogProductId: serializer.fromJson<int>(json['catalog_product_id']),
      productTitleSnapshot: serializer.fromJson<String>(
        json['product_title_snapshot'],
      ),
      unitPriceMinorUnits: serializer.fromJson<int>(
        json['unit_price_minor_units'],
      ),
      currencyCode: serializer.fromJson<String>(json['currency_code']),
      quantity: serializer.fromJson<int>(json['quantity']),
      catalogRevision: serializer.fromJson<int>(json['catalog_revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'order_id': serializer.toJson<int>(orderId),
      'catalog_product_id': serializer.toJson<int>(catalogProductId),
      'product_title_snapshot': serializer.toJson<String>(productTitleSnapshot),
      'unit_price_minor_units': serializer.toJson<int>(unitPriceMinorUnits),
      'currency_code': serializer.toJson<String>(currencyCode),
      'quantity': serializer.toJson<int>(quantity),
      'catalog_revision': serializer.toJson<int>(catalogRevision),
    };
  }

  OrderingOrderLine copyWith({
    int? orderId,
    int? catalogProductId,
    String? productTitleSnapshot,
    int? unitPriceMinorUnits,
    String? currencyCode,
    int? quantity,
    int? catalogRevision,
  }) => OrderingOrderLine(
    orderId: orderId ?? this.orderId,
    catalogProductId: catalogProductId ?? this.catalogProductId,
    productTitleSnapshot: productTitleSnapshot ?? this.productTitleSnapshot,
    unitPriceMinorUnits: unitPriceMinorUnits ?? this.unitPriceMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    quantity: quantity ?? this.quantity,
    catalogRevision: catalogRevision ?? this.catalogRevision,
  );
  OrderingOrderLine copyWithCompanion(OrderingOrderLinesCompanion data) {
    return OrderingOrderLine(
      orderId: data.orderId.present ? data.orderId.value : this.orderId,
      catalogProductId: data.catalogProductId.present
          ? data.catalogProductId.value
          : this.catalogProductId,
      productTitleSnapshot: data.productTitleSnapshot.present
          ? data.productTitleSnapshot.value
          : this.productTitleSnapshot,
      unitPriceMinorUnits: data.unitPriceMinorUnits.present
          ? data.unitPriceMinorUnits.value
          : this.unitPriceMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      catalogRevision: data.catalogRevision.present
          ? data.catalogRevision.value
          : this.catalogRevision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OrderingOrderLine(')
          ..write('orderId: $orderId, ')
          ..write('catalogProductId: $catalogProductId, ')
          ..write('productTitleSnapshot: $productTitleSnapshot, ')
          ..write('unitPriceMinorUnits: $unitPriceMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantity: $quantity, ')
          ..write('catalogRevision: $catalogRevision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    orderId,
    catalogProductId,
    productTitleSnapshot,
    unitPriceMinorUnits,
    currencyCode,
    quantity,
    catalogRevision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OrderingOrderLine &&
          other.orderId == this.orderId &&
          other.catalogProductId == this.catalogProductId &&
          other.productTitleSnapshot == this.productTitleSnapshot &&
          other.unitPriceMinorUnits == this.unitPriceMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.quantity == this.quantity &&
          other.catalogRevision == this.catalogRevision);
}

class OrderingOrderLinesCompanion extends UpdateCompanion<OrderingOrderLine> {
  final Value<int> orderId;
  final Value<int> catalogProductId;
  final Value<String> productTitleSnapshot;
  final Value<int> unitPriceMinorUnits;
  final Value<String> currencyCode;
  final Value<int> quantity;
  final Value<int> catalogRevision;
  final Value<int> rowid;
  const OrderingOrderLinesCompanion({
    this.orderId = const Value.absent(),
    this.catalogProductId = const Value.absent(),
    this.productTitleSnapshot = const Value.absent(),
    this.unitPriceMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.quantity = const Value.absent(),
    this.catalogRevision = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OrderingOrderLinesCompanion.insert({
    required int orderId,
    required int catalogProductId,
    required String productTitleSnapshot,
    required int unitPriceMinorUnits,
    required String currencyCode,
    required int quantity,
    required int catalogRevision,
    this.rowid = const Value.absent(),
  }) : orderId = Value(orderId),
       catalogProductId = Value(catalogProductId),
       productTitleSnapshot = Value(productTitleSnapshot),
       unitPriceMinorUnits = Value(unitPriceMinorUnits),
       currencyCode = Value(currencyCode),
       quantity = Value(quantity),
       catalogRevision = Value(catalogRevision);
  static Insertable<OrderingOrderLine> custom({
    Expression<int>? orderId,
    Expression<int>? catalogProductId,
    Expression<String>? productTitleSnapshot,
    Expression<int>? unitPriceMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? quantity,
    Expression<int>? catalogRevision,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (orderId != null) 'order_id': orderId,
      if (catalogProductId != null) 'catalog_product_id': catalogProductId,
      if (productTitleSnapshot != null)
        'product_title_snapshot': productTitleSnapshot,
      if (unitPriceMinorUnits != null)
        'unit_price_minor_units': unitPriceMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (quantity != null) 'quantity': quantity,
      if (catalogRevision != null) 'catalog_revision': catalogRevision,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OrderingOrderLinesCompanion copyWith({
    Value<int>? orderId,
    Value<int>? catalogProductId,
    Value<String>? productTitleSnapshot,
    Value<int>? unitPriceMinorUnits,
    Value<String>? currencyCode,
    Value<int>? quantity,
    Value<int>? catalogRevision,
    Value<int>? rowid,
  }) {
    return OrderingOrderLinesCompanion(
      orderId: orderId ?? this.orderId,
      catalogProductId: catalogProductId ?? this.catalogProductId,
      productTitleSnapshot: productTitleSnapshot ?? this.productTitleSnapshot,
      unitPriceMinorUnits: unitPriceMinorUnits ?? this.unitPriceMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      quantity: quantity ?? this.quantity,
      catalogRevision: catalogRevision ?? this.catalogRevision,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (orderId.present) {
      map['order_id'] = Variable<int>(orderId.value);
    }
    if (catalogProductId.present) {
      map['catalog_product_id'] = Variable<int>(catalogProductId.value);
    }
    if (productTitleSnapshot.present) {
      map['product_title_snapshot'] = Variable<String>(
        productTitleSnapshot.value,
      );
    }
    if (unitPriceMinorUnits.present) {
      map['unit_price_minor_units'] = Variable<int>(unitPriceMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<int>(quantity.value);
    }
    if (catalogRevision.present) {
      map['catalog_revision'] = Variable<int>(catalogRevision.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OrderingOrderLinesCompanion(')
          ..write('orderId: $orderId, ')
          ..write('catalogProductId: $catalogProductId, ')
          ..write('productTitleSnapshot: $productTitleSnapshot, ')
          ..write('unitPriceMinorUnits: $unitPriceMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('quantity: $quantity, ')
          ..write('catalogRevision: $catalogRevision, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CatalogCategories extends Table
    with TableInfo<CatalogCategories, CatalogCategory> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatalogCategories(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT CHECK (id > 0)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(name) > 0)',
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT TRUE CHECK (is_active IN (FALSE, TRUE))',
    defaultValue: const CustomExpression('TRUE'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isActive];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogCategory> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogCategory map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogCategory(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
    );
  }

  @override
  CatalogCategories createAlias(String alias) {
    return CatalogCategories(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatalogCategory extends DataClass implements Insertable<CatalogCategory> {
  final int id;
  final String name;
  final bool isActive;
  const CatalogCategory({
    required this.id,
    required this.name,
    required this.isActive,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['is_active'] = Variable<bool>(isActive);
    return map;
  }

  CatalogCategoriesCompanion toCompanion(bool nullToAbsent) {
    return CatalogCategoriesCompanion(
      id: Value(id),
      name: Value(name),
      isActive: Value(isActive),
    );
  }

  factory CatalogCategory.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogCategory(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isActive: serializer.fromJson<bool>(json['is_active']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'is_active': serializer.toJson<bool>(isActive),
    };
  }

  CatalogCategory copyWith({int? id, String? name, bool? isActive}) =>
      CatalogCategory(
        id: id ?? this.id,
        name: name ?? this.name,
        isActive: isActive ?? this.isActive,
      );
  CatalogCategory copyWithCompanion(CatalogCategoriesCompanion data) {
    return CatalogCategory(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCategory(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isActive);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogCategory &&
          other.id == this.id &&
          other.name == this.name &&
          other.isActive == this.isActive);
}

class CatalogCategoriesCompanion extends UpdateCompanion<CatalogCategory> {
  final Value<int> id;
  final Value<String> name;
  final Value<bool> isActive;
  const CatalogCategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isActive = const Value.absent(),
  });
  CatalogCategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.isActive = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CatalogCategory> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<bool>? isActive,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isActive != null) 'is_active': isActive,
    });
  }

  CatalogCategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<bool>? isActive,
  }) {
    return CatalogCategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogCategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isActive: $isActive')
          ..write(')'))
        .toString();
  }
}

class CatalogItems extends Table with TableInfo<CatalogItems, CatalogItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CatalogItems(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY AUTOINCREMENT CHECK (id > 0)',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(title) > 0)',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _priceMinorUnitsMeta = const VerificationMeta(
    'priceMinorUnits',
  );
  late final GeneratedColumn<int> priceMinorUnits = GeneratedColumn<int>(
    'price_minor_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (price_minor_units BETWEEN 0 AND 9007199254740991)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _currencyCodeMeta = const VerificationMeta(
    'currencyCode',
  );
  late final GeneratedColumn<String> currencyCode = GeneratedColumn<String>(
    'currency_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'XXX\' CHECK (currency_code GLOB \'[A-Z][A-Z][A-Z]\')',
    defaultValue: const CustomExpression('\'XXX\''),
  );
  static const VerificationMeta _statusValueMeta = const VerificationMeta(
    'statusValue',
  );
  late final GeneratedColumn<int> statusValue = GeneratedColumn<int>(
    'status_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (status_value IN (0, 1, 2))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES catalog_categories(id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _revisionMeta = const VerificationMeta(
    'revision',
  );
  late final GeneratedColumn<int> revision = GeneratedColumn<int>(
    'revision',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (revision BETWEEN 0 AND 9007199254740991)',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    priceMinorUnits,
    currencyCode,
    statusValue,
    categoryId,
    revision,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'catalog_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<CatalogItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('price_minor_units')) {
      context.handle(
        _priceMinorUnitsMeta,
        priceMinorUnits.isAcceptableOrUnknown(
          data['price_minor_units']!,
          _priceMinorUnitsMeta,
        ),
      );
    }
    if (data.containsKey('currency_code')) {
      context.handle(
        _currencyCodeMeta,
        currencyCode.isAcceptableOrUnknown(
          data['currency_code']!,
          _currencyCodeMeta,
        ),
      );
    }
    if (data.containsKey('status_value')) {
      context.handle(
        _statusValueMeta,
        statusValue.isAcceptableOrUnknown(
          data['status_value']!,
          _statusValueMeta,
        ),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('revision')) {
      context.handle(
        _revisionMeta,
        revision.isAcceptableOrUnknown(data['revision']!, _revisionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CatalogItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CatalogItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      priceMinorUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}price_minor_units'],
      )!,
      currencyCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}currency_code'],
      )!,
      statusValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}status_value'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      revision: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}revision'],
      )!,
    );
  }

  @override
  CatalogItems createAlias(String alias) {
    return CatalogItems(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(status_value = 0 OR(length(description) > 0 AND price_minor_units > 0 AND currency_code <> \'XXX\' AND category_id IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CatalogItem extends DataClass implements Insertable<CatalogItem> {
  final int id;
  final String title;
  final String description;
  final int priceMinorUnits;
  final String currencyCode;
  final int statusValue;
  final int? categoryId;
  final int revision;
  const CatalogItem({
    required this.id,
    required this.title,
    required this.description,
    required this.priceMinorUnits,
    required this.currencyCode,
    required this.statusValue,
    this.categoryId,
    required this.revision,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['description'] = Variable<String>(description);
    map['price_minor_units'] = Variable<int>(priceMinorUnits);
    map['currency_code'] = Variable<String>(currencyCode);
    map['status_value'] = Variable<int>(statusValue);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['revision'] = Variable<int>(revision);
    return map;
  }

  CatalogItemsCompanion toCompanion(bool nullToAbsent) {
    return CatalogItemsCompanion(
      id: Value(id),
      title: Value(title),
      description: Value(description),
      priceMinorUnits: Value(priceMinorUnits),
      currencyCode: Value(currencyCode),
      statusValue: Value(statusValue),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      revision: Value(revision),
    );
  }

  factory CatalogItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CatalogItem(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String>(json['description']),
      priceMinorUnits: serializer.fromJson<int>(json['price_minor_units']),
      currencyCode: serializer.fromJson<String>(json['currency_code']),
      statusValue: serializer.fromJson<int>(json['status_value']),
      categoryId: serializer.fromJson<int?>(json['category_id']),
      revision: serializer.fromJson<int>(json['revision']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String>(description),
      'price_minor_units': serializer.toJson<int>(priceMinorUnits),
      'currency_code': serializer.toJson<String>(currencyCode),
      'status_value': serializer.toJson<int>(statusValue),
      'category_id': serializer.toJson<int?>(categoryId),
      'revision': serializer.toJson<int>(revision),
    };
  }

  CatalogItem copyWith({
    int? id,
    String? title,
    String? description,
    int? priceMinorUnits,
    String? currencyCode,
    int? statusValue,
    Value<int?> categoryId = const Value.absent(),
    int? revision,
  }) => CatalogItem(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description ?? this.description,
    priceMinorUnits: priceMinorUnits ?? this.priceMinorUnits,
    currencyCode: currencyCode ?? this.currencyCode,
    statusValue: statusValue ?? this.statusValue,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    revision: revision ?? this.revision,
  );
  CatalogItem copyWithCompanion(CatalogItemsCompanion data) {
    return CatalogItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      priceMinorUnits: data.priceMinorUnits.present
          ? data.priceMinorUnits.value
          : this.priceMinorUnits,
      currencyCode: data.currencyCode.present
          ? data.currencyCode.value
          : this.currencyCode,
      statusValue: data.statusValue.present
          ? data.statusValue.value
          : this.statusValue,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      revision: data.revision.present ? data.revision.value : this.revision,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priceMinorUnits: $priceMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('statusValue: $statusValue, ')
          ..write('categoryId: $categoryId, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    priceMinorUnits,
    currencyCode,
    statusValue,
    categoryId,
    revision,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.priceMinorUnits == this.priceMinorUnits &&
          other.currencyCode == this.currencyCode &&
          other.statusValue == this.statusValue &&
          other.categoryId == this.categoryId &&
          other.revision == this.revision);
}

class CatalogItemsCompanion extends UpdateCompanion<CatalogItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> description;
  final Value<int> priceMinorUnits;
  final Value<String> currencyCode;
  final Value<int> statusValue;
  final Value<int?> categoryId;
  final Value<int> revision;
  const CatalogItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.priceMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.statusValue = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.revision = const Value.absent(),
  });
  CatalogItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.priceMinorUnits = const Value.absent(),
    this.currencyCode = const Value.absent(),
    this.statusValue = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.revision = const Value.absent(),
  }) : title = Value(title);
  static Insertable<CatalogItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? priceMinorUnits,
    Expression<String>? currencyCode,
    Expression<int>? statusValue,
    Expression<int>? categoryId,
    Expression<int>? revision,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (priceMinorUnits != null) 'price_minor_units': priceMinorUnits,
      if (currencyCode != null) 'currency_code': currencyCode,
      if (statusValue != null) 'status_value': statusValue,
      if (categoryId != null) 'category_id': categoryId,
      if (revision != null) 'revision': revision,
    });
  }

  CatalogItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? description,
    Value<int>? priceMinorUnits,
    Value<String>? currencyCode,
    Value<int>? statusValue,
    Value<int?>? categoryId,
    Value<int>? revision,
  }) {
    return CatalogItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priceMinorUnits: priceMinorUnits ?? this.priceMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      statusValue: statusValue ?? this.statusValue,
      categoryId: categoryId ?? this.categoryId,
      revision: revision ?? this.revision,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (priceMinorUnits.present) {
      map['price_minor_units'] = Variable<int>(priceMinorUnits.value);
    }
    if (currencyCode.present) {
      map['currency_code'] = Variable<String>(currencyCode.value);
    }
    if (statusValue.present) {
      map['status_value'] = Variable<int>(statusValue.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (revision.present) {
      map['revision'] = Variable<int>(revision.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('priceMinorUnits: $priceMinorUnits, ')
          ..write('currencyCode: $currencyCode, ')
          ..write('statusValue: $statusValue, ')
          ..write('categoryId: $categoryId, ')
          ..write('revision: $revision')
          ..write(')'))
        .toString();
  }
}

abstract class _$ApplicationDatabase extends GeneratedDatabase {
  _$ApplicationDatabase(QueryExecutor e) : super(e);
  $ApplicationDatabaseManager get managers => $ApplicationDatabaseManager(this);
  late final OrderingOrders orderingOrders = OrderingOrders(this);
  late final OrderingOrderLines orderingOrderLines = OrderingOrderLines(this);
  late final CatalogCategories catalogCategories = CatalogCategories(this);
  late final CatalogItems catalogItems = CatalogItems(this);
  late final CatalogCategoriesDao catalogCategoriesDao = CatalogCategoriesDao(
    this as ApplicationDatabase,
  );
  late final CatalogItemsDao catalogItemsDao = CatalogItemsDao(
    this as ApplicationDatabase,
  );
  late final OrderingOrdersDao orderingOrdersDao = OrderingOrdersDao(
    this as ApplicationDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    orderingOrders,
    orderingOrderLines,
    catalogCategories,
    catalogItems,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ordering_orders',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ordering_order_lines', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $OrderingOrdersCreateCompanionBuilder =
    OrderingOrdersCompanion Function({
      Value<int> id,
      Value<int> statusValue,
      Value<int?> totalMinorUnits,
      Value<String?> currencyCode,
      Value<int> revision,
      required int createdAtUtcMilliseconds,
      Value<int?> placedAtUtcMilliseconds,
      Value<int?> cancelledAtUtcMilliseconds,
    });
typedef $OrderingOrdersUpdateCompanionBuilder =
    OrderingOrdersCompanion Function({
      Value<int> id,
      Value<int> statusValue,
      Value<int?> totalMinorUnits,
      Value<String?> currencyCode,
      Value<int> revision,
      Value<int> createdAtUtcMilliseconds,
      Value<int?> placedAtUtcMilliseconds,
      Value<int?> cancelledAtUtcMilliseconds,
    });

final class $OrderingOrdersReferences
    extends
        BaseReferences<_$ApplicationDatabase, OrderingOrders, OrderingOrder> {
  $OrderingOrdersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<OrderingOrderLines, List<OrderingOrderLine>>
  _orderingOrderLinesRefsTable(_$ApplicationDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.orderingOrderLines,
        aliasName: 'ordering_orders__id__ordering_order_lines__order_id',
      );

  $OrderingOrderLinesProcessedTableManager get orderingOrderLinesRefs {
    final manager = $OrderingOrderLinesTableManager(
      $_db,
      $_db.orderingOrderLines,
    ).filter((f) => f.orderId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _orderingOrderLinesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $OrderingOrdersFilterComposer
    extends Composer<_$ApplicationDatabase, OrderingOrders> {
  $OrderingOrdersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusValue => $composableBuilder(
    column: $table.statusValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMilliseconds => $composableBuilder(
    column: $table.createdAtUtcMilliseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placedAtUtcMilliseconds => $composableBuilder(
    column: $table.placedAtUtcMilliseconds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cancelledAtUtcMilliseconds => $composableBuilder(
    column: $table.cancelledAtUtcMilliseconds,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> orderingOrderLinesRefs(
    Expression<bool> Function($OrderingOrderLinesFilterComposer f) f,
  ) {
    final $OrderingOrderLinesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderingOrderLines,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OrderingOrderLinesFilterComposer(
            $db: $db,
            $table: $db.orderingOrderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $OrderingOrdersOrderingComposer
    extends Composer<_$ApplicationDatabase, OrderingOrders> {
  $OrderingOrdersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusValue => $composableBuilder(
    column: $table.statusValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMilliseconds => $composableBuilder(
    column: $table.createdAtUtcMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placedAtUtcMilliseconds => $composableBuilder(
    column: $table.placedAtUtcMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cancelledAtUtcMilliseconds => $composableBuilder(
    column: $table.cancelledAtUtcMilliseconds,
    builder: (column) => ColumnOrderings(column),
  );
}

class $OrderingOrdersAnnotationComposer
    extends Composer<_$ApplicationDatabase, OrderingOrders> {
  $OrderingOrdersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get statusValue => $composableBuilder(
    column: $table.statusValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalMinorUnits => $composableBuilder(
    column: $table.totalMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMilliseconds => $composableBuilder(
    column: $table.createdAtUtcMilliseconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get placedAtUtcMilliseconds => $composableBuilder(
    column: $table.placedAtUtcMilliseconds,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cancelledAtUtcMilliseconds => $composableBuilder(
    column: $table.cancelledAtUtcMilliseconds,
    builder: (column) => column,
  );

  Expression<T> orderingOrderLinesRefs<T extends Object>(
    Expression<T> Function($OrderingOrderLinesAnnotationComposer a) f,
  ) {
    final $OrderingOrderLinesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.orderingOrderLines,
      getReferencedColumn: (t) => t.orderId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OrderingOrderLinesAnnotationComposer(
            $db: $db,
            $table: $db.orderingOrderLines,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $OrderingOrdersTableManager
    extends
        RootTableManager<
          _$ApplicationDatabase,
          OrderingOrders,
          OrderingOrder,
          $OrderingOrdersFilterComposer,
          $OrderingOrdersOrderingComposer,
          $OrderingOrdersAnnotationComposer,
          $OrderingOrdersCreateCompanionBuilder,
          $OrderingOrdersUpdateCompanionBuilder,
          (OrderingOrder, $OrderingOrdersReferences),
          OrderingOrder,
          PrefetchHooks Function({bool orderingOrderLinesRefs})
        > {
  $OrderingOrdersTableManager(_$ApplicationDatabase db, OrderingOrders table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OrderingOrdersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OrderingOrdersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OrderingOrdersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> statusValue = const Value.absent(),
                Value<int?> totalMinorUnits = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<int> revision = const Value.absent(),
                Value<int> createdAtUtcMilliseconds = const Value.absent(),
                Value<int?> placedAtUtcMilliseconds = const Value.absent(),
                Value<int?> cancelledAtUtcMilliseconds = const Value.absent(),
              }) => OrderingOrdersCompanion(
                id: id,
                statusValue: statusValue,
                totalMinorUnits: totalMinorUnits,
                currencyCode: currencyCode,
                revision: revision,
                createdAtUtcMilliseconds: createdAtUtcMilliseconds,
                placedAtUtcMilliseconds: placedAtUtcMilliseconds,
                cancelledAtUtcMilliseconds: cancelledAtUtcMilliseconds,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> statusValue = const Value.absent(),
                Value<int?> totalMinorUnits = const Value.absent(),
                Value<String?> currencyCode = const Value.absent(),
                Value<int> revision = const Value.absent(),
                required int createdAtUtcMilliseconds,
                Value<int?> placedAtUtcMilliseconds = const Value.absent(),
                Value<int?> cancelledAtUtcMilliseconds = const Value.absent(),
              }) => OrderingOrdersCompanion.insert(
                id: id,
                statusValue: statusValue,
                totalMinorUnits: totalMinorUnits,
                currencyCode: currencyCode,
                revision: revision,
                createdAtUtcMilliseconds: createdAtUtcMilliseconds,
                placedAtUtcMilliseconds: placedAtUtcMilliseconds,
                cancelledAtUtcMilliseconds: cancelledAtUtcMilliseconds,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $OrderingOrdersReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderingOrderLinesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (orderingOrderLinesRefs) db.orderingOrderLines,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (orderingOrderLinesRefs)
                    await $_getPrefetchedData<
                      OrderingOrder,
                      OrderingOrders,
                      OrderingOrderLine
                    >(
                      currentTable: table,
                      referencedTable: $OrderingOrdersReferences
                          ._orderingOrderLinesRefsTable(db),
                      managerFromTypedResult: (p0) => $OrderingOrdersReferences(
                        db,
                        table,
                        p0,
                      ).orderingOrderLinesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.orderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $OrderingOrdersProcessedTableManager =
    ProcessedTableManager<
      _$ApplicationDatabase,
      OrderingOrders,
      OrderingOrder,
      $OrderingOrdersFilterComposer,
      $OrderingOrdersOrderingComposer,
      $OrderingOrdersAnnotationComposer,
      $OrderingOrdersCreateCompanionBuilder,
      $OrderingOrdersUpdateCompanionBuilder,
      (OrderingOrder, $OrderingOrdersReferences),
      OrderingOrder,
      PrefetchHooks Function({bool orderingOrderLinesRefs})
    >;
typedef $OrderingOrderLinesCreateCompanionBuilder =
    OrderingOrderLinesCompanion Function({
      required int orderId,
      required int catalogProductId,
      required String productTitleSnapshot,
      required int unitPriceMinorUnits,
      required String currencyCode,
      required int quantity,
      required int catalogRevision,
      Value<int> rowid,
    });
typedef $OrderingOrderLinesUpdateCompanionBuilder =
    OrderingOrderLinesCompanion Function({
      Value<int> orderId,
      Value<int> catalogProductId,
      Value<String> productTitleSnapshot,
      Value<int> unitPriceMinorUnits,
      Value<String> currencyCode,
      Value<int> quantity,
      Value<int> catalogRevision,
      Value<int> rowid,
    });

final class $OrderingOrderLinesReferences
    extends
        BaseReferences<
          _$ApplicationDatabase,
          OrderingOrderLines,
          OrderingOrderLine
        > {
  $OrderingOrderLinesReferences(super.$_db, super.$_table, super.$_typedResult);

  static OrderingOrders _orderIdTable(_$ApplicationDatabase db) => db
      .orderingOrders
      .createAlias('ordering_order_lines__order_id__ordering_orders__id');

  $OrderingOrdersProcessedTableManager get orderId {
    final $_column = $_itemColumn<int>('order_id')!;

    final manager = $OrderingOrdersTableManager(
      $_db,
      $_db.orderingOrders,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_orderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $OrderingOrderLinesFilterComposer
    extends Composer<_$ApplicationDatabase, OrderingOrderLines> {
  $OrderingOrderLinesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get catalogProductId => $composableBuilder(
    column: $table.catalogProductId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get productTitleSnapshot => $composableBuilder(
    column: $table.productTitleSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unitPriceMinorUnits => $composableBuilder(
    column: $table.unitPriceMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get catalogRevision => $composableBuilder(
    column: $table.catalogRevision,
    builder: (column) => ColumnFilters(column),
  );

  $OrderingOrdersFilterComposer get orderId {
    final $OrderingOrdersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orderingOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OrderingOrdersFilterComposer(
            $db: $db,
            $table: $db.orderingOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $OrderingOrderLinesOrderingComposer
    extends Composer<_$ApplicationDatabase, OrderingOrderLines> {
  $OrderingOrderLinesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get catalogProductId => $composableBuilder(
    column: $table.catalogProductId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get productTitleSnapshot => $composableBuilder(
    column: $table.productTitleSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unitPriceMinorUnits => $composableBuilder(
    column: $table.unitPriceMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get catalogRevision => $composableBuilder(
    column: $table.catalogRevision,
    builder: (column) => ColumnOrderings(column),
  );

  $OrderingOrdersOrderingComposer get orderId {
    final $OrderingOrdersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orderingOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OrderingOrdersOrderingComposer(
            $db: $db,
            $table: $db.orderingOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $OrderingOrderLinesAnnotationComposer
    extends Composer<_$ApplicationDatabase, OrderingOrderLines> {
  $OrderingOrderLinesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get catalogProductId => $composableBuilder(
    column: $table.catalogProductId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get productTitleSnapshot => $composableBuilder(
    column: $table.productTitleSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unitPriceMinorUnits => $composableBuilder(
    column: $table.unitPriceMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<int> get catalogRevision => $composableBuilder(
    column: $table.catalogRevision,
    builder: (column) => column,
  );

  $OrderingOrdersAnnotationComposer get orderId {
    final $OrderingOrdersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.orderId,
      referencedTable: $db.orderingOrders,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $OrderingOrdersAnnotationComposer(
            $db: $db,
            $table: $db.orderingOrders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $OrderingOrderLinesTableManager
    extends
        RootTableManager<
          _$ApplicationDatabase,
          OrderingOrderLines,
          OrderingOrderLine,
          $OrderingOrderLinesFilterComposer,
          $OrderingOrderLinesOrderingComposer,
          $OrderingOrderLinesAnnotationComposer,
          $OrderingOrderLinesCreateCompanionBuilder,
          $OrderingOrderLinesUpdateCompanionBuilder,
          (OrderingOrderLine, $OrderingOrderLinesReferences),
          OrderingOrderLine,
          PrefetchHooks Function({bool orderId})
        > {
  $OrderingOrderLinesTableManager(
    _$ApplicationDatabase db,
    OrderingOrderLines table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $OrderingOrderLinesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $OrderingOrderLinesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $OrderingOrderLinesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> orderId = const Value.absent(),
                Value<int> catalogProductId = const Value.absent(),
                Value<String> productTitleSnapshot = const Value.absent(),
                Value<int> unitPriceMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> quantity = const Value.absent(),
                Value<int> catalogRevision = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OrderingOrderLinesCompanion(
                orderId: orderId,
                catalogProductId: catalogProductId,
                productTitleSnapshot: productTitleSnapshot,
                unitPriceMinorUnits: unitPriceMinorUnits,
                currencyCode: currencyCode,
                quantity: quantity,
                catalogRevision: catalogRevision,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required int orderId,
                required int catalogProductId,
                required String productTitleSnapshot,
                required int unitPriceMinorUnits,
                required String currencyCode,
                required int quantity,
                required int catalogRevision,
                Value<int> rowid = const Value.absent(),
              }) => OrderingOrderLinesCompanion.insert(
                orderId: orderId,
                catalogProductId: catalogProductId,
                productTitleSnapshot: productTitleSnapshot,
                unitPriceMinorUnits: unitPriceMinorUnits,
                currencyCode: currencyCode,
                quantity: quantity,
                catalogRevision: catalogRevision,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $OrderingOrderLinesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({orderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (orderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.orderId,
                        referencedTable: $OrderingOrderLinesReferences
                            ._orderIdTable(db),
                        referencedColumn: $OrderingOrderLinesReferences
                            ._orderIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $OrderingOrderLinesProcessedTableManager =
    ProcessedTableManager<
      _$ApplicationDatabase,
      OrderingOrderLines,
      OrderingOrderLine,
      $OrderingOrderLinesFilterComposer,
      $OrderingOrderLinesOrderingComposer,
      $OrderingOrderLinesAnnotationComposer,
      $OrderingOrderLinesCreateCompanionBuilder,
      $OrderingOrderLinesUpdateCompanionBuilder,
      (OrderingOrderLine, $OrderingOrderLinesReferences),
      OrderingOrderLine,
      PrefetchHooks Function({bool orderId})
    >;
typedef $CatalogCategoriesCreateCompanionBuilder =
    CatalogCategoriesCompanion Function({
      Value<int> id,
      required String name,
      Value<bool> isActive,
    });
typedef $CatalogCategoriesUpdateCompanionBuilder =
    CatalogCategoriesCompanion Function({
      Value<int> id,
      Value<String> name,
      Value<bool> isActive,
    });

final class $CatalogCategoriesReferences
    extends
        BaseReferences<
          _$ApplicationDatabase,
          CatalogCategories,
          CatalogCategory
        > {
  $CatalogCategoriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<CatalogItems, List<CatalogItem>>
  _catalogItemsRefsTable(_$ApplicationDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.catalogItems,
        aliasName: 'catalog_categories__id__catalog_items__category_id',
      );

  $CatalogItemsProcessedTableManager get catalogItemsRefs {
    final manager = $CatalogItemsTableManager(
      $_db,
      $_db.catalogItems,
    ).filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_catalogItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CatalogCategoriesFilterComposer
    extends Composer<_$ApplicationDatabase, CatalogCategories> {
  $CatalogCategoriesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> catalogItemsRefs(
    Expression<bool> Function($CatalogItemsFilterComposer f) f,
  ) {
    final $CatalogItemsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catalogItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatalogItemsFilterComposer(
            $db: $db,
            $table: $db.catalogItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatalogCategoriesOrderingComposer
    extends Composer<_$ApplicationDatabase, CatalogCategories> {
  $CatalogCategoriesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CatalogCategoriesAnnotationComposer
    extends Composer<_$ApplicationDatabase, CatalogCategories> {
  $CatalogCategoriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  Expression<T> catalogItemsRefs<T extends Object>(
    Expression<T> Function($CatalogItemsAnnotationComposer a) f,
  ) {
    final $CatalogItemsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.catalogItems,
      getReferencedColumn: (t) => t.categoryId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatalogItemsAnnotationComposer(
            $db: $db,
            $table: $db.catalogItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CatalogCategoriesTableManager
    extends
        RootTableManager<
          _$ApplicationDatabase,
          CatalogCategories,
          CatalogCategory,
          $CatalogCategoriesFilterComposer,
          $CatalogCategoriesOrderingComposer,
          $CatalogCategoriesAnnotationComposer,
          $CatalogCategoriesCreateCompanionBuilder,
          $CatalogCategoriesUpdateCompanionBuilder,
          (CatalogCategory, $CatalogCategoriesReferences),
          CatalogCategory,
          PrefetchHooks Function({bool catalogItemsRefs})
        > {
  $CatalogCategoriesTableManager(
    _$ApplicationDatabase db,
    CatalogCategories table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatalogCategoriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatalogCategoriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatalogCategoriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
              }) => CatalogCategoriesCompanion(
                id: id,
                name: name,
                isActive: isActive,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<bool> isActive = const Value.absent(),
              }) => CatalogCategoriesCompanion.insert(
                id: id,
                name: name,
                isActive: isActive,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CatalogCategoriesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({catalogItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (catalogItemsRefs) db.catalogItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (catalogItemsRefs)
                    await $_getPrefetchedData<
                      CatalogCategory,
                      CatalogCategories,
                      CatalogItem
                    >(
                      currentTable: table,
                      referencedTable: $CatalogCategoriesReferences
                          ._catalogItemsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $CatalogCategoriesReferences(
                            db,
                            table,
                            p0,
                          ).catalogItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.categoryId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $CatalogCategoriesProcessedTableManager =
    ProcessedTableManager<
      _$ApplicationDatabase,
      CatalogCategories,
      CatalogCategory,
      $CatalogCategoriesFilterComposer,
      $CatalogCategoriesOrderingComposer,
      $CatalogCategoriesAnnotationComposer,
      $CatalogCategoriesCreateCompanionBuilder,
      $CatalogCategoriesUpdateCompanionBuilder,
      (CatalogCategory, $CatalogCategoriesReferences),
      CatalogCategory,
      PrefetchHooks Function({bool catalogItemsRefs})
    >;
typedef $CatalogItemsCreateCompanionBuilder = CatalogItemsCompanion Function({
  Value<int> id,
  required String title,
  Value<String> description,
  Value<int> priceMinorUnits,
  Value<String> currencyCode,
  Value<int> statusValue,
  Value<int?> categoryId,
  Value<int> revision,
});
typedef $CatalogItemsUpdateCompanionBuilder = CatalogItemsCompanion Function({
  Value<int> id,
  Value<String> title,
  Value<String> description,
  Value<int> priceMinorUnits,
  Value<String> currencyCode,
  Value<int> statusValue,
  Value<int?> categoryId,
  Value<int> revision,
});

final class $CatalogItemsReferences
    extends BaseReferences<_$ApplicationDatabase, CatalogItems, CatalogItem> {
  $CatalogItemsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CatalogCategories _categoryIdTable(_$ApplicationDatabase db) => db
      .catalogCategories
      .createAlias('catalog_items__category_id__catalog_categories__id');

  $CatalogCategoriesProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $CatalogCategoriesTableManager(
      $_db,
      $_db.catalogCategories,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CatalogItemsFilterComposer
    extends Composer<_$ApplicationDatabase, CatalogItems> {
  $CatalogItemsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priceMinorUnits => $composableBuilder(
    column: $table.priceMinorUnits,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get statusValue => $composableBuilder(
    column: $table.statusValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnFilters(column),
  );

  $CatalogCategoriesFilterComposer get categoryId {
    final $CatalogCategoriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.catalogCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatalogCategoriesFilterComposer(
            $db: $db,
            $table: $db.catalogCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CatalogItemsOrderingComposer
    extends Composer<_$ApplicationDatabase, CatalogItems> {
  $CatalogItemsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priceMinorUnits => $composableBuilder(
    column: $table.priceMinorUnits,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get statusValue => $composableBuilder(
    column: $table.statusValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get revision => $composableBuilder(
    column: $table.revision,
    builder: (column) => ColumnOrderings(column),
  );

  $CatalogCategoriesOrderingComposer get categoryId {
    final $CatalogCategoriesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.catalogCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatalogCategoriesOrderingComposer(
            $db: $db,
            $table: $db.catalogCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CatalogItemsAnnotationComposer
    extends Composer<_$ApplicationDatabase, CatalogItems> {
  $CatalogItemsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get priceMinorUnits => $composableBuilder(
    column: $table.priceMinorUnits,
    builder: (column) => column,
  );

  GeneratedColumn<String> get currencyCode => $composableBuilder(
    column: $table.currencyCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get statusValue => $composableBuilder(
    column: $table.statusValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get revision =>
      $composableBuilder(column: $table.revision, builder: (column) => column);

  $CatalogCategoriesAnnotationComposer get categoryId {
    final $CatalogCategoriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: $db.catalogCategories,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CatalogCategoriesAnnotationComposer(
            $db: $db,
            $table: $db.catalogCategories,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CatalogItemsTableManager
    extends
        RootTableManager<
          _$ApplicationDatabase,
          CatalogItems,
          CatalogItem,
          $CatalogItemsFilterComposer,
          $CatalogItemsOrderingComposer,
          $CatalogItemsAnnotationComposer,
          $CatalogItemsCreateCompanionBuilder,
          $CatalogItemsUpdateCompanionBuilder,
          (CatalogItem, $CatalogItemsReferences),
          CatalogItem,
          PrefetchHooks Function({bool categoryId})
        > {
  $CatalogItemsTableManager(_$ApplicationDatabase db, CatalogItems table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CatalogItemsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CatalogItemsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CatalogItemsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<int> priceMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> statusValue = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> revision = const Value.absent(),
              }) => CatalogItemsCompanion(
                id: id,
                title: title,
                description: description,
                priceMinorUnits: priceMinorUnits,
                currencyCode: currencyCode,
                statusValue: statusValue,
                categoryId: categoryId,
                revision: revision,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String> description = const Value.absent(),
                Value<int> priceMinorUnits = const Value.absent(),
                Value<String> currencyCode = const Value.absent(),
                Value<int> statusValue = const Value.absent(),
                Value<int?> categoryId = const Value.absent(),
                Value<int> revision = const Value.absent(),
              }) => CatalogItemsCompanion.insert(
                id: id,
                title: title,
                description: description,
                priceMinorUnits: priceMinorUnits,
                currencyCode: currencyCode,
                statusValue: statusValue,
                categoryId: categoryId,
                revision: revision,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $CatalogItemsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (categoryId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.categoryId,
                        referencedTable: $CatalogItemsReferences
                            ._categoryIdTable(db),
                        referencedColumn: $CatalogItemsReferences
                            ._categoryIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CatalogItemsProcessedTableManager =
    ProcessedTableManager<
      _$ApplicationDatabase,
      CatalogItems,
      CatalogItem,
      $CatalogItemsFilterComposer,
      $CatalogItemsOrderingComposer,
      $CatalogItemsAnnotationComposer,
      $CatalogItemsCreateCompanionBuilder,
      $CatalogItemsUpdateCompanionBuilder,
      (CatalogItem, $CatalogItemsReferences),
      CatalogItem,
      PrefetchHooks Function({bool categoryId})
    >;

class $ApplicationDatabaseManager {
  final _$ApplicationDatabase _db;
  $ApplicationDatabaseManager(this._db);
  $OrderingOrdersTableManager get orderingOrders =>
      $OrderingOrdersTableManager(_db, _db.orderingOrders);
  $OrderingOrderLinesTableManager get orderingOrderLines =>
      $OrderingOrderLinesTableManager(_db, _db.orderingOrderLines);
  $CatalogCategoriesTableManager get catalogCategories =>
      $CatalogCategoriesTableManager(_db, _db.catalogCategories);
  $CatalogItemsTableManager get catalogItems =>
      $CatalogItemsTableManager(_db, _db.catalogItems);
}
