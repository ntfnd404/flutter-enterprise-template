/// Product-offer query contract exposed to downstream bounded contexts.
///
/// The Context Map classifies this capability-oriented inter-context API as a
/// Published Language. Published Language describes the shared contract
/// vocabulary, not its transport or delivery guarantee. It is not a
/// presentation or event API: Catalog entities, persistence records, and
/// implementation details remain private.
library;

export 'src/application/product_offers/catalog_offer_request_exception.dart';
export 'src/application/product_offers/catalog_offer_unavailable_exception.dart';
export 'src/application/product_offers/catalog_product_offer_reader.dart';
export 'src/application/product_offers/catalog_product_offer_snapshot.dart';
