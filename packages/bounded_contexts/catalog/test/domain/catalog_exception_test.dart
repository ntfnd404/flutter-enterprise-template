import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('classifies only operational failures as expected', () {
    const expected = <CatalogException>[
      CatalogInvalidTitleException(),
      CatalogInvalidDescriptionException(),
      CatalogInvalidPriceException(),
      CatalogInvalidCategoryNameException(),
      CatalogItemNotFoundException(),
      CatalogCategoryNotFoundException(),
      CatalogItemPublicationException(
        CatalogItemPublicationFailure.descriptionRequired,
      ),
      CatalogItemTransitionException(
        CatalogItemTransitionFailure.concurrentStateChange,
      ),
      CatalogPersistenceException(),
    ];

    for (final error in expected) {
      expect(error, isA<CatalogExpectedException>());
    }
    expect(
      const CatalogDataIntegrityException(),
      isNot(isA<CatalogExpectedException>()),
    );
  });

  test('uses privacy-safe descriptions for every public failure', () {
    const failures = <CatalogException>[
      CatalogInvalidTitleException(),
      CatalogInvalidDescriptionException(),
      CatalogInvalidPriceException(),
      CatalogInvalidCategoryNameException(),
      CatalogItemNotFoundException(),
      CatalogCategoryNotFoundException(),
      CatalogItemPublicationException(
        CatalogItemPublicationFailure.descriptionRequired,
      ),
      CatalogItemTransitionException(
        CatalogItemTransitionFailure.concurrentStateChange,
      ),
      CatalogPersistenceException(),
      CatalogDataIntegrityException(),
    ];

    expect(
      failures.map((failure) => failure.toString()),
      <String>[
        'CatalogInvalidTitleException(invalid title)',
        'CatalogInvalidDescriptionException(invalid description)',
        'CatalogInvalidPriceException(invalid price)',
        'CatalogInvalidCategoryNameException(invalid category name)',
        'CatalogItemNotFoundException(item not found)',
        'CatalogCategoryNotFoundException(category not found)',
        'CatalogItemPublicationException(descriptionRequired)',
        'CatalogItemTransitionException(concurrentStateChange)',
        'CatalogPersistenceException(catalog storage unavailable)',
        'CatalogDataIntegrityException(catalog data violates invariants)',
      ],
    );
  });
}
