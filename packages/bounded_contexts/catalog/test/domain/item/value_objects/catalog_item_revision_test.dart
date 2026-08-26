import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('accepts non-negative revisions and compares by value', () {
    expect(
      CatalogItemRevision.fromStored(0),
      CatalogItemRevision.fromStored(0),
    );
    expect(
      CatalogItemRevision.fromStored(CatalogItemRevision.maxValue).value,
      CatalogItemRevision.maxValue,
    );
    expect(CatalogItemRevision.fromStored(0).next().value, 1);
  });

  test('rejects invalid persisted revisions', () {
    for (final value in <int>[-1, CatalogItemRevision.maxValue + 1]) {
      expect(
        () => CatalogItemRevision.fromStored(value),
        throwsA(isA<CatalogDataIntegrityException>()),
      );
    }
    expect(
      CatalogItemRevision.fromStored(CatalogItemRevision.maxValue).next,
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
