import 'package:app_database/src/application_database.steps.dart';
import 'package:drift/drift.dart';

const _catalogItemsTableName = 'catalog_items';

/// Adds Catalog product fields and categories to the legacy item schema.
Future<void> migrateV1ToV2CatalogProducts(
  Migrator migrator,
  Schema2 schema,
) async {
  final legacySequence = await _readCatalogItemsSequence(
    migrator.database,
    allowMissingAfterRebuild: false,
  );

  await migrator.createTable(schema.catalogCategories);
  await migrator.alterTable(
    TableMigration(
      schema.catalogItems,
      newColumns: <GeneratedColumn<Object>>[
        schema.catalogItems.description,
        schema.catalogItems.priceMinorUnits,
        schema.catalogItems.currencyCode,
        schema.catalogItems.statusValue,
        schema.catalogItems.categoryId,
        schema.catalogItems.revision,
      ],
    ),
  );

  if (legacySequence != null) {
    await _restoreCatalogItemsSequence(
      migrator.database,
      legacySequence: legacySequence,
    );
  } else {
    await migrator.database.customStatement(
      'DELETE FROM sqlite_sequence WHERE name = ?',
      const <Object?>[_catalogItemsTableName],
    );
  }
}

Future<int?> _readCatalogItemsSequence(
  GeneratedDatabase database, {
  required bool allowMissingAfterRebuild,
}) async {
  final sequenceRows = await database
      .customSelect(
        'SELECT seq FROM sqlite_sequence WHERE name = ?',
        variables: const <Variable<Object>>[
          Variable<String>(_catalogItemsTableName),
        ],
      )
      .get();
  if (sequenceRows.length > 1) {
    throw StateError(
      'Catalog items AUTOINCREMENT metadata is inconsistent.',
    );
  }

  final maxId = await database
      .customSelect(
        'SELECT MAX(id) AS max_id FROM catalog_items',
      )
      .getSingle()
      .then((row) => row.readNullable<int>('max_id'));
  if (sequenceRows.isEmpty) {
    if (maxId != null && !allowMissingAfterRebuild) {
      throw StateError(
        'Catalog items AUTOINCREMENT metadata is inconsistent.',
      );
    }

    return null;
  }

  final sequence = sequenceRows.single.read<int>('seq');
  if (sequence < 0 || (maxId != null && sequence < maxId)) {
    throw StateError(
      'Catalog items AUTOINCREMENT metadata is inconsistent.',
    );
  }

  return sequence;
}

Future<void> _restoreCatalogItemsSequence(
  GeneratedDatabase database, {
  required int legacySequence,
}) async {
  final currentSequence = await _readCatalogItemsSequence(
    database,
    allowMissingAfterRebuild: true,
  );
  if (currentSequence == null) {
    await database.customStatement(
      'INSERT INTO sqlite_sequence(name, seq) VALUES (?, ?)',
      <Object?>[_catalogItemsTableName, legacySequence],
    );
  } else if (currentSequence < legacySequence) {
    await database.customStatement(
      'UPDATE sqlite_sequence SET seq = ? WHERE name = ?',
      <Object?>[legacySequence, _catalogItemsTableName],
    );
  }
}
