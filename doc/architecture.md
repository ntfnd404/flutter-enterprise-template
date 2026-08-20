# Application architecture

This document is the normative target for startup, manual dependency injection,
resource ownership, package topology, DDD collaboration, diagnostics, feature
composition, routing, localization, and application events in `template`. It
consolidates and replaces Architecture Source of Truth v7 and its later
amendments.

Implementation-level conventions are documented separately in
[code style](code_style.md). Accepted commits, review order, temporary
implementation gaps, and capability gates are tracked in the
[architecture roadmap](roadmap.md). The roadmap cannot override this target.
`architecture/context_map.yaml` deliberately records only already accepted
bounded contexts and relationships, so a planned relationship can appear here
before it is added to that accepted-state artifact.

## Documentation authority

This document owns normative architecture contracts. The other canonical
artifacts have narrower responsibilities:

- `doc/code_style.md` owns coding and naming conventions;
- `architecture/context_map.yaml` records only DDD topology accepted in Git;
- `doc/roadmap.md` records accepted commits, current review scope, ordered
  future work, and temporary target-versus-code gaps;
- `doc/dependency_lifecycle.md` provides detailed examples of the DI and
  lifecycle contracts fixed here;
- the root README provides onboarding, while package READMEs document their
  owning capability;
- `AGENTS.md` and `CLAUDE.md` derive executable contributor instructions from
  these documents and cannot introduce architecture decisions;
- ADRs preserve rationale and consequences but cannot override a newer
  normative contract.

All canonical documentation is maintained in English. When artifacts conflict,
the narrower document is corrected to this architecture rather than treating
the roadmap, an instruction file, an example, or an ADR as a competing source
of truth.

## Startup responsibilities

| Component | Responsibility |
|---|---|
| `main` | One-line delegate to the testable application entrypoint |
| `runApplication` | Root diagnostics, binding prelude, Environment loading, graph composition, ownership handoff, startup fallback |
| `AppErrorBoundary` | Root zone, Flutter/platform handlers, injected safe reporting |
| `AppLoggingModule` | Future root-isolate support-log ownership outside the dependency graph |
| `initializeAppFramework` | Environment-dependent process-global framework and required SDK preparation after the binding prelude |
| `buildAppDependencies` | Concrete app-level Database→Catalog→Ordering composition |
| `buildAppDependencyGraph<T>` | Generic transactional construction over one private resource ledger |
| `AppDependencies` | Immutable downstream port/facade catalog without lifecycle APIs |
| `AppDependencyGraphOwner` | Flutter lifecycle adapter that claims one `AppDependencyGraph<Object>` once |
| `App` | Routing and application UI lifecycle |

## Startup sequence

```text
main → runApplication
  → AppErrorBoundary installs Flutter/platform handlers and guarded root zone
  → set debug zone-mismatch policy before binding initialization
  → initialize the Flutter binding inside the guarded root zone
  → future Persistent Support Log phase activates bounded local storage
  → load and validate AppStartupConfiguration
  → initializeAppFramework(configuration.environment, logger)
  → build and validate the route registry
  → buildAppDependencyGraph creates one private ownership boundary
  → buildAppDependencies receives only a register-only resource capability
  → the graph seals registration and exposes AppDependencies
  → build app-owned Page catalog from narrow dependencies
  → runApp hands the graph to its root lifecycle owner
  → App owns Rolter lifecycle
  → feature-owned Page composition
```

The boundary is installed before binding initialization, Environment parsing,
or any future vendor reporter. In debug,
`BindingBase.debugZoneErrorsAreFatal` is set before the binding exists; the
binding is then initialized inside the guarded root zone. This configuration-
free prelude is deliberately separate from `initializeAppFramework`, whose
URL-strategy and required-SDK work may depend on the validated Environment.

The later Persistent Support Log phase inserts bounded best-effort local
activation after binding and before Environment parsing. That order permits a
support-safe Environment failure to reach app-local storage without reading or
persisting the rejected configuration. Until that phase is accepted, Startup
uses the same sequence with the activation step absent. `runApp` remains inside
the guarded zone. The route registry is evaluated before app-owned graph
resources are created. Page composition occurs after graph construction and
before ownership handoff. Subordinate builders are tested directly; production
does not expose a generic Page-catalog replacement seam. Tests own and dispose
an injected boundary.

## Top-level boundaries

The source tree uses an application-shell plus vertical-slice layout:

The package grouping decision is recorded in
[ADR 0002](adr/0002_enterprise_package_taxonomy.md).

`packages` is the physical Pub workspace container rather than an
architectural layer. Its two child groups classify package responsibility:
`bounded_contexts` contains business-model boundaries, while `libraries` is a
repository category for reusable technical and foundation capabilities. The
word does not refer to a Dart `library` declaration or a DDD Shared Kernel.

- `app` owns application environment policy, process-global initialization,
  dependency-graph composition and ownership, root framework/application
  wrappers, routing composition, and application-wide cross-feature
  notification contracts;
- `core` contains feature-neutral internal application infrastructure and must
  not import `app` or `feature`; it does not promise portability as an external
  reusable package;
- `feature/<name>` contains Flutter presentation and feature-local UI
  orchestration;
- `packages/libraries/app_database` owns the shared physical Drift connection, schema,
  migrations, private DAOs, and narrow context stores;
- `packages/bounded_contexts/catalog` and
  `packages/bounded_contexts/ordering` are executable reference bounded
  contexts; `packages/bounded_contexts/<context>` contains each additional
  real business capability;
- `packages/libraries/<capability>` contains reusable technical or foundation
  capabilities without their own business model.

A technical adapter stays with its application or bounded-context owner until
a package boundary has evidence: multiple real consumers, an independently
useful public contract, multiple provider/platform implementations, separate
ownership or lifecycle, or material independent testing, versioning, or
delivery. Meeting one criterion permits a boundary review; it does not make
extraction automatic. `common`, `utils`, and empty symmetry packages are not
valid ownership models.

`app` is deliberately not a feature: it has no user-facing use case or BLoC of
its own. A feature's data-only route, decoder, route Page adapter, DI boundary,
and view remain in the same feature slice. The route itself imports no UI or
DI. The `routing/page_composition/<name>_route_page.dart` adapter is the only
routing file that imports the feature's route, scope, and screen. Importing the
app-owned routing SPIs is not a feature-to-feature dependency.

`app/view` is not a catalog of screens. `App` owns the normal router lifecycle,
and `StartupFailureApp` owns the minimal pre-DI `MaterialApp`; both delegate
their user-facing content and state to feature slices. NotFound is a
normal-graph recovery feature. StartupFailure is an isolated pre-DI feature.

### Deliberate exclusions

The base architecture does not use a service locator, global dependency
registry, inherited `AppScope.of()` lookup, static startup coordinator, or
runtime application handle. Presentation never receives a repository, store,
database, vendor client, graph, or graph owner.

It does not create universal Module, Repository, Mapper, UnitOfWork, retry, or
exactly-once abstractions; one use-case class per facade method; mandatory
`Either`/`Result`; broadcast authoritative streams; automatic watch
resubscription; or automatic persistence retry. Resources are modeled by their
real ownership contract rather than a shared lifecycle interface.

It does not introduce global domain/data packages, a Flutter package per UI
feature, empty symmetric layers, shared Catalog/Ordering transactions or
foreign keys, a global DomainEvent/dispatcher, or durable messaging without a
delivery requirement. AppEventBus never carries required business work.

Remote diagnostics, analytics, feature flags, session/tenant state, Pricing,
Offering, Inventory, Payment, Customer, Delivery, Cart, a second app, and full
multiplatform CI remain capability-gated in the roadmap. Their absence is an
intentional boundary, not permission to add nullable placeholders or provider
guesses.

### Business bounded contexts

Strategic DDD separates the problem space from its implementation boundaries:

- a **domain** is the business problem area addressed by the system;
- a **subdomain** is a cohesive part of that problem;
- **core**, **supporting**, and **generic** classify a subdomain's strategic
  importance; they are not subdomain names;
- a **bounded context** is a solution-space boundary for one model,
  Ubiquitous Language, public contract, ownership, and dependency direction;
- `domain/` is the domain layer inside one bounded context, not the domain of
  the whole system;
- a **persistence slice** is physical storage logically owned by a context; it
  is neither a subdomain nor an implementation of that context's domain model.

The reference problem space is the `commerce` domain with `catalog` and
`ordering` subdomains. Both are classified as `core` only for the illustrative
reference application. A product created from the scaffold must remodel its
own domains, subdomains, and strategic types instead of inheriting that
classification automatically.

The target maps each reference subdomain to one bounded context, but this is
not a universal DDD rule. A complex subdomain may require several contexts,
and one cohesive context may model several small subdomains.
Splitting or combining them requires evidence from language, invariants,
ownership, security, release cadence, or integration pressure.

`architecture/context_map.yaml` records both sides without conflating them:
`domains` declares problem-space subdomains and their types;
`bounded_contexts` declares implementation boundaries and references the
subdomains they model; `dependencies` records relationships between contexts.
Its `version` is the repository-local map schema version, not a Product Offers
contract or aggregate revision.

Technical capabilities such as the database host, secure storage, device
bridges, observability transports, analytics adapters, and UI kit do not enter
the domain map merely because business scenarios use them. A capability is
reclassified only after strategic modelling identifies its own authoritative
business language, state, invariants, and ownership; an SDK or table alone is
not a subdomain.

A real business bounded context starts as one
`packages/bounded_contexts/<context>` package.
Global `packages/domain` and `packages/data` packages are forbidden because
they erase ownership and encourage unrelated models and repositories to share
one dependency surface. Within a context, `domain`, `application`,
`infrastructure`, and `composition` exist only when active behavior requires
them; empty layers are not scaffolded.

Demo and Activity remain presentation examples rather than artificial business
contexts. A context is split into several packages only after an ADR records a
real independent team/release lifecycle, incompatible platform dependencies,
or demonstrated reuse boundary.

Presentation consumes a context's application facade, command, query, or use
case API. Repository ports, concrete persistence, SDK clients, and
infrastructure-layer
types remain inside the owning context. A simple capability may omit a rich
domain layer, but it is still grouped by business capability rather than by a
global technical layer.

`packages/bounded_contexts/catalog` demonstrates the complete boundary with active behavior.
Its product and category entities use typed value objects; publication is a
domain policy; successful commands complete only after their local write.
`CatalogItemRepository` and `CatalogCategoryRepository` are domain-owned
persistence ports. Their store adapters live under
`infrastructure/persistence`. `CatalogService` implements the public
`CatalogFacade`, while `CatalogProductOfferService` implements the separate
`CatalogProductOfferReader`. `CatalogApplication` is only the immutable
composition result that carries both narrowed ports. The Context Map
classifies the Product Offers contract exposed through that reader as a
Published Language. Product Offers is grouped under Catalog's application
layer because it is a query capability, not another architectural layer or
bounded context. The repository port is grouped in `domain/repository` because
it speaks only domain types and models persistence of the
context's authoritative model. A query-only port expressed in application
language would instead belong to application; interfaces are not moved into
domain mechanically.

`catalog_product_offers.dart` is the separate public inter-context entrypoint.
`CatalogProductOfferSnapshot` is an immutable point-in-time DTO, not a Catalog
entity, Value Object, domain event, or Ordering type. It carries only product
ID, title, price, currency, and Catalog item revision and is translated
immediately by the downstream ACL.

The reader accepts at most 100 positive IDs, copies caller input before its
first asynchronous boundary, performs no query for an empty set and one batch
query otherwise, and returns an immutable ID-ordered map. Only published items
are returned; missing, draft, and archived IDs are absent. Category
deactivation does not hide a product that was already published. Duplicate or
unrequested persistence records are data-integrity failures rather than
last-write-wins map entries.

Catalog title, description, category-name, price, lifecycle status, and
optimistic revision invariants are enforced by their owning domain types. Text
limits use grapheme clusters. User input is normalized before validation;
persisted values are rehydrated strictly and never silently repaired. SQL keeps
storage-level constraints, stable status values, foreign-key integrity,
and a monotonic revision. SQLite `length()` counts code points rather than
grapheme clusters, so domain maxima are intentionally not duplicated as SQL
`CHECK`s.

The reference limits are owned by their Value Objects: title is at most 120
grapheme clusters, description 2000, category name 80, currency is exactly
three uppercase ASCII characters, and price is integer minor units within the
Web-safe integer bound. Duplicate titles are allowed. UI uses the exported
constants as input guidance but never replaces domain validation.

Catalog entity equality is identity-only. Mutable title, price, status, and
completion fields do not participate in `==` or `hashCode`; presentation state
and selectors compare render-relevant values explicitly. Commands without a
useful payload return `Future<void>` and complete only after commit.
Authoritative state comes from observation, not from synthetic post-commit
fact objects.

Published and archived Catalog items must rehydrate as complete publishable
offers; only drafts may retain incomplete offer fields. Published Language
assembly rejects duplicate or unrequested repository records rather than
silently overwriting or exporting an inconsistent batch.

Draft edits and lifecycle transitions compare and increment the item revision.
Publication additionally rechecks the active category in the same conditional
SQL update. The domain policy remains authoritative; the persistence condition
only prevents a concurrent edit or category change from invalidating the
policy decision before commit.

Each Catalog Value Object owns and publishes its own UI-relevant constraint.
Presentation imports only `catalog.dart` and uses those constants as input
guidance, while every facade command validates the raw value again. An inactive
category blocks new publication and published-offer revision but does not hide
or archive an already published product.

`packages/bounded_contexts/ordering` owns a persistent multi-line `Order` aggregate. Empty
drafts have no money; non-empty drafts and placed Orders have checked
single-currency totals. Placement reloads current Catalog offers in one batch,
replaces draft snapshots, and commits the refreshed lines under an Order
status/revision condition. Placed snapshots do not change after later Catalog
updates.

An Order has at most 100 lines. Product IDs and quantities are positive,
duplicate product IDs are rejected rather than merged, all lines share one
currency, `XXX` is invalid, and line plus aggregate arithmetic stays within the
Web-safe integer bound. A draft may be empty; a placed Order may not. Placed
lines are immutable except that a draft or placed Order may transition to the
terminal cancelled state. Every successful mutation advances optimistic
revision, and persisted timestamps are UTC Unix milliseconds supplied through
an injected UTC-now function.

`createDraft` returns the useful `OrderId`; line replacement has no payload.
Placement and cancellation return `Future<void>` and their committed result is
read through Ordering observation. No artificial placed/cancelled fact is
created without an independent consumer.

Ordering owns an Anti-Corruption Layer that imports only
`catalog_product_offers.dart` and converts Product Offers snapshots into
Ordering value objects. This capability-oriented API is classified as a
Published Language in the Context Map. Its domain and application layers never
import Catalog. The Context Map records Catalog as upstream and Ordering as
downstream in a customer/supplier relationship. The target in-process
transport is a synchronous query, but the Catalog read and Ordering write are
never one SQL transaction. Ordering commits the point-in-time snapshot returned
by that query; a placed Order intentionally does not converge to later Catalog
changes.

These terms describe independent aspects of the collaboration:

- Product Offers is the query capability;
- Published Language classifies its shared contract vocabulary;
- the direct Dart call is the target in-process transport;
- the Ordering adapter is the downstream Anti-Corruption Layer;
- point-in-time snapshot describes consistency;
- customer/supplier describes contract governance, even when one team owns the
  scaffold.

Runtime autonomy is operation-specific. Reading Orders, creating an empty
draft, replacing its lines with an empty list, and cancellation do not require
Catalog. Non-empty line replacement and placement do. Catalog unavailability
must leave the Order unchanged, and stale draft offers are never a fallback.

Each observation call returns a new single-subscription stream. It emits the
current authoritative snapshot before subsequent changes, propagates
cancellation to persistence, and terminates on error or completion without
automatic resubscription. Retry is a new facade call; context packages do not
cache or broadcast authoritative watches.

Context trees are not required to be structurally identical. Ordering has an
`infrastructure/integration/catalog` adapter because it consumes Catalog;
Catalog has no empty matching directory because it currently consumes no
upstream context. Repository ports belong in `domain/repository`; persistence
adapters belong in `infrastructure/persistence` so their different
responsibilities remain explicit.

Product Offers remains a Catalog capability while Catalog owns publication,
offer values, and their lifecycle. A new Pricing or Offering bounded context is
considered through context modelling and an ADR when authoritative state,
language, invariants, ownership, security, release cadence, or relationship
pressure becomes independently meaningful. No fixed number of signals is
required, but a new folder, table, or DTO alone is never sufficient. Extraction
must define ownership transfer, data migration/backfill, contract evolution,
cutover, rollback, and removal of the former Catalog authority.

The Product Offers contract remains unversioned while Catalog and Ordering ship
from one repository in one application binary, evolve in a coordinated release,
and have no external consumer, persisted message, or compatibility window. An
independently deployed or external consumer, concurrent contract shapes,
durable messages, or a formal compatibility period introduces explicit wire
versioning. `catalogRevision` is item traceability and never substitutes for a
contract version.

`packages/libraries/app_database` is deliberately not a bounded context. It is the
shared physical persistence host accepted in
[ADR 0001](adr/0001_shared_application_database.md). Generated Drift rows and
private DAOs remain inside that package. Each business context imports only its
narrow store from a dedicated entrypoint in its infrastructure/composition
code. The
single migration chain centralizes physical schema changes without transferring
logical table ownership between contexts.

Public persistence entrypoints scale by owning context under
`package:app_database/stores/<owner>.dart`; they are never combined into a
cross-context store barrel. The application-only module and configuration API
remain available through `app_database_composition.dart`. Internally,
configuration failures stay with `src/configuration`, while connection-opening
failures stay with `src/connection`, instead of accumulating in a generic
exception directory.

Authored version transitions live in
`packages/libraries/app_database/lib/src/migrations`, one semantic file per
consecutive schema version. The registry uses Drift's
generated target `SchemaN` types, runs the requested chain atomically, and
validates foreign keys before commit; transition files never import the current
`ApplicationDatabase`. Handwritten migration policy/data tests are kept apart
from Drift's scaffold and regenerated verifier helpers under the package test
tree. Downgrades fail closed rather than recreating or silently relabeling a
newer schema.

True binary columns use Drift/SQL `BOOLEAN` and map to Dart `bool`. Lifecycle
statuses use explicit stable wire values rather than Dart enum order or names.
SQL `CHECK` constraints protect physical row and cross-column invariants. Text
grapheme limits remain domain-only because SQLite `length()` has different
semantics. A domain/SQL bound deliberately duplicated for defense in depth has
one canonical domain constant and a regression test proving the SQL
representation stays aligned.

Schema-version allocation is serialized across branches. Migrations are
atomic, reject downgrade, validate foreign keys before commit, preserve
AUTOINCREMENT history during rebuild, and treat a failed connection as
terminal. Released snapshots and transitions are not rewritten; repairs are
forward migrations. Old binaries and stale Web tabs must not continue against
a newer physical schema.

Owned persistence sources live under
`src/persistence/<owner>/<cluster>`. Each cluster separates authored `tables`,
optional complex named `queries`, private `dao`, and public/internal `store`
files. An owner-level `src/persistence/<owner>/failures` may contain only store
failure contracts or translation shared by several clusters of that context.
It contains no DAOs, tables, or concrete stores and is not a global failure
layer. The root `src/schema` directory has a different role: it
contains versioned Drift snapshots used by migration tooling. A DAO follows a
cohesive access or transaction responsibility and is not created mechanically
for each table.

`architecture/context_map.yaml` records business context-to-context
relationships. It does not model the technical dependency on
`packages/libraries/app_database`; architecture guards enforce that dependency by
allowing only narrow store entrypoints in context
infrastructure/composition code and
forbidding database access from presentation.

## Responsibility and placement matrix

| Value or action | Owner | Reason |
|---|---|---|
| Flutter binding, URL strategy, required global SDK initialization | `initializeAppFramework` | Process-global startup preparation; each concrete initializer owns its reentrancy and retry policy |
| Firebase/SDK global registry handle used only by an adapter | Local variable in the owning module factory | Borrowed process-global value, not downstream API |
| Simple HTTP/RPC client shared as app infrastructure | App module or direct leaf registration in `buildAppDependencies` | Explicit app ownership without exposing it to presentation |
| Private client created inside a context module | The module | Avoid exposing internals and double disposal |
| Application facade/query/command used by features | Owning context, exposed through `AppDependencies` | Preserve business ownership without leaking repositories |
| Physical Drift database, SQL schema, migrations, and DAOs | `packages/libraries/app_database`, owned by `AppDatabaseModule` | Centralize one physical file and expose only narrow context stores |
| Catalog repository port, store adapter, and application facade | `packages/bounded_contexts/catalog` | Keep business language and mapping in the owning context |
| `AppEventBus` instance with real publishers/subscribers | Graph-owned leaf | Concrete lifecycle stays in composition; consumers receive non-owning publisher/subscriber roles |
| Graph resource ownership | `buildAppDependencyGraph<T>` and `AppDependencyGraphOwner` | Private ledger during construction and one-shot root ownership after handoff |
| Typed application log vocabulary and local projection | `app/diagnostics/logging` | Outer-app observability SPI without exposing a generic logger to packages or features |
| Raw unexpected-error reporting and root handlers | `app/diagnostics/error_reporting` | Keep raw error/stack authority separate from approved log records |
| Future persistent support log | Root-isolate `AppLoggingModule` under Diagnostics | Starts before Environment, outlives the app graph, and degrades independently of functional dependencies |
| BLoC factory | `feature/<name>/di` | Presentation construction policy |
| `Factory<T>` closure | `feature/<name>/di` | Creates a new feature-owned instance without runtime parameters; the invoking lifecycle owner owns the result |
| `ParamFactory<T, P>` closure | `feature/<name>/di` | Creates a new feature-owned instance from a typed route/runtime parameter; the invoking lifecycle owner owns the result |
| BLoC instance | `BlocProvider(create: ...)` | Widget/flow lifecycle |
| Router delegate or UI controller | `App` or a flow shell | UI lifecycle, not graph lifecycle |
| Typed feature route, decoder, and Page definition | Owning feature under `routing` and `routing/page_composition` | Cohesive feature navigation and presentation contribution |
| Application-wide best-effort AppEvent notification | `app/events` | App-owned catalog prevents feature cycles without misclassifying the notification as a DDD integration event |
| Navigation capability shared by otherwise independent features | `app/routing` | Application UI owns semantic navigation and adapts it to routes |
| Route registry and initial-stack policy | `app/routing/app_route_registry.dart` | Data/policy composition point that aggregates feature decoders |
| Page catalog and narrow dependency mapping | `app/routing/app_pages.dart` | UI composition point that aggregates feature Page definitions |
| Invalid route classification | `AppRouteFailureReason` | Privacy-safe app routing SPI without URI/query payload |
| NotFound BLoC, DI, route, and screen | `feature/not_found` | Normal-graph route-recovery scenario |
| Startup fallback `MaterialApp` | `app/view/StartupFailureApp` | Pre-DI framework wrapper |
| Startup-failure BLoC, DI, and screen | `feature/startup_failure` | Isolated user-facing fallback scenario |
| Ephemeral action stream | Owning BLoC | Same-feature one-shot UI commands |

`AppDependencies` is an immutable, flat, app-specific catalog read only at
explicit application composition points and narrowed immediately for each
consumer. It contains only app-lifetime public application facades or ports
with real accepted consumers. The sole temporary exception is an explicitly
bounded consumer gap recorded in the roadmap and covered by a production
composition test; an expired gap removes the dependency. Otherwise a dependency
is added atomically with its first consumer. A disposable capability is exposed
through non-owning roles rather than through its concrete lifecycle-bearing
implementation. Modules and repositories retain their private collaborators.
`AppDependencies` has no `dispose`, lookup API, ledger, registrar,
configuration aggregate, vendor client, repository, store, module, or BLoC
factory. Graph resource ownership remains unavailable to features and leaf
widgets.

Any internal lifecycle state is a private monotonic guard rather than
presentation state and has no subscribers. A `ChangeNotifier`, `ValueNotifier`,
or third-party observable would expose ownership transitions, introduce
reentrant callbacks, and create another lifecycle without improving the
invariants.

## Build transaction and ownership

The app-local DI mechanism has four core roles:

```dart
abstract interface class AppResourceRegistrar {
  T register<T extends Object>(
    T resource,
    AppResourceDisposer<T> disposer,
  );
}

Future<AppDependencyGraph<T>> buildAppDependencyGraph<T extends Object>({
  required Future<T> Function(AppResourceRegistrar resources)
      dependenciesFactory,
  required AppResourceRollbackFailureCollector captureRollbackFailure,
});
```

`buildAppDependencyGraph<T>` is the one generic construction transaction.
It receives the factory inline as
`Future<T> Function(AppResourceRegistrar resources)`; a public typedef would
add vocabulary without another semantic contract.
`AppDependencyGraph<T>` pairs a typed result with sealed application-resource
ownership. Non-generic `AppDependencyGraphOwner` accepts
`AppDependencyGraph<Object>`, is the only Flutter-aware DI type, and performs
the root-lifecycle handoff. The resource ledger is private: factories receive
only `AppResourceRegistrar`, so they cannot seal, dispose, or inspect lifecycle
state and must not retain the registrar. A stateless builder object and a
public disposal stack would add API without adding responsibility and are not
part of the target.

- Each build creates a fresh private ownership boundary.
- An owned resource is registered immediately after acquisition.
- Borrowed resources and module internals already owned elsewhere are not
  registered again.
- `register` returns the exact supplied instance unchanged.
- Registering the same object identity twice in one graph is rejected; each
  owned object has one cohesive disposer.
- Successful construction seals registration before returning the graph.
- Construction failure attempts every registered disposer in sequential LIFO
  order before rethrowing the primary error.
- The primary failure object and its original stack remain the construction
  result.
- Cleanup failures are immutable secondary data and never replace the primary
  failure.
- Repeated and concurrent disposal return the exact same memoized `Future` and
  invoke each disposer at most once.
- One graph can be claimed by one root owner exactly once; pre-handoff disposal
  prevents a later claim, and graph replacement is rejected.
- Presentation cannot look up dependencies or register resources through the
  graph or its owner.
- Graph primitives remain Flutter-free and independent of diagnostics,
  routing, features, and business packages. Only the root owner imports
  Flutter.

Identity ownership is enforced within one ledger. Detecting the same object in
another independently built graph would require a global registry and is
therefore a composition contract covered by production tests and review. Graph
construction is private; there is no public owned constructor, `seal`,
`isSealed`, resource list, or state getter. Validation failures use static
privacy-safe messages and retain neither rejected resources nor caller
iterables.

The private ledger has only these legal transitions:

```text
successful construction: accepting → sealed → disposing → disposed
construction rollback:   accepting → disposing → disposed
```

It has no observable state. `AppDependencyGraph.dispose()` is a non-`async`
method that returns the memoized completion directly, preserving `Future`
identity. Dependencies remain structurally readable after disposal; revoking
or nulling them would turn lifecycle into observable application state without
making an already-held facade safe. Calling a disposed dependency is a caller
ownership violation and follows that dependency's own behavior.

Graph handoff has two legal pre-owner paths: `unclaimed → claimed` or
`unclaimed → disposalRequested`. Before claim, the composition root is the
only disposal authority. After claim, the root owner is the only production
disposal authority. A pre-handoff disposal request is synchronous and makes a
later claim fail; claim is one-shot and has no replacement transition.

While any app-resource disposer is active, calling `dispose()` on a graph whose
disposal has not started or is still in flight fails synchronously with a
static, privacy-safe `StateError`. A target that has already completed disposal
returns its memoized Future even from that disposer Zone. This prevents direct,
indirect, and independently-started graph disposal cycles without making a
completed target unusable or introducing a public dependency graph. An
external caller outside the disposer Zone always receives the target's
memoized disposal completion. The generic graph does not impose timeout,
cancellation, or retry; each concrete I/O resource owns those policies.

Disposal aggregates contain a shallow unmodifiable snapshot of each original
error object and original stack in actual disposal order. Their stable
`toString()` is privacy-safe, but the contained objects and stacks are
sensitive and can include paths, URIs, or provider data. They never enter UI or
`AppLogger`; a future remote reporter must scrub them. The stack passed with an
aggregate callback is the aggregate throw-boundary stack. There is no synthetic
combined stack; original stacks remain on the individual failure records.

Rollback collection and normal teardown reporting are deliberately different.
During construction, `AppResourceRollbackFailureCollector` and its
`captureRollbackFailure` parameter are a non-reporting secondary collector.
Startup first reports the primary construction failure and only then reports
the collected cleanup aggregate. A broken collector is suppressed so it cannot
escape to the root Zone before the primary error. During normal root teardown
there is no construction primary, so the owner's separate latest accepted
failure callback may report directly; if that callback fails, its failure is
forwarded once to the captured Zone.

During the short pre-UI interval the composition root owns a successfully
constructed graph. Page-catalog or synchronous `runApp` failure reports the
primary failure through a guarded reporter call, awaits graph disposal, reports
any cleanup aggregate, and only then mounts the privacy-safe fallback. Reporter
failure never blocks cleanup. Successful `runApp` hands ownership to
the root lifecycle adapter. Normal widget teardown initiates graph disposal and
offers one aggregate to the latest failure callback.

The owner keeps the last accepted graph, child, and failure callback. Updating
the same graph adopts the new child and callback. An invalid replacement leaves
all previously accepted values intact, and the rejected graph remains owned by
its caller. One-shot claim is an explicit ownership contract rather than an
unforgeable capability: composition and architecture tests ensure no other
production holder disposes a claimed graph. Ownership-token machinery would
add complexity without a current competing owner.

Successful `runApp` return means root attachment was scheduled, not that the
first frame mounted. The scaffold deliberately has no mount completer,
ownership state machine, generic shutdown barrier, or live graph replacement.

A capability with private clients, repositories, subscriptions, or partial
rollback rules is constructed by a cohesive module factory. The application
registrar records only the returned module and exposes only its application
facade. The reference Database→Catalog→Ordering composition remains
explicit. It may be split into private typed subordinate functions only after
size or reuse provides evidence; `lib/app/di/modules` is reserved for concrete
graph-owned technical/platform composition, not arbitrary wiring groups. A
process-root resource stays with its owning capability: the future persistent
support-log adapter belongs under Diagnostics and is not registered merely to
fit every lifetime into the app graph. No universal `Module` interface is
introduced. Do not register process-global
Firebase registries, externally supplied test fakes, or private resources
already owned by a module. If an async module factory allocates internal
resources and throws before returning an owner, it must attempt all internal
cleanup, preserve the primary error and stack, and surface cleanup failures
separately. Foundation resources are created first so LIFO teardown closes
their dependents first.

The reference production composition registers the physical database exactly
once and constructs lifecycle-free Catalog and Ordering facades over borrowed
stores:

```dart
final databaseConfiguration = await createAppDatabaseConfiguration(
  storageNamespace: storageConfiguration.namespace,
);
final databaseModule = resources.register(
  createAppDatabaseModule(configuration: databaseConfiguration),
  (module) => module.dispose(),
);
await databaseModule.initialize();
final databaseStores = databaseModule.stores;
final catalogStores = databaseStores.catalog;

final catalogApplication = createCatalogApplication(
  itemsStore: catalogStores.items,
  categoriesStore: catalogStores.categories,
);
final ordering = createOrderingFacade(
  store: databaseStores.ordering.orders,
  productOffers: CatalogProductOfferAdapter(catalogApplication.productOffers),
  utcNow: () => DateTime.now().toUtc(),
);
```

The application catalog exposes `catalogApplication.facade` and `ordering`
only while they have accepted app-lifetime consumers or an explicitly bounded,
tested consumer gap recorded in the roadmap. The Product Offers view, ACL,
repositories, stores, clock, and database module remain private to composition.

`AppDatabaseStores` is an app-composition-only typed facade. Each context owns
its immutable store bundle and synchronous assembly, while the database module
retains connection lifecycle. The module publishes one stable catalog only
after readiness rather than growing per-store fields/getters or using dynamic
lookup. Bundles are assembled eagerly once, perform no I/O, own no lifecycle,
are narrowed immediately, and never enter `AppDependencies`, presentation, or
business APIs.

The app graph owns the database module. Catalog infrastructure/composition sees
only `CatalogItemsStore` and `CatalogCategoriesStore`; its domain and
application layers do not import the database package. Ordering infrastructure
sees only `OrderingOrdersStore`, and its ACL sees only the Catalog Published
Language.
Presentation sees only `CatalogFacade` or `OrderingFacade`. A repository with
no owned resource is not wrapped in a disposable module merely because more
repositories are added.

The same generic primitives also support a derived feature-layered application:
its app factory may return a typed catalog of app-local application ports
without introducing bounded-context packages. This does not change this
scaffold's boundary: its current `lib/feature` tree is presentation-only, and
business domain/application/infrastructure code remains in real bounded-context
packages. The flat catalog grows by explicit constructor fields. It is not
replaced with dynamic lookup or nested catalogs merely to avoid compile-time
changes.

At the SQLite boundary only primary `BUSY` and `LOCKED` result codes, including
their extended variants, become sanitized temporary
context-owned store failures. Catalog and Ordering share only a private SQLite
classifier; they keep separate public store exception types.
Constraint, corruption, read-only, disk-full, I/O, and programming failures
remain the original boundary exceptions with their original stack traces. A
direct executor therefore preserves its `SqliteException`; a background Drift
executor preserves the outer `DriftRemoteException` and inspects
`remoteCause` only to classify contention.

`AppDatabaseModule` is registered before initialization and owns every executor
returned by the platform connector. Its private lifecycle guard covers one
initialization attempt and idempotent/concurrent disposal; it is not observable
application state. The first disposal request synchronously revokes public
store access, while the memoized asynchronous disposal waits for any in-flight
initialization and then closes the acquired database or executor. This
monotonic ownership guard is not a reason to add a notifier or observable
lifecycle dependency. Native storage uses an absolute host-provided path and
`NativeDatabase.createInBackground`. Web storage rejects Drift's in-memory
fallback. The default policy permits persistent compatibility IndexedDB while
the strict policy also rejects its unsafe multi-tab implementation. Drift
storage enums remain package-internal.

## Environment security

`env/` contains deployment inputs. `lib/app/environment/` contains the
typed runtime model and validation. Flutter dart-defines are public client
data, not a secret store.

`app/environment` is an app-internal subsystem, not a separate package.
Consumers import the exact library they use; a nested dump-barrel would hide
those dependencies without creating an external API boundary. Every Dart file
is already a library and owns its DartDoc. Environment files use the `app_`
prefix so their purpose remains predictable in imports and search results.

Tracked profiles contain only public values:

- `local.env`, `dev.env`, `test.env`, and `prod.env` are committed;
- secrets, private keys, service-account credentials, passwords, and private
  tokens must never be compiled into a Flutter client.

Each profile also supplies a validated `APP_STORAGE_NAMESPACE`. It is distinct
from `APP_ENVIRONMENT`: the integration-test profile intentionally uses local
runtime behavior but a separate physical storage identity. App composition
derives `template_<namespace>` and its native filename, while the Dart-only
database package remains independent of the Environment model. The namespace
is public client configuration and never a secret.

A deployment may supply a different validated profile path when its public
endpoint values differ. Tracking `prod.env` does not make dart-defines a secret
store and does not permit credentials in the file.

Environment validation has two mandatory boundaries:

1. Before compilation, `make check-env ENV_FILE=<path>` validates the exact
   profile supplied to `flutter build --dart-define-from-file=<path>`, including
   its syntax, complete key set, duplicates, empty values, and unknown keys.
2. At application startup, `loadAppStartupConfiguration()` reads only the
   injected compile-time values and passes them through the owning typed
   configuration factories.

The second boundary cannot replace the first: the compiled application cannot
read the source profile or detect unrelated keys that Flutter did not expose to
the typed loader. Every CI/CD build must keep validation and compilation next
to one another and use the same path for both commands.

`AppEnvironmentKeys` is the single Dart source for key wire names and the
required-key set. Profile files, Makefile targets, and CI repeat those names as
external representations and are kept aligned through validation and tests.
Adding an app-owned key requires this complete sequence:

1. Add it to `AppEnvironmentKeys.required`.
2. Read it only in `app_environment_loader.dart`.
3. Add its raw input to `AppStartupConfiguration.fromValues`.
4. Parse it in the narrow owning configuration. Only deployment/framework
   policy belongs in `AppEnvironment`; app-wide storage policy belongs in
   `AppStorageConfiguration`.
5. Add the resulting typed configuration to `AppStartupConfiguration` only
   for a real composition consumer.
6. Update all four tracked profiles.
7. Pass it from `DartDefineFileValidator` through the same typed factory used
   at runtime.
8. Test valid, missing, empty, invalid, and privacy behavior. The invalid-value
   case must prove that CLI validation reaches the owning parser.
9. Run `make check-config`, then validate the exact deployment profile again
   immediately before every CI/CD build.

`AppStartupConfiguration` is a composition-only aggregate. The composition
root immediately narrows it: framework initialization receives
`configuration.environment`, storage composition receives
`configuration.storage`, and neither receives the whole aggregate. It is never
stored in `AppDependencies` or passed to presentation, repositories, or SDK
adapters.

### Adding a package-specific compile-time configuration

A business or infrastructure package owns a configuration only when a real
adapter or application policy consumes it. Do not add an empty configuration
or an unused dart-define merely to reserve an extension point.

For example, if Catalog later gains a remote adapter with a configurable
service endpoint:

1. `packages/bounded_contexts/catalog` defines and tests `CatalogConfiguration.fromValues` and
   a sanitized package-owned exception. The package does not import
   `lib/app/environment`.
2. The application declares the public wire key in `AppEnvironmentKeys` and
   adds it to every complete profile.
3. `app_environment_loader.dart` remains the only production dart-define
   reader and forwards the raw value to
   `AppStartupConfiguration.fromValues`.
4. `AppStartupConfiguration.fromValues` calls
   `CatalogConfiguration.fromValues`; its typed `catalog` field is the only
   package-specific value retained by the startup aggregate.
5. `runApplication` passes `configuration.catalog` to
   `buildAppDependencies`, which immediately passes it to the Catalog module
   factory. No unrelated module receives it.
6. The CLI validator invokes the same composition parser. Because a business
   package must not depend on the app layer, its typed configuration exception
   remains package-owned and is handled explicitly at this outer validation
   boundary.
7. Valid, missing, empty, invalid, privacy, composition-wiring, and
   real-consumer behavior are tested together with the adapter.

The following illustrative code is added only when the remote adapter exists;
it is not part of the current local-only Catalog contract:

```dart
// packages/bounded_contexts/catalog/lib/src/composition/catalog_configuration.dart
final class CatalogConfiguration {
  const CatalogConfiguration._({required this.serviceEndpoint});

  factory CatalogConfiguration.fromValues({
    required String serviceEndpoint,
  }) {
    final endpoint = Uri.tryParse(serviceEndpoint);
    if (endpoint == null ||
        endpoint.scheme != 'https' ||
        endpoint.host.isEmpty ||
        endpoint.userInfo.isNotEmpty ||
        endpoint.hasQuery ||
        endpoint.hasFragment) {
      throw const CatalogConfigurationException(
        CatalogConfigurationFailure.invalidServiceEndpoint,
      );
    }

    return CatalogConfiguration._(serviceEndpoint: endpoint);
  }

  final Uri serviceEndpoint;
}
```

The application then composes, but does not reinterpret, that package-owned
configuration:

```dart
final class AppStartupConfiguration {
  const AppStartupConfiguration({
    required this.environment,
    required this.storage,
    required this.catalog,
  });

  factory AppStartupConfiguration.fromValues({
    required String environment,
    required String urlStrategy,
    required String storageNamespace,
    required String catalogServiceEndpoint,
  }) => AppStartupConfiguration(
    environment: AppEnvironment.fromValues(
      environment: environment,
      urlStrategy: urlStrategy,
    ),
    storage: AppStorageConfiguration.fromValues(
      namespace: storageNamespace,
    ),
    catalog: CatalogConfiguration.fromValues(
      serviceEndpoint: catalogServiceEndpoint,
    ),
  );

  final AppEnvironment environment;
  final AppStorageConfiguration storage;
  final CatalogConfiguration catalog;
}
```

The composition root narrows the value immediately:

```dart
final configuration = loadAppStartupConfiguration();

final graph = await buildAppDependencyGraph<AppDependencies>(
  dependenciesFactory: (resources) => buildAppDependencies(
    resources,
    storageConfiguration: configuration.storage,
    catalogConfiguration: configuration.catalog,
  ),
  captureRollbackFailure: collectRollbackFailure,
);
```

The rollback callback only collects secondary cleanup information. If the
factory fails, startup reports the preserved primary error first and the
collected aggregate second; it does not report from inside the graph
transaction.

`buildAppDependencies` passes `catalogConfiguration` only to the Catalog
composition factory or module. The BLoC receives `CatalogFacade`; it never sees
the endpoint, startup aggregate, repository, or vendor client.

The intended dependency flow is:

```text
dart-define
→ app-owned loader
→ package-owned CatalogConfiguration.fromValues
→ AppStartupConfiguration.catalog
→ Catalog composition/module factory
→ private adapter
```

The following shortcuts are prohibited:

- adding `catalogEndpoint` to `AppEnvironment`;
- passing `AppStartupConfiguration` or `AppEnvironment` into the package;
- exposing a raw string/map configuration to downstream consumers;
- putting a vendor client or configuration in `AppDependencies` without a real
  application-level consumer;
- adding `CATALOG_*` before the corresponding behavior exists.

An architecture test enforces that `app_environment_loader.dart` is the only
production file invoking `String.fromEnvironment`.

Future endpoint types should validate scheme, authority, user info, query,
fragment, and capability-specific path rules without echoing rejected values.
There is one deployment-level `AppEnvironment`; scoped values are named
`<Capability>Configuration`, not `<Capability>Environment`. The owning context
defines its immutable configuration and `fromValues` leaf validation. The app
loader remains the only dart-define reader, concrete vendor objects are built
by context infrastructure/composition, and cross-configuration rules belong in
`AppStartupConfiguration.fromValues` after leaf parsing. `AppEnvironment`
validates only app-owned deployment/framework policy and never imports concrete
assemblies, package configurations, or vendor SDK types.

## Fatal and best-effort initialization

Fatal steps propagate to the startup boundary when the functional graph cannot
operate without them: Flutter binding, a required database engine, or required
Firebase initialization. Binding creation is a configuration-free prelude
inside the guarded root zone. Environment-dependent framework and SDK choices
still execute only after configuration validation.

Environment parsing occurs before any optional remote provider exists. In the
future Persistent Support Log phase it occurs after a bounded app-local storage
attempt, but that store accepts only already approved support-safe projections;
it is neither a reporter nor a remote provider. Startup never forwards rejected
configuration, its raw representation, or an Environment-derived storage name
to logging or reporting.

Best-effort steps catch and safely contain their own failure when functionality
remains available. Optional analytics or remote crash reporting appears only
after its capability decision; a remote reporter must have bounded completion
and must not install duplicate global handlers.

The base scaffold contains no vendor SDK and no artificial initializer list.
The composition root invokes the top-level `initializeAppFramework` function
once. The function is a subordinate operation, not a second composition root,
and does not memoize the call or impose a shared retry and terminal-failure
policy on SDKs that do not yet exist. When a concrete initializer is added, its
documented reentrancy, retry, failure, and shutdown semantics determine the
required guarding policy. Static `AppBootstrap`, `AppLauncher`, and generic
startup coordinator classes are not part of the target.

## Diagnostics and error-handler lifecycle

Application diagnostics belongs under `lib/app/diagnostics`. It has two sibling
subcapabilities, not two architectural layers and not one universal sink:

```text
Operational logging
  AppLogger → synchronous typed breadcrumbs

Error reporting
  AppErrorReporter → asynchronous raw error + nullable original stack

Coordination
  AppErrorBoundary → root Zone and Flutter/platform handler ownership
```

The code is split between `logging` and `error_reporting`, uses point imports,
and has no dump barrel or separate package. `app_logger.dart` contains the
stable `AppLogger` port and the trivial lifecycle-free `NoopAppLogger` null
object. The substantial local projection and `DeveloperAppLogger`
implementation live in the separate `developer_app_logger.dart` point-import
library. Callers constructing that implementation import it explicitly; the
port library does not re-export it. The two subcapabilities remain one app-owned
Diagnostics capability because the boundary coordinates both channels, they
share root-isolate privacy governance, the boundary attempts a safe breadcrumb
before every accepted raw report, and a reporter failure becomes a fixed safe
record. Neither channel acquires the authority of the other.

### Operational log-record SPI

`AppLogger.log` accepts one immutable `AppLogRecord`. The base record is an open
`abstract base class`, and each production record is a final application-owned
subclass that represents exactly one semantic breadcrumb. This class-per-record
model avoids a growing central factory or subtype switch while retaining typed
closed field shapes. Related records are grouped by cohesive app concern; one
class does not imply one source file.

The SPI is open only inside trusted reviewed outer-application code. It is not
a privacy sandbox, plug-in API, domain contract, analytics vocabulary, or
permission for arbitrary features and packages to depend on a global logger.
Domain, inner application layers, and bounded-context packages never import it.
A capability with a real logging need owns a narrower semantic port, and an
app-side adapter translates that call to a concrete app-owned record. The first
real adapter is placed under
`lib/app/diagnostics/logging/adapters/<capability>_logging_adapter.dart`; the
directory and any adapter base do not exist before that consumer. The adapter
may import only the inward semantic port, `AppLogger`, and its concrete records,
and receives no raw failure, arbitrary string, identifier, entity, DTO, or
metadata map. Records do not import features, entities, facades, repositories,
DI, provider SDKs, or bounded-context models. The adapter is stateless,
non-owning, and is not added to `AppDependencies` without a real app-lifetime
consumer. Its exact inward import is admitted by an atomic guard update rather
than a blanket Diagnostics exception.

Each record exposes one static descriptor containing an explicit event name,
positive event-schema version, fixed semantic severity, and fixed data class.
It synchronously projects fields through `AppLogFieldWriter` and returns only
`AppLogProjectionResult.complete`. A production record does not perform I/O,
schedule a Future, Timer, microtask, `.then` callback, or detached work; call a
logger, reporter, Zone, global handler, or store; stringify a payload; or accept
event identity, severity, data class, arbitrary messages, errors, stacks, maps,
lists, configuration, credentials, or caller-defined metadata.

`AppLogFieldWriter` is an `abstract interface class`, not `abstract final`:
production records and test writers live in separate point-import libraries.
Implementing the writer grants no access to a production logger or store;
production `project` calls and collector implementations remain restricted to
the private projection engine and architecture guards.

The typed writer permits:

- `debugType` for debug-only runtime `Type` breadcrumbs;
- `supportFlag` for a boolean;
- `supportCount` for a non-negative JSON-safe integer;
- `supportDuration` for a non-negative JSON-safe microsecond duration;
- `supportCode` for a reviewed low-cardinality `AppLogStableCode`.

Support fields never contain arbitrary strings, entity/account/device/session/
tenant identifiers, URLs, paths, queries, objects, collections, DTOs, errors,
stacks, runtime types, or credentials. Syntax validation of a stable code does
not prove that it is free of personal data; production record definitions are
trusted reviewed code.
Absence is represented by an omitted field or a different record type, not a
nullable metadata bag.

Validation requires a lower-case dotted ASCII event name of at most 96
characters, a positive 31-bit version, a unique `(eventName, eventVersion)`
pair, lower-snake-case field names of at most 48 characters, at most 32 fields,
no duplicate field name, and an uppercase tokenized stable code of at most 64
characters. Invalid projection rejects the entire record atomically.

Diagnostics Core validates this synchronous schema and its typed bounds. The
4-KiB limit belongs to the future Persistent Support Log phase because it is
defined over the complete canonical persisted UTF-8 line, including its
storage envelope and final LF. Core neither has that envelope nor claims to
enforce its encoded size early.

### Privacy profiles and local projection

Build privacy is physically clamped as `kDebugMode && testOverride`: a test
seam may disable debug detail but cannot enable it in profile or release.
`kReleaseMode` is not used to select diagnostic detail.

- A `debugOnly` record is discarded before `project` outside debug and never
  enters developer output or future support history.
- A `supportSafe` record projects approved support fields in every mode. Any
  additional debug `Type` fields are rendered only in debug and are neither
  stored nor retained outside it.
- `supportSafe` means eligible for bounded local support history under this
  policy. It does not mean anonymous, remotely cleared, consented,
  audit-grade, or suitable for analytics.

The built-in logger reads and validates the descriptor, invokes `project`
exactly once, creates one immutable defensive projection, rejects it atomically
on any failure, and tombstones its temporary writer in `finally`. A retained
writer silently ignores later calls and does not retain a logger, store,
callback, mutable buffer, or debug `Type`. The logger contains synchronous
descriptor, projection, validation, formatting, and sink failures. It cannot
contain failures that occur before `log`, a hostile infinite loop or detached
task, OOM, or VM/native fatal termination.

`AppLogger.log` remains a synchronous `void` port. Implementations do not mark
it `async`, reenter themselves, invoke `AppErrorBoundary` or
`AppErrorReporter`, or install global handlers. Validation, projection, and a
synchronous sink or enqueue handoff complete before return, and no failure
escapes the caller. A future persistent module may start only a module-owned,
tracked, fully contained drain after enqueue; detached work remains forbidden.
This reviewed implementation contract and its source/AST guards are preferred
to a result sentinel, which would break callers without preventing arbitrary
scheduling.

`DeveloperAppLogger` writes through `dart:developer.log` without raw `error` or
`stackTrace` arguments and maps `info`, `warning`, and `error` to levels 800,
900, and 1000. It never calls `record.toString()`. `NoopAppLogger` returns
without reading the descriptor or projecting the record. Recording loggers and
field writers are test-only. The private collector, normalized projection,
validation, formatting, and developer sink remain in the same Dart library as
`DeveloperAppLogger`: extracting them now would require `part` files or public
internal types without a second production consumer. When persistent logging
is accepted, the engine is reviewed and extracted atomically only as needed so
developer output and support recording can consume one normalized projection
created by one `project` call. It never becomes a public formatter, sink,
visitor, or serializer registry.

Diagnostics Core contains exactly this record vocabulary:

| Record class | Event | Version | Data class | Severity | Fields |
|---|---|---:|---|---|---|
| `AppBlocCreatedLogRecord` | `app.bloc.created` | 1 | debugOnly | info | `component_type` |
| `AppBlocEventLogRecord` | `app.bloc.event` | 1 | debugOnly | info | `component_type`, `event_type` |
| `AppBlocStateChangedLogRecord` | `app.bloc.state_changed` | 1 | debugOnly | info | `component_type`, `previous_state_type`, `next_state_type` |
| `AppBlocActionLogRecord` | `app.bloc.action` | 1 | debugOnly | info | `component_type`, `action_type` |
| `AppBlocErrorBreadcrumbLogRecord` | `app.bloc.error_breadcrumb` | 1 | debugOnly | warning | `component_type`, `error_type` |
| `AppBlocClosedLogRecord` | `app.bloc.closed` | 1 | debugOnly | info | `component_type` |
| `AppErrorReportedLogRecord` | `app.diagnostics.error_reported` | 1 | supportSafe | error | `report_code` |
| `AppErrorReporterFailureLogRecord` | `app.diagnostics.reporter_failed` | 1 | supportSafe | error | `support_code = APP-REPORT-001` |

The Startup phase later adds `AppStartupStartedLogRecord`
(`app.startup.started`, no fields) and `AppStartupCompletedLogRecord`
(`app.startup.completed`, non-negative `duration`). Both begin at event version
1. They are not part of
Diagnostics Core and are not added merely to anticipate a caller. A negative
duration is rejected by the later record constructor with a static privacy-safe
message.

Event-schema, persisted-entry, exported-NDJSON, and backend-layout versions are
independent namespaces. An event version changes when a persisted field's
name, type, meaning, requiredness, support classification, severity semantics,
or descriptor meaning changes. An old `(name, version)` pair and a removed name
never acquire a new meaning. A debug rendering change need not version a record
that is never persisted.

### Error reports and report kinds

`AppErrorReportKind` is a closed taxonomy of root and orchestration ingress,
not a list of feature failures. It is neither severity, expectedness, retry
policy, analytics dimension, remote-provider eligibility, nor an
`AppLogRecord`. Feature-specific expected failures do not extend it.

| Kind | Wire value | Support code | Label |
|---|---|---|---|
| Root Zone | `root_zone` | `APP-ROOT-001` | `Root zone` |
| Environment | `environment` | `APP-ENVIRONMENT-001` | `Environment` |
| Startup | `startup` | `APP-STARTUP-001` | `Startup` |
| Flutter framework | `flutter_framework` | `APP-FRAMEWORK-001` | `Flutter framework` |
| Platform dispatcher | `platform_dispatcher` | `APP-PLATFORM-001` | `Platform dispatcher` |
| DI rollback | `dependency_rollback` | `APP-DI-ROLLBACK-001` | `Dependency rollback` |
| DI disposal | `dependency_disposal` | `APP-DI-DISPOSE-001` | `Dependency disposal` |

`AppErrorReporter.report` returns strict `Future<void>` for all work it starts
and accepts the raw error, its nullable original stack, and one
`AppErrorReportKind`. Calls may proceed independently and concurrently. The API
does not promise ordering, serialization, acknowledgement, retry, queueing,
deduplication, cancellation, or flush, and accepted implementations create no
floating work or global handlers.

`LocalAppErrorReporter` receives its formatter by constructor, formats and
invokes its developer sink synchronously, then returns a completed Future. A
synchronous sink failure becomes a failed Future with the original sink stack.
It never passes raw `error` or `stackTrace` arguments to
`dart:developer.log`. `NoopAppErrorReporter` and test-owned recording reporters
complete the accepted Core implementations.

The formatter enables detail only under `kDebugMode`. Profile and release
return only the exact static code and English label, without reading
`error.runtimeType` or invoking `error.toString()` or
`stackTrace.toString()`. Debug may add `error.runtimeType` and a guarded
rendering of a supplied stack, but not the error's string representation. A raw
debug stack can contain paths and URIs and is sensitive local detail, not
sanitized or remote-ready data. An absent stack remains absent; no
`StackTrace.current` is fabricated. Retired support codes are never reused with
a different meaning.

### Root error boundary

`AppErrorBoundary` borrows its logger and reporter and never closes them. It
owns one guarded Dart application Zone plus `FlutterError.onError` and
`PlatformDispatcher.onError` for the root Flutter application isolate. It does
not claim child-isolate, OOM, VM/native-fatal, arbitrary browser-JavaScript,
pre-boundary, or already caught failure coverage. On Flutter 3.47 Web the
platform callback is not a complete browser error channel, so the guarded root
Zone remains mandatory ([Flutter issue 100277](https://github.com/flutter/flutter/issues/100277)).

The public `run` is `void`: it claims one isolate-local active-owner lease,
installs handlers inside `runZonedGuarded<void>`, and invokes the asynchronous
body with `unawaited`. The body's Future never crosses the error-zone boundary.
Binding initialization and `runApp` later execute inside that body. Startup
sets `BindingBase.debugZoneErrorsAreFatal = true` before creating the binding in
debug.

Boundary lifecycle is private and monotonic: `created → active → disposed` or
`created → disposed`. A competing boundary changes no handlers and remains
usable after the winner is disposed. Repeated `run` and `run` after disposal
fail with static messages. Installation failure performs identity-safe
rollback, releases the lease, and leaves that instance terminal.

Direct explicit `report` is independent of the handler lease. It is permitted
while the boundary is `created` or `active`, does not install handlers, and
does not change lifecycle state; automatic error coverage still begins only in
`run`. After disposal, deliberately starting new reports is a caller violation,
but an unavoidable late callback remains best-effort/no-throw and carries no
delivery, availability, ordering, or flush guarantee.

Previous Flutter and platform callbacks are captured only for identity-safe
restoration. They are never invoked and never receive an original or surrogate
failure. Disposal restores only a callback still identical to this boundary's
wrapper and does not overwrite a later foreign handler. Platform restoration
runs in the caller Zone captured by `run`, because the setter captures
`Zone.current`; an arbitrary Zone in which a third-party handler was installed
cannot be reconstructed. Vendor automatic global handlers must not compete
with the application boundary.

Production retains the boundary for the application-isolate lifetime. Tests
dispose it only after quiescence. Disposal is idempotent but does not cancel the
root Zone, await in-flight reports, flush a provider, or stop callbacks retained
by older tasks.

The platform wrapper always returns `true` so an embedder fallback cannot print
the raw failure. This means application policy accepted the error, not that a
report was delivered. A Flutter detail's supplied nullable stack is forwarded
unchanged. Silent Flutter details are reported by default only in debug; any
future remote provider must review that policy explicitly. Application code
does not call `FlutterError.presentError`, `exceptionAsString`, `print`, or
`debugPrint`.

For each normal `report` call the boundary:

1. checks its private per-boundary logger invocation marker and silently
   suppresses logger-induced reentry;
2. checks its distinct reporter invocation marker and reduces reporter-induced
   reentry to at most one reporter-failure record;
3. best-effort logs one `AppErrorReportedLogRecord` containing only the kind's
   support code;
4. invokes the raw reporter;
5. reduces synchronous or asynchronous reporter failure to at most one
   `AppErrorReporterFailureLogRecord`.

Both keys are private per-boundary objects, so unrelated boundaries and normal
concurrent reports remain independent. Boundary-owned record construction and
`logger.log` execute inside a guarded child Zone carrying the logger marker;
synchronous and inherited-async logger failures are suppressed without calling
the reporter or manufacturing `APP-REPORT-001`. This defense does not permit an
`async void` logger. The reporter marker retains the existing direct and
inherited-async A→B→A containment. Logger failure never blocks the raw reporter,
and reporter or logger failure never replaces the primary failure. Neither
marker claims to contain detached reporter work or unrelated engine callbacks.
Global ingress uses `unawaited(report(...))` only because `report` contains all
of its own failures. Independent ingress has no ordering guarantee. Explicit
Startup/DI orchestration may await the primary report and then the captured
rollback aggregate to preserve primary-first order.

`AppBlocObserver` receives `AppLogger` through its constructor and emits the
six debug-only record types from `onCreate`, `onEvent`, `onChange`, `onAction`,
`onError`, and `onClose`. It does not log `onTransition`, because `onChange`
already covers both Bloc and Cubit without duplicate state records. Records are
constructed only in debug; the logger independently drops them before
projection outside debug. Payloads are never stringified, the observer never
invokes the reporter, and a hostile logger cannot prevent the required super
callback.

Exactly-once is deliberately narrow: one non-suppressed boundary ingress calls
the reporter at most once. There is no identity deduplication across Zone,
Flutter, and platform channels. One uncaught reference Bloc handler failure
creates one observer breadcrumb and one root report. Manual `addError` may
create only a breadcrumb, while a Cubit failure may reach root without one.

Expectedness belongs to each operation contract, not to Dart's `Exception`
marker. Presentation catches only exact documented application failures.
Unknown exceptions, `Error`, data-integrity failures, and invariant failures
remain unexpected. An adapter translates only a recognized provider condition
to its owner-specific failure while preserving the original stack. Propagating
the same object uses `rethrow`; handled expected failures are not reported
automatically.

### Future persistent support log

Persistent support history is a later Storage phase, not part of Diagnostics
Core. It adds `AppLoggingModule` under
`app/diagnostics/logging/support_log`, with separate borrowed `AppLogger` and
least-authority `AppSupportLogExporter` roles. Its constructor performs static
validation and memory allocation only. It captures an exclusive same-isolate
logging lease before observable effects, but exposes no static current-module
getter, registry, lookup, or lifecycle authority through its roles.

Its public shape is deliberately small:

```dart
enum AppLogPersistenceMode { persistent, memoryOnly }

abstract interface class AppSupportLogExporter {
  Future<AppSupportLogSnapshot> exportSnapshot();
}

final class AppLoggingModule {
  AppLogger get logger;
  AppSupportLogExporter get supportLogExporter;
  Future<AppLogPersistenceMode> activatePersistence();
  Future<void> dispose();
}
```

`AppSupportLogSnapshot` contains only `ndjson`, `mediaType`, and
`suggestedFileName`. Logger and exporter role objects may retain the private
engine but expose no activation, disposal, or lookup authority.

The composition root owns the module outside `AppDependencyGraph`. Logging must
remain available for Environment failure, graph-construction rollback, graph
disposal failure, and final controlled teardown; graph ownership would close it
too early. This is a narrow lifetime exception, not permission for arbitrary
root resources. The lifecycle-bearing module never enters `AppDependencies`;
the exporter role enters only with a real Support UI consumer. Widgets do not
close the module, and production normally has no awaited process shutdown.

The module begins as a bounded memory recorder. `activatePersistence()` and
`dispose()` publish their memoized Future before any provider callback and set
their request state synchronously. Activation never exposes a raw failed Future
and resolves only to `persistent` or `memoryOnly`; it is not a Startup readiness
gate. Dispose wins once requested, prevents new activation and export, drops
later logs, contains provider failures, and completes after cleanup or bounded
abandonment rather than promising durable flush. An open that completes after
disposal closes its handle and cannot attach. All late provider completions are
generation/state guarded and cannot resurrect public state.

Its internal lifecycle is:

```text
buffering → activating → persistent
                       → memoryOnly
persistent → memoryOnly

buffering/activating/persistent/memoryOnly
  → disposalRequested → disposed
```

`activatePersistence()` is non-`async` at entry. Its first valid call publishes
one Future before invoking a provider; repeated valid callers receive that
identical Future. A first call after disposal request fails synchronously with a
static message. Disposal before activation wins. Activation before disposal may
finish only as `memoryOnly` if the request prevents attachment; any late opened
handle is closed. `dispose()` is likewise non-`async` at entry, publishes one
identical Future for repeated callers, makes later logging a silent drop, and
makes new activation or export fail synchronously with static messages.
Public state becomes `disposed` before the shared disposal Future completes. A
clean quiescent disposal releases the lease; a still-running timed-out provider
operation keeps it poisoned until that operation can no longer race a new
module.

Provider open, write, prune, flush, and close operations default to two-second
bounds; one export has a five-second whole-operation budget. `Future.timeout`
does not cancel underlying work. A controlled disposal gives an already
accepted export up to five seconds and cleanup up to two more, for a seven-
second hard public bound. If a timed-out provider operation is still alive, the
same-isolate lease remains poisoned until safe completion rather than allowing
a second writer over the namespace. Controlled shutdown therefore requires:

```text
quiesce application work
→ await graph disposal and every explicit report
→ establish boundary/report/export quiescence
→ dispose the boundary
→ await logging-module disposal
```

The Startup phase first introduces the transitional seam of one logger, one
reporter, and a narrow boundary factory. The Storage phase atomically replaces
the logger seam with one optional `AppLoggingModule`; the boundary factory must
receive the exact module logger and selected reporter, and no independent
logger may create split-brain composition. The final order is module
construction, fixed local reporter and boundary construction, boundary run,
debug zone-mismatch policy, binding creation, unawaited owned non-failing
persistence activation, Environment loading, Environment-dependent SDK work,
graph and UI composition, then `runApp`. The fixed storage namespace is
app-owned and never derived from rejected Environment values.

Each accepted support-safe record is synchronously normalized to immutable
fields, UTC time, a private random 128-bit writer-instance ID, and monotonic
sequence before an async boundary. The ID is for store idempotency only; it is
not a user/device/session identifier and is never exported. Failure to create
it safely keeps persistence in memory-only mode. Recent history holds 256
entries. Total uncommitted work, including an in-flight immutable batch, is at
most 256; a batch is at most 32. Overflow drops the oldest non-in-flight entry.
Counters do not consume queue slots, and one serialized tracked drain Future
replaces periodic timers, blind retries, sampling, or deduplication. Unknown
commit outcome is not blindly retried; the store uses `(writerInstanceId,
sequence)` as an idempotent logical key.

The initial reviewed logical bounds are 4 KiB per complete canonical persisted
line, 2 MiB and seven days retained encoded data, 2 MiB per exported snapshot,
256 KiB per native segment, and eight native segments total including active.
The byte bounds measure UTF-8 encoded entries, not filesystem or IndexedDB
overhead; the byte cap is hard while age pruning is opportunistic under clock
skew. The initial phase keeps these reviewed constants in source rather than
adding a runtime configuration hierarchy.

Native persistence is segmented append-only NDJSON in the application cache
or no-backup location. It uses streaming bounded reads, closes before rename,
prunes before append/rotation, skips corrupt full lines and an incomplete crash
tail, repairs only exact owned filenames, and never deletes unknown files.
`flush` is best effort and does not claim physical `fsync` durability. Web
persistence uses exact-pinned `idb_shim` and IndexedDB, not `localStorage`;
append plus oldest pruning shares one read-write transaction whose completion
is awaited. Browser eviction, private mode, quota, blocked open, and
`versionchange` degrade or close safely. No root module coordinates native
multi-process writers, child isolates, Web tabs, or a shared-origin multi-app
namespace.

Open, write, prune, or unusable-connection failure terminates persistence for
that run and degrades to memory. One corrupt stored entry or export-only read
failure does not automatically disable a healthy writer. Store failure never
enters the boundary or reporter, is never stringified or retried, and creates
at most one fixed `app.diagnostics.support_log_unavailable` /
`APP-SUPPORT-LOG-001` health entry plus an exact out-of-band counter. Invalid
application records similarly produce at most one private
`app.diagnostics.log_record_rejected` / `APP-LOG-001` health entry; overflow is
a counter, not a recursive record. Failure handling first marks persistence
terminal, detaches the target, clears pending work and updates loss counters,
then adds the fixed memory health entry and attempts fixed developer output.
These engine entries are not public record classes and never re-enter
`AppLogger`.

Export captures its writer watermark and retained ring references
synchronously, then within five seconds drains toward that watermark, reads a
transactional store snapshot, structurally validates and re-encodes entries,
merges and deduplicates by the private logical key, excludes current-writer
entries above the watermark, and selects the newest events that fit 2 MiB. The
final NDJSON is chronological and contains a canonical header, event records,
UTF-8 LF separators, and a final LF. The header reports format, creation time,
mode/degradation, record and loss/corruption/omission counters. It is
recalculated after trimming; the private writer ID is not exported. Concurrent
calls have distinct watermarks and Futures but execute serially.

The snapshot has media type `application/x-ndjson`, suggested filename
`app-support-log.ndjson`, and a hard two-MiB UTF-8 limit including the header and
final LF. Its header contains only snapshot-format version, UTC creation time,
persistence mode/degraded status, final record count, persistence-drop count,
rejected-record count, corrupt-record count, and omitted-for-size count. Each
record line contains entry-format version, event name and schema version,
severity token, UTC event time, snapshot-local ordinal, and typed support
fields. Canonical key ordering is golden-tested; store commit order and current-
run sequence, not timestamp, determine order.

An exporter creates an in-memory snapshot only. It does not save, share,
upload, purge, or enter `AppDependencies` before a real support workflow. Since
there is no central historical schema registry, restart validation is
structural and cannot promise semantic re-scrubbing. The snapshot is
operational and potentially personal data, not an audit log or
cryptographically protected record, and leaves the app only through an
explicit user support workflow. Public purge, account correlators, automatic
upload, encryption, compression, sampling, remote providers, support UI,
child-isolate forwarding, multi-process/tab coordination, and controlled
production shutdown each remain separate gates recorded in the roadmap.
Before introducing an account/device/entity correlator, logout/erasure policy,
or automatic upload, the application must accept a separately owned public
purge capability and its policy; bounded retention is not a substitute.

The selected shape deliberately rejects several superficially simpler
alternatives. A central sealed record union would make every new app breadcrumb
edit one subtype catalog; an open marker plus sink pattern matching would lose
unknown fields or require every sink to change. A universal `DiagnosticSink`
would merge synchronous support-safe records with asynchronous raw sensitive
failures. A generic `AppErrorPolicy`, middleware pipeline, appender registry,
or metadata bag would create policy and extension machinery before a provider
exists. The support history does not use the business database, where it would
be unavailable during database failure, or a second Drift database, whose
schema/codegen/Web cost is disproportionate to bounded append-only history.
Graph ownership and graph-to-root relays are rejected because they close or
detach the recorder before final graph diagnostics. These decisions are
revisited only when their named capability gates produce a concrete driver.

The accepted boundary remains backed by one fixed local or no-op reporter for
its whole lifetime. A remote provider requires an ADR covering post-Environment
activation, eligibility, consent, governance, scrubbing, timeout, recursion,
retry and delivery, flush, shutdown, ownership, and reporter handoff without a
second global handler. No mutable registry or delegating placeholder is created
in advance. Analytics remains a different capability with its own typed
vocabulary, classified properties, consent, governance, cardinality limits,
provider serialization, constructor injection, and provider-owned lifecycle.
An analytics event is not an `AppEvent`, `AppLogRecord`, domain event, or
integration event.

A privacy-safe localized `ErrorWidget` policy waits for Presentation/Startup.
Child-isolate roots and error-port forwarding wait for the first isolate
workload; browser-level JavaScript capture waits for a Web diagnostics
provider; controlled awaited shutdown waits for a real desktop or restart use
case. None is scaffolded by Diagnostics Core.

## Feature DI lifetime

1. Use a feature-owned Page definition with direct constructor injection when
   wiring is used once.
2. Use a Factory Scope when the same construction policy is reused by a
   subtree or several screens.
3. Use a flow-shell `BlocProvider` when one BLoC instance must span routes.

A Factory Scope receives only narrow dependencies and exposes construction
policy. It never receives `AppDependencies`, creates a BLoC from `build`, embeds
`BlocProvider`, or owns the returned instance. `BlocProvider(create: ...)`
below the Scope remains the instance owner.

The root graph owner has no dependency lookup API. `app_pages.dart` narrows
`AppDependencies` into feature Page definitions; those definitions pass ports
to feature scopes and BLoCs through constructors. Do not invent a dependency
or app-level factory solely to demonstrate DI.

`DemoScope` captures the constructor-injected graph-owned event bus in its
feature-local BLoC factory and leaves instance lifecycle to
`BlocProvider(create: ...)`.

`ActivityScope` demonstrates screen lifetime. Its Page definition injects the
event bus, and `BlocProvider` owns `ActivityBloc` and its EventBus subscription
when the screen leaves the tree. An event published before Activity opens is
intentionally absent because the bus has no replay. If Activity required
authoritative current data or history, the graph would expose an app-lifetime
repository/store with `current + Stream` instead.

`NotFoundScope` and `StartupFailureScope` are intentionally minimal scaffold
extension points. Each creates a screen-lifetime BLoC through
`BlocProvider(create: ...)`, which owns and closes the instance. Their sealed
event bases have no concrete events until real recovery behavior appears; this
preserves the lifecycle boundary without inventing fake use cases. The startup
scope is additionally pre-DI: it receives only a safe diagnostic code and
cannot read the graph lifecycle owner, normal routing, or `AppEventBus`.

Widget teardown cannot be awaited by Flutter and mobile process termination
may skip it entirely. A BLoC starts subscription cancellation before its first
asynchronous gap. Required persistence and business completion remain awaited
inside the repository or use-case operation and never move into `close()`.

`Factory<T>` and `ParamFactory<T, P>` are shared function-type vocabulary, not
app-level dependencies. A factory defines how feature composition creates an
object; the caller owns the returned instance. `Factory<T>` fits construction
without runtime input. `ParamFactory<T, P>` fits a route ID or argument while
the closure captures infrastructure dependencies. Use a record or immutable
parameter object when several values are needed rather than adding numbered
factory typedefs. BLoC factories remain in feature DI and `BlocProvider(create:
...)` owns the instances they return.

### Catalog and Order Composer presentation

The Catalog feature ultimately exercises its complete public facade: item and
category observation, draft creation and editing, category activation,
publication, published-offer editing, archival, draft deletion, and explicit
watch retry. Expected command failures are operation-specific ephemeral
actions. Watch failure or completion is persistent unavailable state. Value
Object constants provide UI guidance, but each facade command validates raw
input again. Presentation catches only the expected types documented for that
operation; data-integrity and unexpected failures reach the root boundary.

The reference Ordering UI is the app-level `feature/order_composer` workflow,
not a third bounded context. It receives `CatalogFacade` for published-product
discovery and `OrderingFacade` for Order behavior through Page composition.
Catalog and Ordering themselves remain independent. The workflow provides an
Order list and `/orders/:orderId` draft editor, creates persistent drafts,
selects published products and quantities, replaces the whole line set, places
or cancels an Order, and renders committed state only from Ordering watches.
Ordering still repeats the authoritative Product Offers query through its ACL
before mutation; presentation discovery never substitutes for that check.

`OrdersBloc` owns list/create behavior. `OrderComposerBloc` owns one selected
Order, product selection, quantities, replace/place/cancel commands, and its
watch subscriptions. The useful `OrderId` result from `createDraft` is carried
by a same-feature ephemeral navigation action, not AppEventBus.

### Localization

The application uses Flutter generated localization with a root `l10n.yaml`
and one canonical English ARB baseline. Product keys are feature-owned through
stable prefixes such as `catalog`, `orders`, `orderComposer`, `activity`,
`demo`, `notFound`, and `startupFailure`. Normal and startup-failure app shells
install the same generated delegates.

Business packages remain Flutter-free and never return localized exceptions.
UI kit owns visual semantics, not product vocabulary. Adding another locale or
persisted locale selection is a product capability and does not change
business APIs.

### UI kit

The target `packages/libraries/ui_kit` is a reusable Flutter library that owns
Material 3 theme assembly, light/dark/system theme policy, semantic
`ThemeExtension` tokens, component themes, and the shared accessibility
baseline. It has no product vocabulary or business model. Its autonomous
package patch proves WCAG 2.2 AA contrast, 48dp targets, unrestricted scaling,
200% and 320% layout behavior, reduced motion, and system-font compatibility.

The root application adds a direct dependency only with the first accepted
shell consumer. Normal and StartupFailure shells use the same theme assembly;
feature-specific widgets do not move into the UI kit merely because they can
be reused twice inside one product workflow.

## Interaction channels and delivery semantics

| Need | Mechanism | Guarantee |
|---|---|---|
| UI intent for one BLoC | BLoC event | Local presentation-state-machine input |
| Current presentation data | BLoC `State` | Authoritative for that BLoC's current UI |
| One-shot effect for the same UI | `EphemeralBloc` action | Best-effort and not persistent state |
| Optional cross-feature notification | `AppEventBus` | In-process best-effort, no replay or acknowledgement |
| Confirmation of a local commit | Command `Future<void>` | Success or a typed failure to the direct caller |
| Useful payload for the direct caller | Application result | Synchronous call contract, not an event |
| Current data from another context | Narrow query port + Published Language + ACL | Request/response with an explicit availability contract |
| Required synchronous work in another context | Application workflow + narrow command port | Awaited response; no implied distributed transaction |
| Independent reaction inside one domain boundary | Context-owned domain event | Policy chosen with its first real handler |
| Committed fact that must not be lost | Versioned integration event + durable delivery | Outbox, relay, and idempotent consumption |

```text
Demo input event
  ├── DemoState                         current UI data
  ├── DemoAction                       same-feature one-shot UI command
  └── DemoActionCompletedAppEvent      cross-feature best-effort fact
```

The similarly named concepts have different ownership and delivery semantics:

- a BLoC event is an input to one presentation state machine;
- an `EphemeralBloc` action is an output to that same feature's UI and avoids
  encoding a one-shot effect in persistent state;
- an app event is an app-owned best-effort notification sent to current
  independent feature subscribers through `AppEventBus`;
- a normally completed command Future proves commit without inventing a
  payload; an application result is added only when a caller needs returned
  data that is not appropriately obtained from authoritative observation.

Transport is selected after the business guarantee. A synchronous query,
command result, and DTO are not events. Published Language classifies a shared
contract vocabulary; it does not prescribe a Dart call, HTTP, a broker, or a
delivery guarantee. An application result must not be published through
`AppEventBus`.

A domain event appears only with a real independent reaction in its owning
bounded context. The first such event must decide whether dispatch occurs
before or after commit, whether a handler participates in that transaction,
how handler failure affects the command, whether duplicates or loss are
allowed, and whether a separate integration message is needed. Until then,
direct calls keep invariants explicit and no global `DomainEvent` hierarchy or
dispatcher exists.

A DDD integration event is a separately versioned wire contract for a
committed fact and never extends `AppEvent`. When delivery is required, the
business write and outbox record are committed together, a relay performs
at-least-once delivery with retry and monitoring, and the consumer is
idempotent. An inbox is one possible deduplication mechanism, not a universal
requirement. Outbox storage alone does not constitute delivery.

Persistent state is reconstructable and rendered by `BlocBuilder`. An
`EphemeralBloc` action is delivered to the same feature UI without adding a
temporary state flag or reset transition. It does not mutate BLoC state and
therefore does not by itself rebuild a `BlocBuilder`. Actions are not replayed
and must not represent required work.

Catalog applies this distinction explicitly. Loss or normal completion of its
authoritative `watchItems()` subscription is persistent unavailability and
keeps the last snapshot in state with a retry path. An expected failure of one
add/update/delete command is a one-shot action. Retry owns at most one active
subscription, while data-integrity and other unexpected failures propagate to
the root error boundary instead of becoming ordinary UI state.

An `AppEvent` is delivered to any current typed subscriber without the producer
knowing its concrete consumers. `AppEventBus` removes direct BLoC-to-BLoC
references, not semantic coupling. Application-wide best-effort notifications
live in `app/events`; this catalog contains only `AppEvent` contracts, never
internal BLoC events, UI commands, current state, durable integration events,
or required-workflow messages. Central placement prevents event contracts from
being scattered among producer and consumer features and avoids a Demo ↔
Activity dependency cycle. The domain-neutral bus and base event type remain
in `core/event_bus`.

Activity is intentionally a non-authoritative screen-lifetime projection. A
late subscriber misses earlier Demo events, sequences may contain gaps, and
recreating the screen starts a new observation window. This reference must not
be copied for audit, billing, business counters, or any invariant. Code review
must ask what happens if a proposed notification is lost; if the answer is a
business inconsistency, `AppEventBus` is the wrong mechanism.

Navigation is a separate channel. `ActivityNavigation` lives in
`app/routing` because it is an application-UI capability, not a
low-level core concern. `AppNavigator` adapts that narrow contract to the
concrete Activity route. Demo and Activity can therefore share semantics
without importing one another or sending navigation through the EventBus.

Neither action stream nor event bus has replay or durable delivery. When a
consumer needs the current value or cannot miss an update, use an owned
repository, service, or application store exposing current state and a stream.
Navigation, SnackBars, dialogs, focus, and clipboard commands never travel over
the event bus. Consumers translate bus facts into internal BLoC events and
cancel subscriptions in `close()` before application graph teardown. The
disposal stack closes the app-owned bus last.

The global BLoC observer logs only BLoC, event, state, and action runtime types.
It never stringifies payloads or `EphemeralBlocChange`.

## Typed routing

The package dependency is pinned to `rolter: 0.2.0`. `App` creates and disposes
the route state and delegate; routing objects do not enter `AppDependencies`.
`App` receives one synchronous, non-owning `RouteNodePageBuilder<AppRoute>`
Strategy from application composition.

Feature routes are data-only `RouteNode` values. Each feature owns its route,
`*RouteName` enum, strict decoder contribution, typed Page definition, feature
DI, and view. A route enum's `value` is the single source for both the
route name and decoder key. Every Page uses `route.pageKey`, and the page
catalog dispatches by exact route runtime type rather than route value.

Every Flutter Page adapter uses the single predictable path
`feature/<name>/routing/page_composition/<name>_route_page.dart`. Other routing
files remain presentation-free. The adapter may import its route, Scope, and
screen; it must not import the BLoC library, start I/O, navigate, or own a
resource.

`app_route_page_definition.dart` owns the Page-contribution SPI and its typed
adapter. `app_route_page_catalog.dart` owns only indexing, duplicate rejection,
and runtime dispatch. The interface and typed adapter stay together as one
contract; the application catalog changes for a different reason.

Application routing deliberately has two composition responsibilities:

- `app_route_registry.dart` validates and merges decoder maps, selects
  fallback, and owns initial-stack/normalization policy;
- `app_pages.dart` maps the dependency catalog to narrow feature Page
  contributions.

These catalogs change for different reasons and are not merged into a module
registry or `AppRoutingConfiguration`. Checked decoder composition rejects a
duplicate route value before app-owned resource construction; the composition
root explicitly evaluates the otherwise-lazy registry before building the
graph.

`AppRoutePageCatalog` rejects duplicate route types during construction. A
missing Page definition fails safely when the route is first rendered;
contract tests enumerate every supported route type instead of adding
descriptors or code generation.

`AppNavigator` implements narrow contracts such as `ActivityNavigation` and
maps them to concrete feature routes without exposing those route classes to
callers. Invalid external values are reported through an injected
`AppRouteFallbackBuilder` as a safe `AppRouteFailureReason`. Feature decoders
therefore do not import NotFound. Application registry fallback maps that
reason to `NotFoundRoute`; the feature's Page contribution renders it. The
route is excluded from history and stores no attempted URI or query value in
params, state, page keys, logs, or UI.

Startup failure follows a separate path because the normal graph may not
exist. `StartupFailureApp` is a thin `MaterialApp` wrapper around
`StartupFailureScope → BlocProvider → StartupFailureScreen`. It accepts only a
safe diagnostic code and never provides raw errors, stack traces, environment
values, normal graph services, or a generic retry of framework initialization.

`NavigatorScope` stays above `MaterialApp.router` so routed pages can resolve
the navigator facade. A Page definition may wrap its screen with feature DI. A
flow scope belongs above only the routes that truly share one session BLoC; the
base app does not install such a scope speculatively. Page builders may run
repeatedly and must not start I/O, navigate, mutate route state, or create
unowned disposable resources.

The target reference routing phase starts with a flat two-route tree and the
default `TreeUrlCodec`.
Nested navigation, guards, and public-URL custom codecs remain supported
extension points but are not instantiated without a real requirement.

Navigation APIs have two intentionally different ownership models:

- `DemoNavigation` is feature-owned. Its `toDemo()` operation performs a full
  stack reset and may be used by Demo or application composition that
  intentionally depends on Demo. Unrelated features must not import it.
- `ActivityNavigation` is application-owned. It is a narrow cross-feature
  capability that lets a caller open Activity without importing Activity's
  route or implementation.

The absence of a production caller does not by itself make a documented
template extension point dead code. The scaffold may retain one when it
represents a chosen pattern, has a concrete future scenario and test, creates
no runtime initialization or artificial dependency, and does not require every
feature to copy the abstraction.

## Session, application lifecycle, and isolates

The application graph is stable for one root application lifetime. It is not
replaced on login, logout, tenant changes, `AppLifecycleState.inactive`, pause,
or background transitions. Mobile operating systems may terminate the process
without calling widget or graph disposal, so durability depends on awaited
transactions, idempotent operations, and recovery rather than teardown.

No auth or tenant capability exists in the base scaffold, so it does not create
an empty session graph. When a real capability requires controlled user or
tenant switching, a separately owned session graph belongs in the authenticated
flow shell. Logout must stop new session work, remove the session UI, resolve
the capability's in-flight-operation policy, and then dispose session-owned
resources. Process/app resources are not rebuilt. App-scoped caches must not
retain user data unless they define explicit partition/reset semantics.

Each background isolate has its own composition root and lifecycle.
`AppDependencies`, repositories, SDK clients, database objects, and
`AppEventBus` are not transferred between isolates. Only serializable messages
or an SDK's explicitly supported proxy/handle may cross the boundary.

If root theme, localization, guards, or app shells later need a dependency,
application composition passes that narrow value into `App` or the owning
controller. It does not reintroduce an app-wide inherited container. UI-owned
router/guard controllers remain owned by `App`; business and session services
remain graph-owned.

## Observability extension

The base template is provider-neutral. Before adding Sentry, Crashlytics, or a
similar SDK, retain `AppErrorBoundary` as the only global Flutter/platform/Zone
owner and explicitly decide reporter activation, consent, scrubbing, bounded
completion, recursion, Web coverage, flush, and SDK ownership. Vendor automatic
global integration remains disabled so two channels do not capture the same
failure.

## Testing

Unit and widget tests cover environment parsing, safe diagnostics, root-handler
ownership and restoration, scoped BLoC breadcrumbs/reporting, aggregate build
rollback, cleanup ordering, graph ownership transfer, failed pre-handoff Page
composition, graph owner disposal callbacks, feature DI, checked decoder
composition, typed Page coverage, route round-trips, no-replay/live event
delivery, action consumption, and router teardown.

Device-dependent integration scenarios run in separate processes:

1. real `main` plus `env/test.env` reaches the normal production graph;
2. `runApplication` plus a recording reporter exposes hidden async failures and
   asserts the complete expected record set;
3. real `main` plus invalid configuration renders only the privacy-safe startup
   fallback.

Every scenario that installs `AppErrorBoundary` uses a test-owned recording
reporter, asserts its complete record set, and restores the boundary in a
`finally` block after graph/report quiescence. An `addTearDown` callback remains
a fallback but is not sufficient on its own: Flutter's test binding must regain
its `FlutterError.onError` handler before a failing test-body Future escapes,
otherwise the boundary hides the original assertion behind the binding's
handler-override assertion.

They are intentionally excluded from `make check`. A real external-system flow
becomes mandatory when the project adds its first real external adapter.
