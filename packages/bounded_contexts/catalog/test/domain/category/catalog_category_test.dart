import 'package:catalog/catalog.dart';
import 'package:test/test.dart';

void main() {
  test('reconstitutes category and uses identity equality', () {
    final active = CatalogCategory.fromValues(
      id: 1,
      name: 'Hardware',
      isActive: true,
    );
    final inactive = CatalogCategory.fromValues(
      id: 1,
      name: 'Renamed',
      isActive: false,
    );

    expect(active.name.value, 'Hardware');
    expect(active.isActive, isTrue);
    expect(active, inactive);
  });

  test('rejects invalid persisted identity and name', () {
    expect(
      () => CatalogCategory.fromValues(
        id: 0,
        name: 'Hardware',
        isActive: true,
      ),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
    expect(
      () => CatalogCategory.fromValues(
        id: 1,
        name: ' padded ',
        isActive: true,
      ),
      throwsA(isA<CatalogDataIntegrityException>()),
    );
  });
}
