import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes input and uses value equality', () {
    final first = CatalogCategoryName.fromUserInput('  Hardware  ');
    final second = CatalogCategoryName.fromStored('Hardware');

    expect(first, second);
  });

  test('rejects empty, oversized, and non-canonical values', () {
    final oversized = 'x' * (CatalogCategoryName.maxLength + 1);
    expect(
      () => CatalogCategoryName.fromUserInput('   '),
      throwsA(isA<CatalogInvalidCategoryNameException>()),
    );
    expect(
      () => CatalogCategoryName.fromUserInput(oversized),
      throwsA(isA<CatalogInvalidCategoryNameException>()),
    );
    expect(
      () => CatalogCategoryName.fromStored(' padded '),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
