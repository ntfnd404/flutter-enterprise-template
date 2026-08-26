import 'package:ordering/ordering.dart';
import 'package:test/test.dart';

void main() {
  test('separates expected operational and integrity failures', () {
    const expected = <OrderingException>[
      OrderingInvalidOrderIdException(),
      OrderingInvalidQuantityException(),
      OrderingTooManyLinesException(),
      OrderingDuplicateProductException(),
      OrderingEmptyOrderException(),
      OrderingMixedCurrencyException(),
      OrderingMoneyOverflowException(),
      OrderingProductUnavailableException(),
      OrderingCatalogUnavailableException(),
      OrderingOrderNotFoundException(),
      OrderingTransitionException(OrderingTransitionFailure.orderNotDraft),
      OrderingPersistenceException(),
    ];

    expect(expected, everyElement(isA<OrderingExpectedException>()));
    expect(
      const OrderingDataIntegrityException(),
      isNot(isA<OrderingExpectedException>()),
    );
    expect(
      expected.map<String>((error) => error.toString()),
      everyElement(isNot(contains(RegExp(r'\d{2,}')))),
    );
  });
}
