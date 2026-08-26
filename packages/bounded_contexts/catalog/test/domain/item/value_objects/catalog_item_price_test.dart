import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes currency and compares by amount and currency', () {
    final first = CatalogItemPrice.fromUserInput(
      minorUnits: 1250,
      currencyCode: ' usd ',
    );
    final second = CatalogItemPrice.fromStored(
      minorUnits: 1250,
      currencyCode: 'USD',
    );

    expect(first, second);
    expect(first.isPublishable, isTrue);
  });

  test('rejects negative, unsafe, and invalid currency input', () {
    for (final values in <(int, String)>[
      (-1, 'USD'),
      (CatalogItemPrice.maxSafeMinorUnits + 1, 'USD'),
      (1, 'US'),
    ]) {
      expect(
        () => CatalogItemPrice.fromUserInput(
          minorUnits: values.$1,
          currencyCode: values.$2,
        ),
        throwsA(isA<CatalogInvalidPriceException>()),
      );
    }
  });

  test('keeps XXX only as an unpublished draft placeholder', () {
    final placeholder = CatalogItemPrice.fromStored(
      minorUnits: 0,
      currencyCode: 'XXX',
    );

    expect(placeholder.isPublishable, isFalse);
    expect(
      () => CatalogItemPrice.fromStored(
        minorUnits: 1,
        currencyCode: 'usd',
      ),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
