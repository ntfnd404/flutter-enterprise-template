import 'dart:async';

import 'package:app_database/stores/ordering.dart';
import 'package:ordering/ordering.dart';
import 'package:ordering/src/infrastructure/persistence/store_order_repository.dart';
import 'package:test/test.dart';

void main() {
  late _OrdersStore store;
  late StoreOrderRepository repository;

  setUp(() {
    store = _OrdersStore();
    repository = StoreOrderRepository(store);
  });

  test('strictly maps every persisted aggregate field', () async {
    store.order = _storedDraftWithLine();

    final order = await repository.getOrder(OrderId.fromInput(1));

    expect(order.id.value, 1);
    expect(order.status, OrderStatus.draft);
    expect(order.revision.value, 1);
    expect(
      order.createdAt,
      DateTime.fromMillisecondsSinceEpoch(10, isUtc: true),
    );
    expect(order.lines.single.product.value, 2);
    expect(order.lines.single.title.value, 'Product');
    expect(order.lines.single.unitPrice.minorUnits, 50);
    expect(order.lines.single.quantity.value, 2);
    expect(order.lines.single.catalogRevision.value, 7);
    expect(order.money!.minorUnits, 100);
  });

  test('maps missing aggregate and optimistic conflict separately', () async {
    store.order = null;
    await expectLater(
      repository.getOrder(OrderId.fromInput(1)),
      throwsA(isA<OrderingOrderNotFoundException>()),
    );

    store.order = _storedDraftWithLine();
    store.affectedRows = 0;
    final current = await repository.getOrder(OrderId.fromInput(1));
    final replacement = current.replaceDraftLines(const <OrderLine>[]);
    await expectLater(
      repository.replaceDraftLines(
        current: current,
        replacement: replacement,
      ),
      throwsA(
        isA<OrderingTransitionException>().having(
          (error) => error.failure,
          'failure',
          OrderingTransitionFailure.concurrentStateChange,
        ),
      ),
    );
  });

  test('maps store contention with its catch stack', () async {
    final stackTrace = StackTrace.fromString('ordering-store-stack');
    store.failure = const OrderingStoreException();
    store.failureStack = stackTrace;

    try {
      await repository.getOrder(OrderId.fromInput(1));
      fail('Expected OrderingPersistenceException.');
    } on OrderingPersistenceException catch (_, caughtStack) {
      expect(identical(caughtStack, stackTrace), isTrue);
    }
  });

  test('preserves unexpected error identity and stack', () async {
    final error = StateError('unexpected');
    final stackTrace = StackTrace.fromString('unexpected-stack');
    store.failure = error;
    store.failureStack = stackTrace;

    try {
      await repository.getOrder(OrderId.fromInput(1));
      fail('Expected original failure.');
    } on Object catch (caught, caughtStack) {
      expect(caught, same(error));
      expect(identical(caughtStack, stackTrace), isTrue);
    }
  });

  test('rejects corrupt persisted money without masking it', () async {
    store.order = StoredOrder(
      id: 1,
      statusValue: 0,
      totalMinorUnits: 99,
      currencyCode: 'USD',
      revision: 1,
      createdAtUtcMilliseconds: 10,
      placedAtUtcMilliseconds: null,
      cancelledAtUtcMilliseconds: null,
      lines: <StoredOrderLine>[_storedLine()],
    );

    await expectLater(
      repository.getOrder(OrderId.fromInput(1)),
      throwsA(isA<OrderingDataIntegrityException>()),
    );
  });

  test('creates independent watches and propagates cancellation', () async {
    final firstStream = repository.watchOrders();
    final secondStream = repository.watchOrders();
    expect(store.watchOrdersCalls, 0);

    final firstSubscription = firstStream.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(store.watchOrdersCalls, 1);

    await firstSubscription.cancel();
    expect(store.watchOrdersCancellations, 1);

    final secondSubscription = secondStream.listen((_) {});
    await Future<void>.delayed(Duration.zero);
    expect(store.watchOrdersCalls, 2);

    await secondSubscription.cancel();
    expect(store.watchOrdersCancellations, 2);
    expect(store.watchOrdersCalls, 2);
  });

  test('watching a missing Order fails without hidden resubscribe', () async {
    final id = OrderId.fromInput(1);
    final errors = <Object>[];
    final completion = Completer<void>();
    final subscription = repository
        .watchOrder(id)
        .listen(
          (_) => fail('A missing Order must not yield a value.'),
          onError: (Object error, StackTrace _) => errors.add(error),
          onDone: completion.complete,
        );
    addTearDown(subscription.cancel);

    await Future<void>.delayed(Duration.zero);
    expect(store.watchOrderCalls, 1);
    final controller = store.orderControllers.single;
    controller.add(null);
    await completion.future;
    unawaited(controller.close());

    expect(errors, hasLength(1));
    expect(errors.single, isA<OrderingOrderNotFoundException>());
    expect(store.watchOrderCalls, 1);
    expect(store.watchOrderCancellations, 1);
  });

  test(
    'normal completion ends one observation and a new call retries',
    () async {
      final firstDone = Completer<void>();
      final first = repository.watchOrders();
      final firstSubscription = first.listen(
        (_) {},
        onDone: firstDone.complete,
      );
      await Future<void>.delayed(Duration.zero);
      final firstController = store.ordersControllers.single;

      await firstController.close();
      await firstDone.future;
      expect(store.watchOrdersCalls, 1);

      final second = repository.watchOrders();
      final secondSubscription = second.listen((_) {});
      await Future<void>.delayed(Duration.zero);
      expect(store.watchOrdersCalls, 2);
      await secondSubscription.cancel();
      await firstSubscription.cancel();
    },
  );

  test('watch contention is mapped with the boundary stack', () async {
    final stackTrace = StackTrace.fromString('ordering-watch-stack');
    final errors = <(Object, StackTrace)>[];
    final done = Completer<void>();
    final subscription = repository
        .watchOrder(OrderId.fromInput(1))
        .listen(
          (_) {},
          onError: (Object error, StackTrace stack) {
            errors.add((error, stack));
          },
          onDone: done.complete,
        );
    await Future<void>.delayed(Duration.zero);

    store.orderControllers.single.addError(
      const OrderingStoreException(),
      stackTrace,
    );
    await done.future;

    expect(errors.single.$1, isA<OrderingPersistenceException>());
    expect(identical(errors.single.$2, stackTrace), isTrue);
    expect(store.watchOrderCancellations, 1);
    await subscription.cancel();
  });

  test('an asynchronous unexpected watch error retains identity', () async {
    final failure = StateError('unexpected async watch failure');
    final stackTrace = StackTrace.fromString('unexpected-async-watch-stack');
    final errors = <(Object, StackTrace)>[];
    final done = Completer<void>();
    repository
        .watchOrder(OrderId.fromInput(1))
        .listen(
          (_) {},
          onError: (Object error, StackTrace stack) {
            errors.add((error, stack));
          },
          onDone: done.complete,
        );
    await Future<void>.delayed(Duration.zero);

    store.orderControllers.single.addError(failure, stackTrace);
    await done.future;

    expect(errors.single.$1, same(failure));
    expect(identical(errors.single.$2, stackTrace), isTrue);
    expect(store.watchOrderCancellations, 1);
  });

  test('maps a synchronous watch creation failure with its stack', () async {
    final stackTrace = StackTrace.fromString('synchronous-watch-stack');
    store.failure = const OrderingStoreException();
    store.failureStack = stackTrace;
    final errors = <(Object, StackTrace)>[];
    final done = Completer<void>();

    repository.watchOrders().listen(
      (_) {},
      onError: (Object error, StackTrace stack) {
        errors.add((error, stack));
      },
      onDone: done.complete,
    );
    await done.future;

    expect(errors.single.$1, isA<OrderingPersistenceException>());
    expect(identical(errors.single.$2, stackTrace), isTrue);
    expect(store.watchOrdersCalls, 0);
  });

  test('preserves a synchronous unexpected watch failure', () async {
    final failure = StateError('unexpected watch failure');
    final stackTrace = StackTrace.fromString('unexpected-watch-stack');
    store.failure = failure;
    store.failureStack = stackTrace;
    final errors = <(Object, StackTrace)>[];
    final done = Completer<void>();

    repository.watchOrders().listen(
      (_) {},
      onError: (Object error, StackTrace stack) {
        errors.add((error, stack));
      },
      onDone: done.complete,
    );
    await done.future;

    expect(errors.single.$1, same(failure));
    expect(identical(errors.single.$2, stackTrace), isTrue);
  });

  test('watch snapshots are immutable', () async {
    final snapshot = await repository.watchOrders().first;

    expect(() => snapshot.clear(), throwsUnsupportedError);
  });

  test('one returned observation rejects a second listener', () async {
    final stream = repository.watchOrders();
    final firstSubscription = stream.listen((_) {});
    await Future<void>.delayed(Duration.zero);

    expect(() => stream.listen((_) {}), throwsStateError);

    await firstSubscription.cancel();
  });
}

StoredOrder _storedDraftWithLine() => StoredOrder(
  id: 1,
  statusValue: 0,
  totalMinorUnits: 100,
  currencyCode: 'USD',
  revision: 1,
  createdAtUtcMilliseconds: 10,
  placedAtUtcMilliseconds: null,
  cancelledAtUtcMilliseconds: null,
  lines: <StoredOrderLine>[_storedLine()],
);

StoredOrderLine _storedLine() => const StoredOrderLine(
  catalogProductId: 2,
  productTitleSnapshot: 'Product',
  unitPriceMinorUnits: 50,
  currencyCode: 'USD',
  quantity: 2,
  catalogRevision: 7,
);

final class _OrdersStore implements OrderingOrdersStore {
  StoredOrder? order = _storedDraftWithLine();
  int affectedRows = 1;
  Object? failure;
  StackTrace? failureStack;
  int watchOrdersCalls = 0;
  int watchOrdersCancellations = 0;
  int watchOrderCalls = 0;
  int watchOrderCancellations = 0;
  final List<StreamController<List<StoredOrder>>> ordersControllers = [];
  final List<StreamController<StoredOrder?>> orderControllers = [];

  @override
  Future<int> cancelOrder({
    required int id,
    required int expectedRevision,
    required int cancelledAtUtcMilliseconds,
  }) async {
    _throwIfNeeded();

    return affectedRows;
  }

  @override
  Future<StoredOrder?> getOrder(int id) async {
    _throwIfNeeded();

    return order;
  }

  @override
  Future<int> insertDraft({required int createdAtUtcMilliseconds}) async {
    _throwIfNeeded();

    return 1;
  }

  @override
  Future<int> placeOrder({
    required int id,
    required int expectedRevision,
    required int totalMinorUnits,
    required String currencyCode,
    required int placedAtUtcMilliseconds,
    required List<StoredOrderLine> lines,
  }) async {
    _throwIfNeeded();

    return affectedRows;
  }

  @override
  Future<int> replaceDraftLines({
    required int id,
    required int expectedRevision,
    required int? totalMinorUnits,
    required String? currencyCode,
    required List<StoredOrderLine> lines,
  }) async {
    _throwIfNeeded();

    return affectedRows;
  }

  @override
  Stream<StoredOrder?> watchOrder(int id) {
    _throwIfNeeded();
    watchOrderCalls += 1;
    final controller = StreamController<StoredOrder?>(
      sync: true,
      onCancel: () {
        watchOrderCancellations += 1;
      },
    );
    orderControllers.add(controller);

    return controller.stream;
  }

  @override
  Stream<List<StoredOrder>> watchOrders() {
    _throwIfNeeded();
    watchOrdersCalls += 1;
    late final StreamController<List<StoredOrder>> controller;
    controller = StreamController<List<StoredOrder>>(
      sync: true,
      onListen: () {
        controller.add(<StoredOrder>[?order]);
      },
      onCancel: () {
        watchOrdersCancellations += 1;
      },
    );
    ordersControllers.add(controller);

    return controller.stream;
  }

  void _throwIfNeeded() {
    final current = failure;
    if (current != null) {
      Error.throwWithStackTrace(current, failureStack!);
    }
  }
}
