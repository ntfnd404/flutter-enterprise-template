import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('uses explicit stable values', () {
    expect(CatalogItemStatus.draft.value, 0);
    expect(CatalogItemStatus.published.value, 1);
    expect(CatalogItemStatus.archived.value, 2);
    expect(CatalogItemStatus.fromStored(1), CatalogItemStatus.published);
  });

  test('rejects unknown persisted status', () {
    expect(
      () => CatalogItemStatus.fromStored(3),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
