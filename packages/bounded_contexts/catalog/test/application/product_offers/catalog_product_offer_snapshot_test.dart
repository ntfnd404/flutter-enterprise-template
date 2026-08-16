import 'package:catalog/catalog_product_offers.dart';
import 'package:test/test.dart';

void main() {
  test('published offer snapshots have structural value equality', () {
    const first = CatalogProductOfferSnapshot(
      productId: 1,
      title: 'Product',
      priceMinorUnits: 2500,
      currencyCode: 'USD',
      catalogRevision: 3,
    );
    const equal = CatalogProductOfferSnapshot(
      productId: 1,
      title: 'Product',
      priceMinorUnits: 2500,
      currencyCode: 'USD',
      catalogRevision: 3,
    );
    const newer = CatalogProductOfferSnapshot(
      productId: 1,
      title: 'Product',
      priceMinorUnits: 2500,
      currencyCode: 'USD',
      catalogRevision: 4,
    );

    expect(first, equal);
    expect(first.hashCode, equal.hashCode);
    expect(first, isNot(newer));
  });
}
