# Catalog

`catalog` is the executable reference bounded context in the template. It is a
pure-Dart product catalog with real domain behavior, not a CRUD model or an
empty layering example.

The reference problem space places the Catalog subdomain in the Commerce
domain and classifies it as core. The Catalog package is the bounded context
that currently models that subdomain. This one-to-one mapping and strategic
classification belong only to the scaffold's example model; a product created
from the template must remodel its own domains, subdomains, context boundaries,
and types from business differentiation, language, invariants, and ownership.

## Boundary and ownership

The runtime dependency flow is:

```text
ApplicationDatabase
→ private item/category DAOs
→ CatalogItemsStore + CatalogCategoriesStore
→ StoreCatalogItemRepository + StoreCatalogCategoryRepository
→ CatalogService + CatalogProductOfferService
→ CatalogApplication composition result
  ├── CatalogFacade
  └── CatalogProductOfferReader
```

[`catalog.dart`](lib/catalog.dart) is the public domain/application API. It
exports the facade, entities, value objects, and context-owned command
failures. The publication policy remains internal so presentation cannot apply
lifecycle rules outside the facade. The entrypoint does not expose the
repository port, store records, DAOs, Drift rows, or composition
implementations.

[`catalog_composition.dart`](lib/catalog_composition.dart) is the app-only
composition API. App DI supplies two borrowed narrow stores and receives one
lifecycle-free `CatalogApplication`, then narrows it to `CatalogFacade` for
presentation and `CatalogProductOfferReader` for an authorized downstream
composition. Catalog never closes either store or the shared database.

[`catalog_product_offers.dart`](lib/catalog_product_offers.dart) is the
capability-oriented upstream contract prepared for a reviewed downstream
integration. It exposes immutable point-in-time product-offer snapshots, a
batch reader, and capability-owned failures needed by a downstream
Anti-Corruption Layer. It does not export Catalog entities or persistence. The
Catalog-only Context Map intentionally contains no dependency edge; the
Published Language relationship is added only with its real downstream
context and adapter.

Product Offers is an application-level query capability under
`src/application/product_offers`, not a fifth architectural layer or a second
bounded context. Catalog owns the published status and offer values, while it
does not know which downstream context consumes them. A separate context is
introduced only if offer ownership, lifecycle, or business policy becomes
independent from Catalog.

Dependency direction is:

```text
domain ← application
  ↑            ↑
infrastructure ← composition
```

Infrastructure implements domain-owned persistence ports. Composition creates
the concrete adapters and application services. Only infrastructure and
composition import `package:app_database/stores/catalog.dart`; domain and
application remain independent of Flutter, Drift, SQLite, and the root app.

Repository ports are grouped in `domain/repository`; their store-backed
adapters are grouped separately in `infrastructure/persistence`. The folders
express port and adapter ownership, not duplicated implementations.
Catalog has no `integration` directory because it currently consumes no
external bounded-context API.

## Domain model

`CatalogItem` is an immutable product entity. It contains:

- `CatalogItemTitle` — canonical, non-empty title of at most 120 graphemes;
- `CatalogItemDescription` — canonical description of at most 2,000
  graphemes, allowed to be empty only while the product is incomplete;
- `CatalogItemPrice` — non-negative minor units and a canonical three-letter
  currency code, without floating-point arithmetic;
- `CatalogItemStatus` — explicit stable stored values `draft`, `published`, and
  `archived`;
- `CatalogItemRevision` — an optimistic concurrency token;
- an optional category identity.

`CatalogCategory` has its own identity, validated name, and activation state.
An inactive category remains authoritative data but cannot accept a newly
published product or a published-offer edit. Deactivation does not archive
existing products: already published products remain visible through the
Published Language until their own status changes.

Each Value Object publishes its own UI-relevant bound. Presentation imports
only `catalog.dart` and uses `CatalogItemTitle.maxLength`,
`CatalogItemDescription.maxLength`, `CatalogCategoryName.maxLength`, and
`CatalogItemPrice.currencyCodeLength`. Widgets provide UX guidance only; the
facade and domain always validate raw input again.

`CatalogItemPrice.maxSafeMinorUnits` is the technical integer envelope shared
by every supported Dart runtime and SQLite storage, not a commercial price
limit. The database repeats this storage-level constraint as defense in depth,
and a cross-package contract test proves that the exact boundary round-trips
and the next integer is rejected by both sides. A future product-specific
maximum may be narrower and remain domain-owned without changing the physical
storage envelope.

Entity equality is identity-based. Two item snapshots with the same ID are the
same entity even when their title, price, status, or revision differs.
Presentation must compare render fields explicitly and use ID for widget keys;
it must not suppress snapshots using entity equality.

User input factories trim permitted surrounding whitespace. Rehydration
factories never repair persisted data. The package does not perform Unicode
normalization, case folding, locale-aware comparison, or duplicate detection.
Duplicate product titles and category names are currently allowed.
Legacy v1 title trimming is an explicit database cutover rule before Catalog
rehydration, not a runtime repair path.

Published and archived items must rehydrate as complete publishable offers;
only drafts may retain an empty description, zero price, `XXX` currency, or no
category. Violations are unexpected `CatalogDataIntegrityException`s.

## Product lifecycle

Drafts may be incomplete so legacy data and work in progress remain
representable. `updateDraft` is the only public command that replaces product
details, and the entity rejects detail revision after publication.

`CatalogItemPublicationPolicy` publishes only a draft that has:

- a non-empty description;
- a positive price;
- a concrete currency rather than the `XXX` incomplete-draft placeholder;
- an assigned active category.

Every state-dependent public command receives the revision from the
authoritative snapshot on which the caller based its decision. Catalog rejects
an already-stale token before applying lifecycle policy. Publication then
performs a conditional database update using that revision and rechecks that
its category is still active. This closes both the caller read-to-command gap
and the service read-to-commit gap. Draft edits and lifecycle changes increment
the revision atomically. A failed optimistic condition becomes a typed
concurrent-state transition failure.

A published item may be archived. Published and archived items cannot be
edited through the draft command. A published offer can be revised through the
separate optimistic command, which rechecks the new category's active state in
the same conditional SQL update and keeps status `published`. Automatic retry
is deliberately absent: the caller reloads authoritative state before deciding
whether to repeat a command.

Deletion is a draft-only optimistic command. Catalog first loads the item,
matches the caller-provided revision, requires `draft`, verifies that its
revision can advance, and asks persistence to delete only the matching ID,
draft status, and revision. A missing item fails as not found; zero affected
rows after a successful load means that another actor changed or deleted the
item. Published and archived products are never deleted through this API.

The update, publication, and archival commands return `Future<void>`. Normal
completion means the optimistic write committed; typed exceptions describe a
rejection. Catalog does not manufacture result objects without a consumer, and
authoritative state continues to arrive through `watchItems()`. A real domain
event is added only with an independent domain reaction; a cross-process event
requires its own integration contract and durable delivery policy.

## Product Offers and Published Language

`findPublishedOffers` copies its input before awaiting, accepts at most 100
positive product IDs, and executes one store query. It returns an immutable map
containing only currently published products; draft, archived, and missing IDs
are omitted. Category activation is publication/edit policy and does not hide
an existing published item. Offer DTOs contain only product ID, title, price,
currency, and Catalog revision.

Keys are returned in ascending product-ID order. The application boundary
rejects duplicate or unrequested repository records instead of silently
overwriting or exposing an inconsistent batch.

`CatalogProductOfferSnapshot` is a Published Language DTO, not a Catalog entity,
Value Object, event, or persisted message. It represents one product revision.
A downstream context must translate it through an Anti-Corruption Layer into
its own model. The revision is traceability data, not a contract version,
freshness lease, or cross-context optimistic lock.

Published Language classifies the vocabulary of this inter-context contract;
it does not define transport or consistency. The current transport is one
synchronous Dart query. The result is a point-in-time snapshot, and a later
downstream commit does not share Catalog's transaction.

`CatalogOfferUnavailableException` means that the product-offer query
capability is temporarily unavailable; it never means that a particular
product is absent. Missing, draft, and archived products are omitted from a
successful result. Invalid request batches use the separate privacy-safe
`CatalogOfferRequestException`.

## Failures

`CatalogExpectedException` classifies operational failures without prescribing
one UI treatment. Callers catch only concrete failures documented for an
operation:

- invalid title, description, price, or category name;
- missing item or category;
- publication-policy rejection;
- invalid or concurrent lifecycle transition;
- temporary Catalog persistence contention.

`CatalogDataIntegrityException` is unexpected and must reach root error
handling. Other unexpected store failures retain their original object and
stack. Public Catalog exceptions are sanitized and contain no rejected input,
identifier, SQL, path, database identity, or vendor message.

## Observation lifecycle

Every `watchItems()` and `watchCategories()` invocation returns a new
single-subscription stream. A subscription receives the current immutable
snapshot followed by changes in ascending database-assigned ID order. The
caller owns cancellation, which propagates to the underlying store stream.

Catalog does not cache, broadcast, share, retry, or resubscribe observations.
An error or normal completion terminates the current observation. A caller
retries by invoking the facade again. Flutter presentation owns loading, ready,
unavailable, stale-data, and retry state.

Commands await the local write. Collection changes remain authoritative through
the observation stream. A normally completed command Future confirms commit;
no additional synthetic lifecycle fact is returned.

## Extending the context

Keep behavior in the existing facade while it belongs to the same application
boundary. Add another application service only for a distinct workflow or
transaction boundary. Add a repository or adapter only for a real independent
data source or policy.

Do not copy this layout mechanically. In particular, do not create empty
layers, a disposable Catalog module without owned resources, a repository base
class, a mapper interface, one use-case class per facade method, or a generic
event dispatcher merely for symmetry.
