# Ordering

`ordering` is the second executable bounded context in the reference
application. It owns persistent multi-line Orders and demonstrates a real DDD
downstream boundary without sharing Catalog entities, repositories, tables, or
transactions.

The reference problem space places the Ordering subdomain in the Commerce
domain and classifies it as core. The Ordering package is the bounded context
that currently models that subdomain. This one-to-one mapping and strategic
classification are illustrative; applications created from the scaffold must
reassess them from their own business strategy and ownership.

## Aggregate boundary

`Order` is the aggregate root. It owns an immutable line collection, status,
optimistic revision, timestamps, and calculated money. One Order contains at
most 100 distinct Catalog product references. Duplicate product IDs are
rejected rather than merged silently.

A persistent draft may be empty. Its lines are empty and its money is `null`.
A non-empty draft and every placed Order have one concrete currency and a
checked total. Unit prices, line totals, aggregate totals, quantities, and
revisions stay within Dart's Web-safe integer range. Placed lines are
immutable; cancellation is the only later transition. A cancelled Order is
terminal.

Order equality is based only on `OrderId`. Renderable fields and revision do
not participate, so presentation must compare the values it renders and use
the ID for widget identity.

## Public and composition APIs

[`ordering.dart`](lib/ordering.dart) is the presentation-facing application
API. It exports `OrderingFacade`, the aggregate and value vocabulary, command
inputs, and sanitized context failures. It exports no
repository, store, Catalog DTO, database type, or adapter.

[`ordering_composition.dart`](lib/ordering_composition.dart) is app-only. It
exports the Catalog ACL adapter and assembles a facade from a borrowed
`OrderingOrdersStore`, the Ordering-owned `ProductOfferProvider`, and an
explicit UTC clock function. App composition connects Catalog's read-only
Published Language to that adapter. The returned facade owns no disposable
resource. The app database module remains the sole owner of the physical
connection.

Dependency direction is:

```text
domain ← application
  ↑            ↑
infrastructure ← composition
```

Only infrastructure/composition imports
`package:app_database/stores/ordering.dart`. Only the
Ordering-owned Catalog adapter imports `catalog_product_offers.dart`. Domain and
application never import Catalog, Drift, Flutter, or the root application.

Repository ports live in `domain/repository`, while their persistence adapters
live in `infrastructure/persistence`. Ordering additionally has
`infrastructure/integration/catalog` because it actually consumes an upstream
bounded-context contract. Context directories are responsibility-driven and
are not made mechanically identical; Catalog therefore has no empty matching
integration directory.

## Catalog Anti-Corruption Layer

Ordering asks `ProductOfferProvider` for all requested products in one batch.
`CatalogProductOfferAdapter` translates `CatalogProductOfferSnapshot` into
Ordering-owned product references, title snapshots, positive unit prices,
concrete currencies, and Catalog revisions. Missing or unpublished products
become `OrderingProductUnavailableException`; temporary Catalog contention
becomes `OrderingCatalogUnavailableException`. Unexpected upstream failures
retain their original object and stack. A Published Language request rejection
for Ordering's already validated batch is an impossible contract mismatch and
becomes `OrderingDataIntegrityException` instead of leaking a Catalog failure
through the downstream boundary.

The adapter snapshots its request before the first asynchronous boundary.
Every returned map key must have been requested and must match the product ID
inside its snapshot. Extra records or identity mismatches are upstream
contract corruption and become `OrderingDataIntegrityException`; absence of a
requested published product remains the expected unavailable-product case.

The Context Map relationship is customer/supplier with Catalog upstream and
Ordering downstream. This describes governance: Ordering's requirements inform
the Product Offers contract while Catalog owns and evolves it without exposing
its internal model. It remains useful when one team owns both contexts.

The current transport is a synchronous query. The Catalog read and Ordering
write do not share a transaction. A stored line is the point-in-time snapshot
returned by that query and deliberately does not converge to subsequent Catalog
changes. `catalogRevision` records which Catalog item revision was observed; it
is not a lease or cross-context lock.

## Commands and consistency

`replaceDraftLines` validates the full requested set, performs one Catalog
batch query, constructs Ordering-owned snapshots, and atomically replaces all
stored lines under an Order status/revision condition. An empty replacement
does not call Catalog.

`placeOrder` reloads the draft, queries all offers again, automatically accepts
current title/price/revision snapshots, recalculates money, and conditionally
commits refreshed lines plus placement in one local Ordering transaction.
Catalog may change after the query; that later change does not mutate the
placed Order.

Runtime dependency is operation-specific. Watching Orders, creating an empty
draft, replacing lines with an empty list, and cancelling an Order do not call
Catalog. A non-empty replacement and placement require Catalog. If that query
is unavailable, the command fails with `OrderingCatalogUnavailableException`
before an Ordering write begins; existing state remains unchanged and stale
draft snapshots are not used as a fallback. A caller may explicitly retry the
whole command, which performs a new Catalog query.

Every successful mutation increments the Order revision. A zero-row
conditional update is a concurrent-state transition failure. Automatic retry
and idempotency keys are absent: the local BLoC will serialize commands, and a
future remote command API must define its own durable idempotency contract.

## Time and observation

Composition supplies `OrderingUtcNow`; production uses
`DateTime.now().toUtc()` and tests use fixed values. Persistence stores UTC Unix
milliseconds. Time is not a concurrency token, and wall-clock rollback does
not invalidate aggregate state.

Each watch method returns a fresh single-subscription stream. It emits current
authoritative state followed by committed revisions. Cancellation reaches the
store. Error or normal completion terminates that observation; retry means a
new facade call. The package does not cache, broadcast, or resubscribe.

## Command completion and deferred capabilities

Placement and cancellation return `Future<void>`. Normal completion means the
local aggregate transition committed; authoritative totals, timestamps,
revision, and status are read through `watchOrder()`. Ordering does not create
result objects without a consumer. A real domain event is introduced only with
an independent domain reaction and an explicit transaction/failure policy.
Reliable delivery requires a separately versioned integration event, an outbox
written with the business change, a relay, and idempotent consumption. It never
uses the best-effort application `AppEventBus`.

Ordering v1 is single-user local reference behavior. It intentionally contains
no customer, tenant, payment, tax, discount, inventory, delivery, fulfillment,
broker, or shared Catalog/Ordering transaction. Add those only as real bounded
contexts or capabilities with explicit ownership.
