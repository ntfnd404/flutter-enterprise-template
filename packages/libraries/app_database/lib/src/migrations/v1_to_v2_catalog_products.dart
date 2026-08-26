import 'package:app_database/src/application_database.steps.dart';
import 'package:characters/characters.dart';
import 'package:drift/drift.dart';

const _catalogItemsTableName = 'catalog_items';
const _legacyTitleBatchSize = 256;

// This is the immutable compatibility contract of the schema-v2 cutover, not
// a second runtime validator. Catalog remains authoritative after migration.
const _schemaV2CatalogTitleMaxGraphemes = 120;

/// Adds Catalog product fields and categories to the legacy item schema.
Future<void> migrateV1ToV2CatalogProducts(
  Migrator migrator,
  Schema2 schema,
) async {
  final legacySequence = await _readCatalogItemsSequence(
    migrator.database,
    allowMissingAfterRebuild: false,
  );
  await _normalizeLegacyCatalogItemTitles(migrator.database);

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

Future<void> _normalizeLegacyCatalogItemTitles(
  GeneratedDatabase database,
) async {
  var lastId = 0;
  while (true) {
    final rows = await database
        .customSelect(
          'SELECT id, title FROM catalog_items '
          'WHERE id > ? ORDER BY id LIMIT ?',
          variables: <Variable<Object>>[
            Variable<int>(lastId),
            const Variable<int>(_legacyTitleBatchSize),
          ],
        )
        .get();
    if (rows.isEmpty) {
      return;
    }

    for (final row in rows) {
      final id = row.read<int>('id');
      final title = row.read<String>('title');
      final canonicalTitle = title.trim();
      final graphemeLength = canonicalTitle.characters.length;
      if (graphemeLength == 0 ||
          graphemeLength > _schemaV2CatalogTitleMaxGraphemes) {
        throw StateError(
          'Legacy catalog data is incompatible with schema version 2.',
        );
      }
      if (canonicalTitle != title) {
        await database.customStatement(
          'UPDATE catalog_items SET title = ? WHERE id = ?',
          <Object?>[canonicalTitle, id],
        );
      }
      lastId = id;
    }
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
