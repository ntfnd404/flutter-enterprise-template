import 'package:catalog/catalog.dart' show CatalogExpectedException;
import 'package:catalog/catalog_product_offers.dart';
import 'package:test/test.dart';

void main() {
  test('Product Offers request failures are typed and privacy-safe', () {
    const failures = <CatalogOfferRequestException>[
      CatalogOfferRequestException(
        CatalogOfferRequestFailure.invalidProductIdentifier,
      ),
      CatalogOfferRequestException(
        CatalogOfferRequestFailure.batchTooLarge,
      ),
    ];

    expect(
      failures.map((failure) => failure.toString()),
      <String>[
        'CatalogOfferRequestException(invalidProductIdentifier)',
        'CatalogOfferRequestException(batchTooLarge)',
      ],
    );
    expect(
      failures,
      everyElement(isNot(isA<CatalogExpectedException>())),
    );
  });

  test('offer unavailability describes the query, not a missing product', () {
    const failure = CatalogOfferUnavailableException();

    expect(
      failure.toString(),
      'CatalogOfferUnavailableException(catalog offers unavailable)',
    );
    expect(failure, isNot(isA<CatalogExpectedException>()));
  });
}
