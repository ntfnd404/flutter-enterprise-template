// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_database.dart';

// ignore_for_file: type=lint
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
    $customConstraints:
        'NOT NULL DEFAULT 0 CHECK (price_minor_units BETWEEN 0 AND 9007199254740991)',
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
    $customConstraints:
        'NOT NULL DEFAULT \'XXX\' CHECK (currency_code GLOB \'[A-Z][A-Z][A-Z]\')',
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
  late final CatalogCategories catalogCategories = CatalogCategories(this);
  late final CatalogItems catalogItems = CatalogItems(this);
  late final CatalogCategoriesDao catalogCategoriesDao = CatalogCategoriesDao(
    this as ApplicationDatabase,
  );
  late final CatalogItemsDao catalogItemsDao = CatalogItemsDao(
    this as ApplicationDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    catalogCategories,
    catalogItems,
  ];
}

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
typedef $CatalogItemsCreateCompanionBuilder =
    CatalogItemsCompanion Function({
      Value<int> id,
      required String title,
      Value<String> description,
      Value<int> priceMinorUnits,
      Value<String> currencyCode,
      Value<int> statusValue,
      Value<int?> categoryId,
      Value<int> revision,
    });
typedef $CatalogItemsUpdateCompanionBuilder =
    CatalogItemsCompanion Function({
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
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.categoryId,
                                referencedTable: $CatalogItemsReferences
                                    ._categoryIdTable(db),
                                referencedColumn: $CatalogItemsReferences
                                    ._categoryIdTable(db)
                                    .id,
                              )
                              as T;
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
  $CatalogCategoriesTableManager get catalogCategories =>
      $CatalogCategoriesTableManager(_db, _db.catalogCategories);
  $CatalogItemsTableManager get catalogItems =>
      $CatalogItemsTableManager(_db, _db.catalogItems);
}
