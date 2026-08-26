// dart format width=80
import 'package:app_database/src/application_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:test/test.dart';

import '../drift/application_database/generated/schema.dart';
import '../drift/application_database/generated/schema_v1.dart' as v1;
import '../drift/application_database/generated/schema_v2.dart' as v2;
import '../drift/application_database/generated/schema_v3.dart' as v3;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('real legacy data traverses the complete v1 to v3 chain', () async {
    await verifier.testWithDataIntegrity(
      oldVersion: 1,
      newVersion: 3,
      createOld: v1.DatabaseAtV1.new,
      createNew: v3.DatabaseAtV3.new,
      openTestedDatabase: ApplicationDatabase.new,
      createItems: (batch, oldDb) {
        batch.insert(
          oldDb.catalogItems,
          const v1.CatalogItemsData(
            id: 5,
            title: '  Legacy product  ',
            isCompleted: 1,
          ),
        );
      },
      validateItems: (newDb) async {
        final item = await newDb
            .customSelect(
              'SELECT id, title, description, price_minor_units, '
              'currency_code, status_value, category_id, revision '
              'FROM catalog_items',
            )
            .getSingle();

        expect(item.read<int>('id'), 5);
        expect(item.read<String>('title'), 'Legacy product');
        expect(item.read<String>('description'), '');
        expect(item.read<int>('price_minor_units'), 0);
        expect(item.read<String>('currency_code'), 'XXX');
        expect(item.read<int>('status_value'), 0);
        expect(item.readNullable<int>('category_id'), isNull);
        expect(item.read<int>('revision'), 0);
        expect(await newDb.select(newDb.orderingOrders).get(), isEmpty);
        expect(await newDb.select(newDb.orderingOrderLines).get(), isEmpty);
      },
    );
  });

  test(
    'v2 Catalog data remains unchanged when Ordering tables are added',
    () async {
      await verifier.testWithDataIntegrity(
        oldVersion: 2,
        newVersion: 3,
        createOld: v2.DatabaseAtV2.new,
        createNew: v3.DatabaseAtV3.new,
        openTestedDatabase: ApplicationDatabase.new,
        createItems: (batch, oldDb) {
          batch.insert(
            oldDb.catalogCategories,
            const v2.CatalogCategoriesData(
              id: 7,
              name: 'Hardware',
              isActive: 1,
            ),
          );
          batch.insert(
            oldDb.catalogItems,
            const v2.CatalogItemsData(
              id: 11,
              title: 'Keyboard',
              description: 'Mechanical keyboard',
              priceMinorUnits: 12999,
              currencyCode: 'USD',
              statusValue: 1,
              categoryId: 7,
              revision: 4,
            ),
          );
        },
        validateItems: (newDb) async {
          final categories = await newDb
              .customSelect(
                'SELECT id, name, is_active FROM catalog_categories',
              )
              .get();
          final items = await newDb
              .customSelect(
                'SELECT id, title, description, price_minor_units, '
                'currency_code, status_value, category_id, revision '
                'FROM catalog_items',
              )
              .get();

          expect(categories, hasLength(1));
          expect(categories.single.read<int>('id'), 7);
          expect(categories.single.read<String>('name'), 'Hardware');
          expect(categories.single.read<int>('is_active'), 1);
          expect(items, hasLength(1));
          expect(items.single.read<int>('id'), 11);
          expect(items.single.read<String>('title'), 'Keyboard');
          expect(
            items.single.read<String>('description'),
            'Mechanical keyboard',
          );
          expect(items.single.read<int>('price_minor_units'), 12999);
          expect(items.single.read<String>('currency_code'), 'USD');
          expect(items.single.read<int>('status_value'), 1);
          expect(items.single.read<int>('category_id'), 7);
          expect(items.single.read<int>('revision'), 4);
          final sequence = await newDb
              .customSelect(
                "SELECT seq FROM sqlite_sequence WHERE name = 'catalog_items'",
              )
              .getSingle();
          expect(sequence.read<int>('seq'), 11);
          expect(await newDb.select(newDb.orderingOrders).get(), isEmpty);
          expect(await newDb.select(newDb.orderingOrderLines).get(), isEmpty);
        },
      );
    },
  );
}
