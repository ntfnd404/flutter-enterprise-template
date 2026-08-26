import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('allows an empty draft description and normalizes input', () {
    expect(CatalogItemDescription.fromUserInput('   ').isEmpty, isTrue);
    expect(
      CatalogItemDescription.fromUserInput('  Details  ').value,
      'Details',
    );
  });

  test('counts graphemes and strictly rehydrates persisted values', () {
    const family = '👨‍👩‍👦';
    final accepted = List<String>.filled(
      CatalogItemDescription.maxLength,
      family,
    ).join();
    final rejected = '$accepted$family';

    expect(CatalogItemDescription.fromUserInput(accepted).value, accepted);
    expect(
      () => CatalogItemDescription.fromUserInput(rejected),
      throwsA(isA<CatalogInvalidDescriptionException>()),
    );
    expect(
      () => CatalogItemDescription.fromStored(' padded '),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
