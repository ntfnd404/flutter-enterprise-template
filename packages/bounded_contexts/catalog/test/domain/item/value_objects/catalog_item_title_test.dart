import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('normalizes input and uses value equality', () {
    final first = CatalogItemTitle.fromUserInput('  Product  ');
    final second = CatalogItemTitle.fromStored('Product');

    expect(first.value, 'Product');
    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });

  test('applies grapheme limits to input and persisted values', () {
    const family = '👨‍👩‍👦';
    final accepted = List<String>.filled(
      CatalogItemTitle.maxLength,
      family,
    ).join();
    final rejected = '$accepted$family';

    expect(CatalogItemTitle.fromUserInput(accepted).value, accepted);
    expect(
      () => CatalogItemTitle.fromUserInput(rejected),
      throwsA(isA<CatalogInvalidTitleException>()),
    );
    expect(
      () => CatalogItemTitle.fromStored(rejected),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });

  test('does not repair non-canonical persisted titles', () {
    expect(
      () => CatalogItemTitle.fromStored(' padded '),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
