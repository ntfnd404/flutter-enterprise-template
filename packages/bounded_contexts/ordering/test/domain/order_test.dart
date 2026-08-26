import 'package:ordering/ordering.dart';
import 'package:test/test.dart';

void main() {
  test('empty draft has no money and can receive up to 100 lines', () {
    final draft = _draft();
    expect(draft.lines, isEmpty);
    expect(draft.money, isNull);

    final lines = List<OrderLine>.generate(
      Order.maxLineCount,
      (index) => _line(productId: index + 1),
    );
    final replaced = draft.replaceDraftLines(lines);
    expect(replaced.lines, hasLength(100));
    expect(replaced.money!.minorUnits, 10000);
    expect(replaced.revision.value, 1);
    expect(
      () =>
          draft.replaceDraftLines(<OrderLine>[...lines, _line(productId: 101)]),
      throwsA(isA<OrderingTooManyLinesException>()),
    );
  });

  test('rejects duplicate products, mixed currency, and checked overflow', () {
    final draft = _draft();
    expect(
      () => draft.replaceDraftLines(<OrderLine>[
        _line(productId: 1),
        _line(productId: 1),
      ]),
      throwsA(isA<OrderingDuplicateProductException>()),
    );
    expect(
      () => draft.replaceDraftLines(<OrderLine>[
        _line(productId: 1),
        _line(productId: 2, currency: 'EUR'),
      ]),
      throwsA(isA<OrderingMixedCurrencyException>()),
    );
    expect(
      () => draft.replaceDraftLines(<OrderLine>[
        _line(
          productId: 1,
          price: OrderUnitPrice.maxMinorUnits,
          quantity: 2,
        ),
      ]),
      throwsA(isA<OrderingMoneyOverflowException>()),
    );
  });

  test('places refreshed snapshots and makes cancellation terminal', () {
    final current = _draft().replaceDraftLines(<OrderLine>[
      _line(productId: 1, title: 'Old'),
    ]);
    final placed = current.placeWithRefreshedLines(
      refreshedLines: <OrderLine>[
        _line(productId: 1, title: 'New', price: 250, catalogRevision: 7),
      ],
      placedAt: DateTime.parse('2026-01-02T03:04:05+03:00'),
    );
    expect(placed.status, OrderStatus.placed);
    expect(placed.lines.single.title.value, 'New');
    expect(placed.money!.minorUnits, 250);
    expect(placed.placedAt!.isUtc, isTrue);

    final cancelled = placed.cancel(DateTime.parse('2026-01-03T00:00:00Z'));
    expect(cancelled.status, OrderStatus.cancelled);
    expect(
      () => cancelled.cancel(DateTime.now()),
      throwsA(
        isA<OrderingTransitionException>().having(
          (error) => error.failure,
          'failure',
          OrderingTransitionFailure.orderAlreadyCancelled,
        ),
      ),
    );
  });

  test('strict rehydration rejects inconsistent persisted money and state', () {
    expect(
      () => Order.fromStored(
        id: 1,
        lines: <OrderLine>[_line(productId: 1)],
        totalMinorUnits: 99,
        currencyCode: 'USD',
        statusValue: 0,
        revision: 0,
        createdAtUtcMilliseconds: 0,
        placedAtUtcMilliseconds: null,
        cancelledAtUtcMilliseconds: null,
      ),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
    expect(
      () => Order.fromStored(
        id: 1,
        lines: const <OrderLine>[],
        totalMinorUnits: null,
        currencyCode: null,
        statusValue: 1,
        revision: 0,
        createdAtUtcMilliseconds: 0,
        placedAtUtcMilliseconds: 1,
        cancelledAtUtcMilliseconds: null,
      ),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
    final oversizedLines = List<OrderLine>.generate(
      Order.maxLineCount + 1,
      (index) => _line(productId: index + 1),
    );
    expect(
      () => Order.fromStored(
        id: 1,
        lines: oversizedLines,
        totalMinorUnits: oversizedLines.length * 100,
        currencyCode: 'USD',
        statusValue: 0,
        revision: 0,
        createdAtUtcMilliseconds: 0,
        placedAtUtcMilliseconds: null,
        cancelledAtUtcMilliseconds: null,
      ),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
  });

  test('entity equality uses only Order identity', () {
    final left = _draft();
    final right = _draft().replaceDraftLines(<OrderLine>[_line(productId: 1)]);
    expect(left, right);
    expect(left.hashCode, right.hashCode);
  });
}

Order _draft() => Order.fromStored(
  id: 1,
  lines: const <OrderLine>[],
  totalMinorUnits: null,
  currencyCode: null,
  statusValue: 0,
  revision: 0,
  createdAtUtcMilliseconds: 1700000000000,
  placedAtUtcMilliseconds: null,
  cancelledAtUtcMilliseconds: null,
);

OrderLine _line({
  required int productId,
  String title = 'Product',
  int price = 100,
  int quantity = 1,
  String currency = 'USD',
  int catalogRevision = 0,
}) => OrderLine.fromOffer(
  product: CatalogProductReference.fromExternal(productId),
  title: OrderProductTitle.fromExternal(title),
  unitPrice: OrderUnitPrice.fromExternal(price),
  currency: OrderCurrency.fromExternal(currency),
  quantity: OrderLineQuantity.fromInput(quantity),
  catalogRevision: CatalogOfferRevision.fromExternal(catalogRevision),
);
