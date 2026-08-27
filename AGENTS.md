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

- `lib/main.dart`: one-line production entrypoint delegating to Startup.
- `lib/app`: application policy, wrappers, app-wide notification contracts, and UI composition.
- `lib/app/startup`: the sole `runApplication` composition root, its
  subordinate framework initializer, and process/root-isolate global
  preparation after the root binding prelude.
- `lib/app/diagnostics/logging`: app-shell typed log-record SPI, local logger
  projection, and BLoC observer.
- `lib/app/diagnostics/error_reporting`: root error boundary, privacy-safe
  error formatting, and strict local/no-op reporting.
- `lib/app/diagnostics/logging/support_log`: reserved for the later
  root-isolate persistent support-log capability; the roadmap, not target
  documentation, determines when it is accepted.
- `lib/app/environment`: immutable public client configuration.
- `lib/app/di`: generic graph transaction, register-only resource capability,
  private-ledger ownership, rollback, app dependency construction, and
  root-lifecycle handoff.
- `lib/app/di/modules`: concrete graph-owned infrastructure composition and
  its platform adapters; graph primitives outside this subtree stay
  Flutter-free. A process-root adapter stays with its owning app capability
  instead of being placed here merely because it is platform-specific.
- `lib/core/di/typedefs`: construction-only `Factory` vocabulary.
- `lib/core/event_bus`: domain-neutral best-effort event delivery mechanism.
- `lib/app/events`: application-wide best-effort `AppEvent` contracts for
  independent Flutter features.
- `lib/app/routing`: the single handwritten `go_router` composition catalog;
  provider APIs do not enter features, BLoCs, or workspace packages.
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

Do not add GetIt, a global service registry, a static startup coordinator,
launcher/bootstrapper class, or a second composition root.

## Commands

```text
make check
make check-ci
make test-database-web
make test-integration DEVICE=<device>
make test-integration-startup-failure DEVICE=<device>
make run-local
make run-dev
make run-prod
```

`make check` runs analysis, unit/widget/architecture tests, environment
validation, and DartDoc validation. Integration tests are separate because they
require a Flutter device. `make check-ci` additionally verifies formatting,
the locked dependency resolution, Drift source/schema freshness, and a clean
repository; run it only from a clean committed or materialized tree. Real
Chrome persistence, device integration, and platform builds remain separate
targets.

## Rules

- Preserve the package name `template` in this scaffold repository.
- Use package imports in production `lib/` code.
- Use point imports for app-internal subsystems. Do not add nested dump-barrels
  without a reviewed external API boundary.
- Decompose files by cohesive responsibility and useful dependency/review
  boundaries, not by a mechanical one-class-per-file rule. Keep a substantial
  implementation separate from its stable port when that reduces consumer
  coupling; a trivial null object and closely related immutable records may
  remain in one cohesive library.
- Name authored files and directories with `lowercase_with_underscores`, except
  for ecosystem-standard root files such as `README.md` and `AGENTS.md`.
- Separate `return` from a preceding statement in the same block with one blank
  line. Add no leading blank line when `return` is the first or only statement
  in that block.
- Prefer composition over inheritance.
- Keep Environment and DI graph primitives Flutter-free. Isolate a required
  Flutter plugin behind the concrete adapter owned by its lifecycle
  capability; graph-owned adapters belong under `app/di/modules`, while the
  future process-root support-log adapters belong to Diagnostics.
- Keep `runApplication` as the only composition root. It installs the boundary,
  creates the Flutter binding in that Zone, loads typed configuration, invokes
  one top-level `initializeAppFramework`, builds the graph, and performs the
  root handoff. The subordinate initializer configures only process/root-
  isolate global state; it never opens the database, creates repositories,
  retains disposable SDK handles, builds the graph, or mounts UI.
- Log `AppStartupCompletedLogRecord` only after `runApp` returns and local graph
  authority has been released. That breadcrumb means root attachment was
  scheduled; it does not mean first frame, durable persistence, or awaited
  shutdown.
- Keep `App` as the owner of one UI-lifetime `GoRouter` over one exact
  `AppDependencies` identity. A real replacement requires a new widget State.
  Keep `StartupFailureApp` pre-graph and render only the stable Environment or
  Startup support code, never raw failure/configuration data.
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
- Never log raw errors, configuration values, BLoC events, state/action
  payloads, arbitrary messages, or metadata maps. `AppLogRecord` is an open
  but trusted outer-application SPI: every production record is a final
  app-owned subclass that extends the base, owns one static descriptor, and
  projects one closed typed shape synchronously. It never starts async work or
  selects its name, version, severity, or data class at runtime. Workspace
  packages and features neither import nor extend the SPI; a capability that
  genuinely emits diagnostics owns a narrower semantic port. Its first real
  outer adapter belongs under `app/diagnostics/logging/adapters`, imports only
  that inward port plus the logger and concrete records, and is accepted with
  an exact import guard. Do not create the directory or a generic adapter base
  in advance. Runtime types are debug-only breadcrumbs, not stable identifiers,
  persisted fields, or analytics dimensions.
- Keep logging and error reporting as separate subsystems under the one
  Diagnostics capability. `AppLogger` accepts approved typed records and no
  raw failures. `AppErrorReporter` alone accepts an error and nullable original
  stack. `AppErrorBoundary` records one support-safe error-kind breadcrumb
  before invoking the raw reporter and reduces reporter failure to one fixed
  logger record; neither subsystem is a generic sink for the other.
- Keep `AppLogger.log` synchronous and no-throw. An implementation never marks
  it `async`, reenters itself, calls the error boundary/reporter, or installs
  global handlers. A future persistent module may start only an owned, tracked,
  contained drain after its synchronous enqueue handoff; detached work remains
  forbidden.
- Keep `AppErrorReporter` strict and asynchronous: its Future covers all work
  it starts. Profile and release error-report output exposes only stable
  support codes; raw stacks remain local debug detail and are never
  remote-ready data. Approved typed logger records remain separate.
- Keep `AppErrorReportKind` a closed list of real root/orchestration ingress.
  It is not severity, expectedness, retry policy, analytics vocabulary, or a
  catalog of feature failures.
- `AppErrorBoundary` owns the guarded Zone and Flutter/platform callbacks only
  for the root application isolate. It never invokes previously installed
  handlers, never fabricates a missing stack, and remains backed by one fixed
  local or no-op reporter until a provider ADR defines handoff and ownership.
  Its distinct per-instance logger and reporter Zone markers suppress only
  same-boundary reentry. Direct `report` is permitted while created or active;
  after disposal it remains best-effort/no-throw only for unavoidable late
  callbacks, not deliberate new work. A Flutter/widget/integration test that
  installs the boundary restores it in `finally` before a test-body failure can
  escape; `addTearDown` alone runs too late for Flutter test error handling.
- Persistent support logging is a later phase, not part of Diagnostics Core.
  Its `AppLoggingModule` is owned by the root isolate outside
  `AppDependencyGraph`, accepts only support-safe typed projections, and may
  degrade to bounded memory without failing the functional application. It is
  never exposed through `AppDependencies`; native cache files, Web IndexedDB,
  versioned NDJSON export, retention, and platform dependencies enter
  atomically with that phase. Do not add a public purge, upload, support UI,
  remote transport, generic sink, registry, or provider handoff in advance.
- Determine expected failures from the exact operation contract, not from the
  Dart `Exception` marker. Use `rethrow` for the same object and
  `Error.throwWithStackTrace` when translating a recognized boundary failure.
- Register every graph-owned resource immediately and exactly once. Never
  register borrowed resources or private internals already owned by a module,
  and never retain `AppResourceRegistrar` after graph construction.
- Keep `AppDependencies` flat, typed, and lifecycle-free. It is a downstream
  delivery catalog, not an inventory of graph objects. It contains only real
  app-lifetime public facades or ports with accepted consumers, except for an
  explicitly bounded, tested consumer gap recorded in the roadmap. Application
  services retain their private repositories over borrowed stores; the catalog
  never exposes lookup, repositories, stores, modules, configurations, vendor
  clients, or BLoC factories.
- Keep graph primitives independent of Flutter, business packages, Diagnostics,
  routing, and features. `AppDependencyGraphOwner` is the sole Flutter adapter,
  owns one graph once, and never provides dependency lookup or replacement.
- Any graph-lifecycle change must preserve the canonical one-owner, identical
  memoized disposal Future, sequential all-attempt LIFO cleanup, reentrancy
  rejection, and primary-first rollback contracts in
  [application architecture](doc/architecture.md#build-transaction-and-ownership).
- Keep composition explicit and constructor-based. Add private typed helpers or
  cohesive module factories only for demonstrated ownership or partial-rollback
  responsibilities; never add a universal module protocol or DI container.
- Register an owned module before awaiting its initialization. A configuration
  helper may validate or resolve a platform path before registration only when
  it acquires no connection, executor, subscription, or other disposable
  resource. Borrowed registry values are never registered.
- Instantiate and register the accepted concrete `AppEventBus` only with real
  publisher and subscriber consumers; downstream code receives non-owning
  roles.
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
- Keep `go_router` exact-pinned and imported only by
  `app/routing/app_router.dart` and `app/view/app.dart`. The router belongs to
  root UI lifecycle, not `AppDependencies` or the dependency graph. Bounded
  contexts, inner layers, features, and BLoCs never import the provider or use
  a global navigator/router locator.
- Keep one explicit handwritten top-level route composition catalog. Add a
  route group only for a real independently governed flow; do not add route
  registries, route DTOs, generated routes, or a provider-neutral facade.
- Keep cross-feature navigation out of `AppEventBus`. Add a narrow semantic
  callback or application-UI port only when a real caller must navigate
  without depending on another feature's implementation.
- Treat URLs, parameters, and navigation state as potentially sensitive. Do
  not stringify them in Diagnostics, analytics, exceptions, or fallback UI.
- Accept path-based Web URLs and platform deep links only together with their
  hosting/platform configuration and integration tests.
- `AppEventBus` has no replay. A screen-lifetime consumer observes only events
  published while its screen exists.
- `AppErrorBoundary` is the sole reporter of unhandled BLoC failures; the global
  BLoC observer emits debug-only type breadcrumbs through `onChange` for both
  Bloc and Cubit and does not duplicate them through `onTransition`.
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
