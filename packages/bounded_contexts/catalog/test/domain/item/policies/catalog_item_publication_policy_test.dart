import 'package:catalog/catalog.dart';
import 'package:catalog/src/domain/item/policies/catalog_item_publication_policy.dart';
import 'package:test/test.dart';

void main() {
  const policy = CatalogItemPublicationPolicy();

  test('accepts a complete draft in its active category', () {
    final item = _item();
    policy.validatePublication(
      item: item,
      category: _category(),
    );
  });

  test('reports each publication policy rule with a stable reason', () {
    final scenarios =
        <
          ({
            CatalogItem item,
            CatalogCategory? category,
            CatalogItemPublicationFailure failure,
          })
        >[
          (
            item: _item(status: CatalogItemStatus.published),
            category: _category(),
            failure: CatalogItemPublicationFailure.itemNotDraft,
          ),
          (
            item: _item(description: ''),
            category: _category(),
            failure: CatalogItemPublicationFailure.descriptionRequired,
          ),
          (
            item: _item(priceMinorUnits: 0),
            category: _category(),
            failure: CatalogItemPublicationFailure.positivePriceRequired,
          ),
          (
            item: _item(currencyCode: 'XXX'),
            category: _category(),
            failure: CatalogItemPublicationFailure.concreteCurrencyRequired,
          ),
          (
            item: _item(categoryId: null),
            category: null,
            failure: CatalogItemPublicationFailure.categoryRequired,
          ),
          (
            item: _item(),
            category: _category(isActive: false),
            failure: CatalogItemPublicationFailure.activeCategoryRequired,
          ),
          (
            item: _item(),
            category: _category(id: 8),
            failure: CatalogItemPublicationFailure.activeCategoryRequired,
          ),
        ];

    for (final scenario in scenarios) {
      expect(
        () => policy.validatePublication(
          item: scenario.item,
          category: scenario.category,
        ),
        throwsA(
          isA<CatalogItemPublicationException>().having(
            (error) => error.failure,
            'failure',
            scenario.failure,
          ),
        ),
      );
    }
  });
}

CatalogItem _item({
  String description = 'Description',
  int priceMinorUnits = 100,
  String currencyCode = 'USD',
  CatalogItemStatus status = CatalogItemStatus.draft,
  int? categoryId = 7,
}) => CatalogItem.fromValues(
  id: 1,
  title: 'Product',
  description: description,
  priceMinorUnits: priceMinorUnits,
  currencyCode: currencyCode,
  statusValue: status.value,
  categoryId: categoryId,
  revision: 0,
);

CatalogCategory _category({int id = 7, bool isActive = true}) =>
    CatalogCategory.fromValues(
      id: id,
      name: 'Hardware',
      isActive: isActive,
    );
