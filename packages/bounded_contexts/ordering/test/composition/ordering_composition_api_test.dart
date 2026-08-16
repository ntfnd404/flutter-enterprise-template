import 'package:ordering/ordering.dart';
import 'package:ordering/ordering_composition.dart';
import 'package:test/test.dart';

void main() {
  test(
    'Product Offer port is implementable through public entrypoints',
    () async {
      final ProductOfferProvider provider = _StubProductOfferProvider();
      final product = CatalogProductReference.fromInput(1);

      final offers = await provider.loadOffers(<CatalogProductReference>{
        product,
      });

      expect(offers.keys, <CatalogProductReference>{product});
      expect(offers[product]!.product, product);
    },
  );
}

final class _StubProductOfferProvider implements ProductOfferProvider {
  @override
  Future<Map<CatalogProductReference, OrderProductOffer>> loadOffers(
    Set<CatalogProductReference> products,
  ) async => <CatalogProductReference, OrderProductOffer>{
    for (final product in products)
      product: OrderProductOffer(
        product: product,
        title: OrderProductTitle.fromExternal('Product'),
        unitPrice: OrderUnitPrice.fromExternal(100),
        currency: OrderCurrency.fromExternal('USD'),
        catalogRevision: CatalogOfferRevision.fromExternal(1),
      ),
  };
}
