import 'package:ordering/src/application/order_line_input.dart';
import 'package:ordering/src/application/ordering_facade.dart';
import 'package:ordering/src/application/ordering_utc_now.dart';
import 'package:ordering/src/application/product_offers/order_product_offer.dart';
import 'package:ordering/src/application/product_offers/product_offer_provider.dart';
import 'package:ordering/src/domain/order/order.dart';
import 'package:ordering/src/domain/order/order_line.dart';
import 'package:ordering/src/domain/order/policies/order_placement_policy.dart';
import 'package:ordering/src/domain/order/value_objects/catalog_product_reference.dart';
import 'package:ordering/src/domain/order/value_objects/order_id.dart';
import 'package:ordering/src/domain/order/value_objects/order_line_quantity.dart';
import 'package:ordering/src/domain/order/value_objects/order_status.dart';
import 'package:ordering/src/domain/ordering_exception.dart';
import 'package:ordering/src/domain/repository/order_repository.dart';

/// Default Ordering application service.
final class OrderingService implements OrderingFacade {
  /// Creates the service over owned-context ports and stateless policy.
  const OrderingService({
    required this._repository,
    required this._offers,
    required this._utcNow,
    required this._placementPolicy,
  });

  final OrderRepository _repository;
  final ProductOfferProvider _offers;
  final OrderingUtcNow _utcNow;
  final OrderPlacementPolicy _placementPolicy;

  @override
  Stream<List<Order>> watchOrders() => _repository.watchOrders();

  @override
  Stream<Order> watchOrder(OrderId orderId) => _repository.watchOrder(orderId);

  @override
  Future<OrderId> createDraft() => _repository.createDraft(_now());

  @override
  Future<void> replaceDraftLines({
    required OrderId orderId,
    required List<OrderLineInput> lines,
  }) async {
    final copiedInputs = List<OrderLineInput>.unmodifiable(lines);
    final current = await _repository.getOrder(orderId);
    _requireDraft(current);
    if (copiedInputs.length > Order.maxLineCount) {
      throw const OrderingTooManyLinesException();
    }
    final requested = <CatalogProductReference, OrderLineQuantity>{};
    for (final input in copiedInputs) {
      final product = CatalogProductReference.fromInput(input.productId);
      final quantity = OrderLineQuantity.fromInput(input.quantity);
      if (requested.containsKey(product)) {
        throw const OrderingDuplicateProductException();
      }
      requested[product] = quantity;
    }

    final replacementLines = requested.isEmpty
        ? const <OrderLine>[]
        : _linesFromOffers(
            requested,
            await _offers.loadOffers(
              Set<CatalogProductReference>.unmodifiable(requested.keys),
            ),
          );
    final replacement = current.replaceDraftLines(replacementLines);
    await _repository.replaceDraftLines(
      current: current,
      replacement: replacement,
    );
  }

  @override
  Future<void> placeOrder(OrderId orderId) async {
    final current = await _repository.getOrder(orderId);
    _requireDraft(current);
    if (current.lines.isEmpty) {
      throw const OrderingEmptyOrderException();
    }
    final quantities = <CatalogProductReference, OrderLineQuantity>{
      for (final line in current.lines) line.product: line.quantity,
    };
    final refreshedLines = _linesFromOffers(
      quantities,
      await _offers.loadOffers(
        Set<CatalogProductReference>.unmodifiable(quantities.keys),
      ),
    );
    _placementPolicy.validateRefresh(
      draft: current,
      refreshedLines: refreshedLines,
    );
    final placed = current.placeWithRefreshedLines(
      refreshedLines: refreshedLines,
      placedAt: _now(),
    );
    await _repository.placeOrder(current: current, placed: placed);
  }

  @override
  Future<void> cancelOrder(OrderId orderId) async {
    final current = await _repository.getOrder(orderId);
    final cancelled = current.cancel(_now());
    await _repository.cancelOrder(current: current, cancelled: cancelled);
  }

  List<OrderLine> _linesFromOffers(
    Map<CatalogProductReference, OrderLineQuantity> quantities,
    Map<CatalogProductReference, OrderProductOffer> offers,
  ) {
    for (final entry in offers.entries) {
      if (!quantities.containsKey(entry.key) ||
          entry.value.product != entry.key) {
        throw const OrderingDataIntegrityException();
      }
    }
    if (offers.length != quantities.length ||
        !quantities.keys.every(offers.containsKey)) {
      throw const OrderingProductUnavailableException();
    }
    final products = quantities.keys.toList(growable: false)
      ..sort((left, right) => left.value.compareTo(right.value));

    return List<OrderLine>.unmodifiable(
      products.map((product) {
        final offer = offers[product]!;

        return OrderLine.fromOffer(
          product: product,
          title: offer.title,
          unitPrice: offer.unitPrice,
          currency: offer.currency,
          quantity: quantities[product]!,
          catalogRevision: offer.catalogRevision,
        );
      }),
    );
  }

  DateTime _now() => _utcNow().toUtc();

  void _requireDraft(Order order) {
    if (order.status != OrderStatus.draft) {
      throw const OrderingTransitionException(
        OrderingTransitionFailure.orderNotDraft,
      );
    }
  }
}
