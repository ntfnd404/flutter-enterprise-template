# AGENTS.md

## Project

`template` is an enterprise-oriented Flutter scaffold with BLoC presentation,
manual constructor injection, explicit resource ownership, and public
compile-time environment profiles.

The canonical references are:

- [application architecture](doc/architecture.md);
- [code style](doc/code_style.md).

Intentionally deferred work and its entry criteria are recorded in the
[architecture roadmap](doc/roadmap.md). The roadmap does not override the
current contracts above.

These instructions describe the normative target. The roadmap identifies which
phases are accepted in Git; later files in a mixed working tree do not authorize
staging, runtime use, or dependency expansion out of order.

## Architecture

- `lib/main.dart`: application composition root and startup fallback.
- `lib/app`: application policy, wrappers, app-wide notification contracts, and UI composition.
- `lib/app/startup`: process-global framework and required SDK preparation.
- `lib/app/diagnostics`: root error boundaries, logger/reporter policy, and
  privacy-safe diagnostics.
- `lib/app/environment`: immutable public client configuration.
- `lib/app/di`: dependency-catalog construction, graph transaction, ownership,
  rollback, and root-lifecycle handoff.
- `lib/app/di/modules`: concrete app-owned infrastructure composition and
  platform adapters; graph primitives outside this subtree stay Flutter-free.
- `lib/core/di/typedefs`: construction-only `Factory` vocabulary.
- `lib/core/event_bus`: domain-neutral best-effort event delivery mechanism.
- `lib/app/events`: application-wide best-effort `AppEvent` contracts for
  independent Flutter features.
- `lib/app/routing`: route composition, navigation capabilities, and UI-owned router lifecycle.
- `lib/app/view`: root framework/application wrappers, not a general screen catalog.
- `lib/feature/<name>`: Flutter presentation and feature-local UI orchestration;
  `app` is never modeled as a feature.
- `packages/libraries/app_database`: Dart-only shared physical Drift host, schema,
  migrations, private DAOs, and narrow context-specific stores.
- `packages/bounded_contexts/catalog`: executable reference bounded context with a domain-owned
  repository port, infrastructure adapter, and public application facade.
- `packages/bounded_contexts/ordering`: downstream reference bounded context with a persistent
  Order aggregate and an Ordering-owned Catalog Anti-Corruption Layer.
- `packages/bounded_contexts/<context>`: one package per additional real business bounded
  context, created only when that context exists.
- `packages/libraries/<capability>`: one package per real reusable technical or
  foundation capability without its own business model.
- `packages` is only the Pub workspace container, not an architectural layer.
  `libraries` is a repository category, not a Dart `library` declaration or a
  DDD Shared Kernel.
- `lib/feature/<name>/di`: feature BLoC construction.
- `BlocProvider(create: ...)`: BLoC instance ownership.

Do not add GetIt, a global service registry, static `AppBootstrap`,
`AppLauncher`, `AppBootstrapper`, or a second composition-root class.

## Commands

```text
make check
make test-database-web
make run-local
make run-dev
make run-prod
```

`make check` runs analysis, unit/widget/architecture tests, environment
validation, and DartDoc validation. Integration tests are separate because they
require a Flutter device.

## Rules

- Preserve the package name `template` in this scaffold repository.
- Use package imports in production `lib/` code.
- Use point imports for app-internal subsystems. Do not add nested dump-barrels
  without a reviewed external API boundary.
- Name authored files and directories with `lowercase_with_underscores`, except
  for ecosystem-standard root files such as `README.md` and `AGENTS.md`.
- Prefer composition over inheritance.
- Keep Environment and DI graph primitives Flutter-free. Isolate a required
  Flutter plugin behind its concrete `app/di/modules` platform adapter.
- Never put secrets in Flutter dart-defines.
- Declare every Dart environment key in `AppEnvironmentKeys`; only
  `app_environment_loader.dart` reads it with `String.fromEnvironment`.
- Keep `AppEnvironment` limited to app-owned deployment/framework policy.
  `AppStartupConfiguration` may aggregate typed capability configurations only
  for startup composition and must be narrowed immediately. A package-specific
  `<Capability>Configuration` and its validation belong to the owning package;
  never pass the startup aggregate or `AppEnvironment` into that package.
- Every CI/CD build must run `make check-env ENV_FILE=<path>` for the exact
  profile passed to `flutter build --dart-define-from-file=<path>`.
- Put real business domain/application/infrastructure code in
  `packages/bounded_contexts/<context>`.
  Never create global `packages/domain` or `packages/data`, empty context
  packages, or layers without active behavior.
- Keep a technical adapter with its application or bounded-context owner until
  a separate package has at least one concrete driver: multiple real consumers,
  an independently useful public contract, multiple provider/platform
  implementations, separate ownership/lifecycle, or material independent
  testing/versioning/delivery. An entry criterion permits review; it does not
  make extraction automatic.
- Keep problem-space and solution-space terminology separate. Domain and
  subdomain describe the business problem; `core`, `supporting`, and `generic`
  are subdomain types; a bounded context defines a model/language/API boundary;
  `domain/` is only the domain layer inside that context. Keep these relations
  normalized in `architecture/context_map.yaml` under `domains` and
  `bounded_contexts`; never store a subdomain type as a subdomain name.
- Keep repository ports in the layer whose language and policy they express.
  A domain repository uses domain types and is implemented in
  `infrastructure`; a
  query-only application port does not move to `domain` merely because it is
  an interface. Group domain repository ports under `domain/repository` and
  store-backed adapters under `infrastructure/persistence`. Presentation
  receives neither form directly.
- The shared application-database module owns its connection, SQL schema,
  migrations, and private DAOs. It exports separate narrow stores per context,
  never the raw database or generated rows.
- Group public database store seams under
  `package:app_database/stores/<context>.dart`; never combine unrelated
  contexts into one broad database barrel. Keep internal failures with their
  owning configuration, connection, or context capability instead of a global
  exception directory.
- `AppDatabaseModule` exposes one immutable typed store catalog only after it
  is ready. Context-owned bundles assemble stateless store adapters
  synchronously, perform no I/O or disposal, and are narrowed immediately by
  app DI. Never pass the root catalog or a context bundle into `AppDependencies`,
  a bounded context, or presentation, and never replace it with dynamic lookup.
- Put context-owned database sources under
  `packages/libraries/app_database/lib/src/persistence/<context>/<cluster>`. Use `tables`
  for authored definitions, `queries` only for real named queries, `dao` for
  private cohesive access objects, and `store` for narrow context seams. Root
  `src/schema` is reserved for versioned migration snapshots. A context-level
  `persistence/<context>/failures` may contain only store failure contracts and
  translation shared by multiple clusters of that context; it never contains
  DAOs, tables, or concrete stores.
- Only SQLite `BUSY` and `LOCKED` contention is an expected temporary store
  failure. Preserve every other boundary error and its original stack: direct
  executors keep the `SqliteException`, while background executors keep the
  outer `DriftRemoteException` and inspect its SQLite cause only to classify
  contention.
- A context owns its repository port, repository implementation, mapping, and
  application facade. It borrows its narrow store and never closes the shared
  database. Presentation receives only the application facade.
- Public context stores expose intent-specific conditional writes. Do not let
  cross-package callers supply raw lifecycle values when the persistence
  boundary can encode a real command such as publishing a draft or archiving a
  published item.
- Catalog title length is measured in grapheme clusters. Domain validation is
  authoritative; do not duplicate its maximum with SQLite `length()`.
- Catalog item details and lifecycle transitions compare and increment the
  explicit optimistic revision. Publication must also recheck the active
  category in its conditional persistence update.
- Catalog exposes downstream offer snapshots only through
  `catalog_product_offers.dart`; its sources stay in the application-owned
  Product Offers capability, not a peer architectural layer. Ordering
  domain/application never import Catalog; only the Ordering integration
  adapter imports that Published Language contract and translates it through
  its Anti-Corruption Layer. Do not create matching integration directories in
  contexts without a real external adapter.
- Do not split Pricing or Offering from Catalog because a table, DTO, or folder
  grew. Require a context-modelling decision and ADR based on independent
  authority, language, invariants, ownership, security, release cadence, or
  relationship pressure, with an explicit ownership and data cutover plan.
- Keep Product Offers unversioned only while all consumers ship atomically in
  the same application and no persisted messages or compatibility window
  exists. Item `catalogRevision` is traceability, not a contract version.
- Order line replacement and placement are conditional aggregate transactions.
  Catalog IDs remain external scalar references without cross-context foreign
  keys or shared SQL transactions. The synchronous Catalog query returns a
  point-in-time snapshot; a committed Order does not converge to later Catalog
  changes.
- Keep Drift verifier code in
  `test/migrations/drift/application_database/generated` and handwritten
  migration tests in `test/migrations/application_database`. Authored
  transition functions belong in `lib/src/migrations`, use their generated
  target `SchemaN`, and never import the current `ApplicationDatabase`. Add
  migration tests only with a real version transition and never edit generated
  helpers manually.
- Serialize schema-version allocation across branches, preserve historical
  AUTOINCREMENT identity during table rebuilds, and release repairs as forward
  migrations. Old binaries and stale Web tabs must not continue against a
  physical schema newer than they support.
- Do not create a second DAO interface underneath a public narrow store without
  a second implementation or another real boundary. Repositories without owned
  resources are collaborators, not disposable runtime modules.
- Never log raw errors, configuration values, BLoC events, or state payloads.
- Register graph-owned disposable resources immediately after creation.
- Never register borrowed resources or private internals already owned by a
  module.
- `AppDependencies` exposes only real app-lifetime ports or public application
  facades. Presentation does not receive repositories or vendor clients.
- `AppDependencies` has no lifecycle API. One returned graph owns the sealed
  build-time resource registration, and one root lifecycle adapter owns that
  graph after successful `runApp` handoff. The current Builder/Graph/Owner/
  DisposalStack split is a candidate to audit, not a mandatory class design.
- BLoCs and their factories stay in `feature/<name>`.
- Shared `Factory` typedefs describe construction only; they are not
  dependencies, owners, or permission to expose BLoC factories from
  `AppDependencies`.
- A `*_bloc.dart` file is the root library; its action, event, and state are
  mandatory `part` files and are imported only through the BLoC root.
- A documented scaffold feature may start with only a sealed event base and
  immutable initial state. Do not invent concrete events or handlers before
  real behavior exists.
- Never read dependencies from the graph lifecycle owner; it is lifecycle-only.
  Narrow dependencies enter feature Page definitions and
  flow through constructors.
- Persistent UI data belongs in BLoC state; same-feature one-shot UI effects use
  `EphemeralBloc` actions; cross-feature facts use `AppEventBus`.
- Commands without a useful consumer-facing payload return `Future<void>`;
  introduce an application result only for a real consumer. Add domain or
  integration events only with an actual reaction or delivery requirement.
- `AppEvent` means only an in-process, best-effort application-shell
  notification. It is not a DDD integration event and must be safe to lose.
  Required cross-context work uses an awaited narrow port or, when crash-safe
  continuation is required, a versioned durable integration contract.
- Do not add a global `DomainEvent` marker or dispatcher. Introduce a
  context-owned domain event only with a real independent handler and an
  explicit transaction, failure, duplicate, and delivery policy.
- Failure or completion of an authoritative watch is persistent state with an
  explicit retry path. Expected failure of one UI command is an ephemeral
  action; data-integrity and unexpected failures propagate to the root boundary.
- Never use `AppEventBus` for navigation, SnackBars, current state, or required workflows.
- Demo and Activity must not import one another. They may depend on centralized
  best-effort `AppEvent` contracts in `app/events` and narrow navigation
  contracts owned by `app/routing`. The Activity example is a non-authoritative
  screen-lifetime projection and must not be copied for business decisions.
- Route classes and decoders belong to their feature. Application routing may
  map narrow app-owned navigation contracts to concrete feature routes.
- A feature-owned navigation extension may be retained as a documented and
  tested scaffold extension point, but unrelated features must not import it.
- A feature route is data-only and implements the app-owned `AppRoute` SPI. Its
  feature-owned `routing/page_composition/<name>_route_page.dart` adapter imports the route,
  view, and DI boundary. Other routing files remain presentation-free. This is
  feature cohesion, not cross-feature coupling.
- Only explicit application composition points import concrete features:
  `app_navigator.dart`, `app_route_registry.dart`, `app_pages.dart`, and the
  pre-DI `startup_failure_app.dart` wrapper. Root `App` consumes initial-route
  and Page-building strategies without importing a feature directly.
- Stable route names belong to feature-owned `*RouteName` enums; route
  implementations and decoder maps must use the enum's `value`.
- Feature decoder maps receive `AppRouteFallbackBuilder`; they report a safe
  failure reason and never import the concrete NotFound feature.
- NotFound is a normal-graph route-recovery feature. StartupFailure is an
  isolated pre-DI feature that must not import normal DI, routing, or EventBus.
- `App` and `StartupFailureApp` are application wrappers; user-facing screen
  content and its state lifecycle belong in a feature.
- `AppEventBus` has no replay. A screen-lifetime consumer observes only events
  published while its screen exists.
- `AppErrorBoundary` is the sole reporter of unhandled BLoC failures; the global
  BLoC observer emits type-only debug breadcrumbs.
- App dependency composition registers every app-owned leaf resource or
  returned module immediately in the exact ownership boundary created for that
  build. Successful construction closes registration before returning the
  graph; the DI audit may change the involved type names and split.
- Page builders are synchronous and non-owning. They use `route.pageKey`,
  dispatch by exact route type, and never start I/O or allocate disposable
  resources.
- Decoder composition rejects duplicate route values before router construction;
  Page catalog construction rejects duplicate route types.
- Do not replace the app graph for login/logout or tenant changes. Add a
  separately owned session graph only with a real capability and explicit
  quiescence policy.
- Each background isolate has its own composition root; never send
  `AppDependencies`, repositories, database/client objects, or `AppEventBus`
  across isolates.
- Document every public startup, Environment, Diagnostics, DI, and Event Bus symbol.
- Add a real external-system integration flow with the first external adapter.
- Do not delete a documented template extension point merely because it has no
  production caller. It must instead have a concrete scenario, DartDoc, and a
  test while adding no artificial runtime dependency.

## Verification

Format only changed Dart files, then run:

```text
flutter analyze
flutter test
make check-config
dart doc --dry-run
```

Run phase-specific database, package, Web, platform, and integration commands
listed by the roadmap and the owning package. Device integration targets are
added only with the integration-scenarios phase.
