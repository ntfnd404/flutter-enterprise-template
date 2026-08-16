import 'package:ordering/ordering.dart';
import 'package:test/test.dart';

void main() {
  test('scalar Order value objects compare by their validated value', () {
    _expectValueEquality(
      CatalogOfferRevision.fromExternal(7),
      CatalogOfferRevision.fromExternal(7),
      CatalogOfferRevision.fromExternal(8),
    );
    _expectValueEquality(
      OrderLineQuantity.fromInput(2),
      OrderLineQuantity.fromStored(2),
      OrderLineQuantity.fromInput(3),
    );
    _expectValueEquality(
      OrderProductTitle.fromExternal('Product'),
      OrderProductTitle.fromStored('Product'),
      OrderProductTitle.fromExternal('Other'),
    );
    _expectValueEquality(
      OrderUnitPrice.fromExternal(250),
      OrderUnitPrice.fromStored(250),
      OrderUnitPrice.fromExternal(251),
    );
  });

  test('OrderMoney compares by amount and currency', () {
    final dollars = OrderMoney.fromStored(
      minorUnits: 250,
      currencyCode: 'USD',
    );
    final equalDollars = OrderMoney.fromStored(
      minorUnits: 250,
      currencyCode: 'USD',
    );
    final differentAmount = OrderMoney.fromStored(
      minorUnits: 251,
      currencyCode: 'USD',
    );
    final differentCurrency = OrderMoney.fromStored(
      minorUnits: 250,
      currencyCode: 'EUR',
    );

    expect(dollars, equalDollars);
    expect(dollars.hashCode, equalDollars.hashCode);
    expect(dollars, isNot(differentAmount));
    expect(dollars, isNot(differentCurrency));
  });
}

void _expectValueEquality<T>(T value, T equalValue, T differentValue) {
  expect(value, equalValue);
  expect(value.hashCode, equalValue.hashCode);
  expect(value, isNot(differentValue));
}
