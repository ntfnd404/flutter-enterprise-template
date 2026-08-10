// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application_database.dart';

// ignore_for_file: type=lint
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
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  late final GeneratedColumn<int> isCompleted = GeneratedColumn<int>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_completed IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [id, title, isCompleted];
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
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
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
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_completed'],
      )!,
    );
  }

  @override
  CatalogItems createAlias(String alias) {
    return CatalogItems(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class CatalogItem extends DataClass implements Insertable<CatalogItem> {
  final int id;
  final String title;
  final int isCompleted;
  const CatalogItem({
    required this.id,
    required this.title,
    required this.isCompleted,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['is_completed'] = Variable<int>(isCompleted);
    return map;
  }

  CatalogItemsCompanion toCompanion(bool nullToAbsent) {
    return CatalogItemsCompanion(
      id: Value(id),
      title: Value(title),
      isCompleted: Value(isCompleted),
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
      isCompleted: serializer.fromJson<int>(json['is_completed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'is_completed': serializer.toJson<int>(isCompleted),
    };
  }

  CatalogItem copyWith({int? id, String? title, int? isCompleted}) =>
      CatalogItem(
        id: id ?? this.id,
        title: title ?? this.title,
        isCompleted: isCompleted ?? this.isCompleted,
      );
  CatalogItem copyWithCompanion(CatalogItemsCompanion data) {
    return CatalogItem(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CatalogItem(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, isCompleted);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CatalogItem &&
          other.id == this.id &&
          other.title == this.title &&
          other.isCompleted == this.isCompleted);
}

class CatalogItemsCompanion extends UpdateCompanion<CatalogItem> {
  final Value<int> id;
  final Value<String> title;
  final Value<int> isCompleted;
  const CatalogItemsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.isCompleted = const Value.absent(),
  });
  CatalogItemsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.isCompleted = const Value.absent(),
  }) : title = Value(title);
  static Insertable<CatalogItem> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<int>? isCompleted,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (isCompleted != null) 'is_completed': isCompleted,
    });
  }

  CatalogItemsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<int>? isCompleted,
  }) {
    return CatalogItemsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
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
    if (isCompleted.present) {
      map['is_completed'] = Variable<int>(isCompleted.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CatalogItemsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('isCompleted: $isCompleted')
          ..write(')'))
        .toString();
  }
}

abstract class _$ApplicationDatabase extends GeneratedDatabase {
  _$ApplicationDatabase(QueryExecutor e) : super(e);
  $ApplicationDatabaseManager get managers => $ApplicationDatabaseManager(this);
  late final CatalogItems catalogItems = CatalogItems(this);
  late final CatalogItemsDao catalogItemsDao = CatalogItemsDao(
    this as ApplicationDatabase,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [catalogItems];
}

typedef $CatalogItemsCreateCompanionBuilder =
    CatalogItemsCompanion Function({
      Value<int> id,
      required String title,
      Value<int> isCompleted,
    });
typedef $CatalogItemsUpdateCompanionBuilder =
    CatalogItemsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<int> isCompleted,
    });

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

  ColumnFilters<int> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );
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

  ColumnOrderings<int> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );
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

  GeneratedColumn<int> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );
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
          (
            CatalogItem,
            BaseReferences<_$ApplicationDatabase, CatalogItems, CatalogItem>,
          ),
          CatalogItem,
          PrefetchHooks Function()
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
                Value<int> isCompleted = const Value.absent(),
              }) => CatalogItemsCompanion(
                id: id,
                title: title,
                isCompleted: isCompleted,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<int> isCompleted = const Value.absent(),
              }) => CatalogItemsCompanion.insert(
                id: id,
                title: title,
                isCompleted: isCompleted,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
      (
        CatalogItem,
        BaseReferences<_$ApplicationDatabase, CatalogItems, CatalogItem>,
      ),
      CatalogItem,
      PrefetchHooks Function()
    >;

class $ApplicationDatabaseManager {
  final _$ApplicationDatabase _db;
  $ApplicationDatabaseManager(this._db);
  $CatalogItemsTableManager get catalogItems =>
      $CatalogItemsTableManager(_db, _db.catalogItems);
}
