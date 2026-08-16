import 'dart:async';

import 'package:ordering/ordering.dart';
import 'package:ordering/src/application/ordering_service.dart';
import 'package:ordering/src/application/product_offers/order_product_offer.dart';
import 'package:ordering/src/application/product_offers/product_offer_provider.dart';
import 'package:ordering/src/domain/order/policies/order_placement_policy.dart';
import 'package:ordering/src/domain/repository/order_repository.dart';
import 'package:test/test.dart';

void main() {
  late _MemoryOrderRepository repository;
  late _RecordingOfferProvider offers;
  late OrderingService service;
  final now = DateTime.parse('2026-02-03T04:05:06+03:00');

  setUp(() {
    repository = _MemoryOrderRepository();
    offers = _RecordingOfferProvider();
    service = OrderingService(
      repository: repository,
      offers: offers,
      utcNow: () => now,
      placementPolicy: const OrderPlacementPolicy(),
    );
  });

  test(
    'empty replacement avoids Catalog and persists nullable money',
    () async {
      await service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[],
      );

      expect(offers.calls, 0);
      expect(repository.order.lines, isEmpty);
      expect(repository.order.money, isNull);
      expect(repository.order.revision.value, 1);
    },
  );

  test('replacement validates duplicates before querying Catalog', () async {
    await expectLater(
      service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[
          OrderLineInput(productId: 1, quantity: 1),
          OrderLineInput(productId: 1, quantity: 2),
        ],
      ),
      throwsA(isA<OrderingDuplicateProductException>()),
    );
    expect(offers.calls, 0);
  });

  test('replacement snapshots mutable input before its first await', () async {
    final loaded = Completer<Order>();
    repository.pendingGet = loaded;
    offers.values = <int, _OfferValue>{
      1: const _OfferValue(title: 'Original', price: 100, revision: 1),
      2: const _OfferValue(title: 'Mutation', price: 200, revision: 1),
    };
    final inputs = <OrderLineInput>[
      const OrderLineInput(productId: 1, quantity: 1),
    ];

    final replacement = service.replaceDraftLines(
      orderId: repository.order.id,
      lines: inputs,
    );
    inputs
      ..clear()
      ..add(const OrderLineInput(productId: 2, quantity: 1));
    loaded.complete(repository.order);
    await replacement;

    expect(offers.lastIds, <int>{1});
    expect(repository.order.lines.single.product.value, 1);
  });

  test('non-draft commands fail before querying Catalog', () async {
    repository.order = _placedOrder();

    await expectLater(
      service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[
          OrderLineInput(productId: 1, quantity: 1),
        ],
      ),
      throwsA(
        isA<OrderingTransitionException>().having(
          (error) => error.failure,
          'failure',
          OrderingTransitionFailure.orderNotDraft,
        ),
      ),
    );
    await expectLater(
      service.placeOrder(repository.order.id),
      throwsA(isA<OrderingTransitionException>()),
    );

    expect(offers.calls, 0);
  });

  test('read, draft creation, and draft cancellation avoid Catalog', () async {
    await service.watchOrders().first;
    await service.watchOrder(repository.order.id).first;
    await service.createDraft();
    await service.cancelOrder(repository.order.id);

    expect(offers.calls, 0);
    expect(repository.order.status, OrderStatus.cancelled);
  });

  test('loads one batch and persists Ordering-owned snapshots', () async {
    offers.values = <int, _OfferValue>{
      1: const _OfferValue(title: 'One', price: 200, revision: 3),
      2: const _OfferValue(title: 'Two', price: 100, revision: 4),
    };

    await service.replaceDraftLines(
      orderId: repository.order.id,
      lines: const <OrderLineInput>[
        OrderLineInput(productId: 2, quantity: 2),
        OrderLineInput(productId: 1, quantity: 1),
      ],
    );

    expect(offers.calls, 1);
    expect(offers.lastIds, unorderedEquals(<int>[1, 2]));
    expect(
      repository.order.lines.map((line) => line.product.value),
      orderedEquals(<int>[1, 2]),
    );
    expect(repository.order.money!.minorUnits, 400);
  });

  test('rejects a provider response whose key and offer disagree', () async {
    final requested = CatalogProductReference.fromInput(1);
    offers.resultOverride = <CatalogProductReference, OrderProductOffer>{
      requested: OrderProductOffer(
        product: CatalogProductReference.fromInput(2),
        title: OrderProductTitle.fromExternal('Wrong product'),
        unitPrice: OrderUnitPrice.fromExternal(100),
        currency: OrderCurrency.fromExternal('USD'),
        catalogRevision: CatalogOfferRevision.fromExternal(1),
      ),
    };

    await expectLater(
      service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[
          OrderLineInput(productId: 1, quantity: 1),
        ],
      ),
      throwsA(isA<OrderingDataIntegrityException>()),
    );

    expect(repository.replacementWrites, 0);
  });

  test(
    'placement refreshes offers and completes only after commit',
    () async {
      offers.values = <int, _OfferValue>{
        1: const _OfferValue(title: 'Old', price: 100, revision: 1),
      };
      await service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[
          OrderLineInput(productId: 1, quantity: 2),
        ],
      );
      offers.values = <int, _OfferValue>{
        1: const _OfferValue(title: 'Current', price: 250, revision: 8),
      };
      repository.beforePlace = () {
        offers.values = <int, _OfferValue>{
          1: const _OfferValue(title: 'Later', price: 999, revision: 9),
        };
      };

      await service.placeOrder(repository.order.id);

      expect(repository.order.status, OrderStatus.placed);
      expect(repository.order.lines.single.title.value, 'Current');
      expect(repository.order.lines.single.catalogRevision.value, 8);
      expect(repository.order.money!.minorUnits, 500);
      expect(repository.order.revision.value, 2);
      expect(repository.order.placedAt, now.toUtc());
      expect(repository.placementCommitted, isTrue);
      expect(repository.order.lines.single.title.value, 'Current');
      expect(repository.order.lines.single.unitPrice.minorUnits, 250);
      expect(repository.order.lines.single.catalogRevision.value, 8);
    },
  );

  test('Catalog outage leaves a non-empty replacement unchanged', () async {
    offers.failure = const OrderingCatalogUnavailableException();

    await expectLater(
      service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[
          OrderLineInput(productId: 1, quantity: 1),
        ],
      ),
      throwsA(isA<OrderingCatalogUnavailableException>()),
    );

    expect(offers.calls, 1);
    expect(repository.replacementWrites, 0);
    expect(repository.order.lines, isEmpty);
    expect(repository.order.money, isNull);
    expect(repository.order.revision.value, 0);
  });

  test('placement retries with a new Catalog point-in-time snapshot', () async {
    offers.values = <int, _OfferValue>{
      1: const _OfferValue(title: 'Draft', price: 100, revision: 1),
    };
    await service.replaceDraftLines(
      orderId: repository.order.id,
      lines: const <OrderLineInput>[
        OrderLineInput(productId: 1, quantity: 2),
      ],
    );
    offers.failure = const OrderingCatalogUnavailableException();

    await expectLater(
      service.placeOrder(repository.order.id),
      throwsA(isA<OrderingCatalogUnavailableException>()),
    );

    expect(offers.calls, 2);
    expect(repository.placementWrites, 0);
    expect(repository.order.status, OrderStatus.draft);
    expect(repository.order.lines.single.title.value, 'Draft');
    expect(repository.order.revision.value, 1);

    offers
      ..failure = null
      ..values = <int, _OfferValue>{
        1: const _OfferValue(title: 'Retry', price: 250, revision: 4),
      };
    await service.placeOrder(repository.order.id);

    expect(offers.calls, 3);
    expect(repository.placementWrites, 1);
    expect(repository.order.status, OrderStatus.placed);
    expect(repository.order.lines.single.title.value, 'Retry');
    expect(repository.order.lines.single.unitPrice.minorUnits, 250);
    expect(repository.order.lines.single.catalogRevision.value, 4);
  });

  test(
    'cancellation uses normalized UTC time and preserves placed snapshot',
    () async {
      offers.values = <int, _OfferValue>{
        1: const _OfferValue(title: 'One', price: 100, revision: 1),
      };
      await service.replaceDraftLines(
        orderId: repository.order.id,
        lines: const <OrderLineInput>[
          OrderLineInput(productId: 1, quantity: 1),
        ],
      );
      await service.placeOrder(repository.order.id);

      await service.cancelOrder(repository.order.id);
      expect(repository.order.status, OrderStatus.cancelled);
      expect(repository.order.lines.single.title.value, 'One');
      expect(repository.order.cancelledAt, now.toUtc());
      expect(offers.calls, 2);
    },
  );
}

final class _MemoryOrderRepository implements OrderRepository {
  Order order = Order.fromStored(
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

  bool placementCommitted = false;
  int placementWrites = 0;
  int replacementWrites = 0;
  void Function()? beforePlace;
  Completer<Order>? pendingGet;

  @override
  Future<void> cancelOrder({
    required Order current,
    required Order cancelled,
  }) async {
    order = cancelled;
  }

  @override
  Future<OrderId> createDraft(DateTime createdAt) async => order.id;

  @override
  Future<Order> getOrder(OrderId id) =>
      pendingGet?.future ?? Future<Order>.value(order);

  @override
  Future<void> placeOrder({
    required Order current,
    required Order placed,
  }) async {
    beforePlace?.call();
    placementWrites += 1;
    order = placed;
    placementCommitted = true;
  }

  @override
  Future<void> replaceDraftLines({
    required Order current,
    required Order replacement,
  }) async {
    replacementWrites += 1;
    order = replacement;
  }

  @override
  Stream<Order> watchOrder(OrderId id) => Stream<Order>.value(order);

  @override
  Stream<List<Order>> watchOrders() =>
      Stream<List<Order>>.value(<Order>[order]);
}

Order _placedOrder() => Order.fromStored(
  id: 1,
  lines: <OrderLine>[
    OrderLine.fromStored(
      productId: 1,
      title: 'Product',
      unitPriceMinorUnits: 100,
      currencyCode: 'USD',
      quantity: 1,
      catalogRevision: 1,
    ),
  ],
  totalMinorUnits: 100,
  currencyCode: 'USD',
  statusValue: OrderStatus.placed.value,
  revision: 1,
  createdAtUtcMilliseconds: 1700000000000,
  placedAtUtcMilliseconds: 1700000001000,
  cancelledAtUtcMilliseconds: null,
);

final class _RecordingOfferProvider implements ProductOfferProvider {
  int calls = 0;
  Set<int> lastIds = <int>{};
  Map<int, _OfferValue> values = <int, _OfferValue>{};
  Exception? failure;
  Map<CatalogProductReference, OrderProductOffer>? resultOverride;

  @override
  Future<Map<CatalogProductReference, OrderProductOffer>> loadOffers(
    Set<CatalogProductReference> products,
  ) async {
    calls += 1;
    lastIds = products.map((product) => product.value).toSet();
    if (failure case final failure?) {
      throw failure;
    }
    if (resultOverride case final result?) {
      return result;
    }

    return <CatalogProductReference, OrderProductOffer>{
      for (final product in products)
        if (values[product.value] case final value?)
          product: OrderProductOffer(
            product: product,
            title: OrderProductTitle.fromExternal(value.title),
            unitPrice: OrderUnitPrice.fromExternal(value.price),
            currency: OrderCurrency.fromExternal('USD'),
            catalogRevision: CatalogOfferRevision.fromExternal(value.revision),
          ),
    };
  }
}

final class _OfferValue {
  const _OfferValue({
    required this.title,
    required this.price,
    required this.revision,
  });

  final String title;
  final int price;
  final int revision;
}
