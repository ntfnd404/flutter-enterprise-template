import 'package:app_database/stores/ordering.dart';
import 'package:ordering/src/application/ordering_facade.dart';
import 'package:ordering/src/application/ordering_service.dart';
import 'package:ordering/src/application/ordering_utc_now.dart';
import 'package:ordering/src/application/product_offers/product_offer_provider.dart';
import 'package:ordering/src/domain/order/policies/order_placement_policy.dart';
import 'package:ordering/src/infrastructure/persistence/store_order_repository.dart';

/// Creates Ordering over borrowed persistence and an Ordering-owned offer port.
OrderingFacade createOrderingFacade({
  required OrderingOrdersStore store,
  required ProductOfferProvider productOffers,
  required OrderingUtcNow utcNow,
}) => OrderingService(
  repository: StoreOrderRepository(store),
  offers: productOffers,
  utcNow: utcNow,
  placementPolicy: const OrderPlacementPolicy(),
);
