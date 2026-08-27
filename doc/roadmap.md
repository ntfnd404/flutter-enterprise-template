# Architecture roadmap

This roadmap records acceptance state, review order, and capability gates for
the normative target in [application architecture](architecture.md). It does
not redefine that architecture. A target contract may intentionally precede
its implementation; every such gap is recorded here until an isolated staged
snapshot is reviewed and committed by the user.

## Review transaction

Every phase uses the same transaction:

```text
implement and run narrow checks
→ review the working-tree diff
→ receive explicit permission before changing the Git index
→ stage one autonomous snapshot
→ validate and review the staged snapshot in isolation
→ the user commits the accepted batch
→ begin the next batch
```

The existence of code in the mixed working tree, a green combined test suite,
or documentation of a target does not make a phase accepted. Root manifests,
the lockfile, Makefile, generated plugin registrants, and generated sources
must match the exact isolated snapshot being reviewed. Codex does not commit,
push, or change the index without explicit user permission.

## Accepted baseline

The local Git history has accepted these autonomous batches:

| Commit | Accepted capability |
|---|---|
| `0965b3a` | Typed Environment baseline |
| `eca822a` | Strict quality policy |
| `23134c8` | In-process best-effort AppEventBus |
| `63b1839` | Typed startup configuration |
| `05bf1b3` | Shared AppDatabase physical host |
| `eafa349` | Catalog persistence schema v2 |
| `80827cf` | Pre-release Catalog persistence contract correction |
| `d3e3544` | Catalog bounded context and package taxonomy |
| `50b55e4` | Ordering persistence schema v3 |
| `f6b2243` | Consolidated Architecture Source of Truth v8 |
| `0b61dd6` | Flutter 3.47 platform and toolchain baseline |
| `7b710f3` | Ordering bounded context and Catalog ACL |
| `538e194` | App-owned dependency graph |
| `b0ea52e` | Application diagnostics |
| `c3a1000` | Main routing deferral and Rolter reference extraction |
| `3e2f4cb` | Consolidated Architecture Source of Truth v9 |
| `12e64d3` | Startup runtime v1 |
| `ea67c51` | Enterprise Routing v2 and reference presentation |
| Revision containing this roadmap | Minimal CI quality gate |

Self-reference rows are replaced with their final hashes by the next accepted
roadmap update because a commit cannot contain its own hash.

The accepted repository therefore contains the `bounded_contexts/libraries`
package taxonomy, a shared physical database, the Catalog business context,
the Ordering bounded context and Catalog ACL, and the Flutter 3.47/Dart 3.13
platform baseline, app dependency graph, application diagnostics, and the
provider-neutral routing deferral. Later accepted revisions implement the
consolidated v9 Startup/ownership target, live Startup runtime, and Enterprise
Routing v2.

The working tree may contain later implementations so adjacent APIs can be
developed and tested together. UI kit, localization, authenticated routing
flows, and later integration scenarios remain review candidates until their
own commits.

## Accepted in `538e194`: App-owned dependency graph

The DI design audit is complete. Accept the app-local implementation with:

- generic `AppDependencyGraph<T>` and top-level
  `buildAppDependencyGraph<T>` construction transaction;
- a register-only construction ownership boundary;
- non-generic `AppDependencyGraphOwner` as the sole Flutter-aware DI type;
- immutable, lifecycle-free, typed `AppDependencies`;
- production Database→Catalog→Ordering wiring and real teardown tests.

The complete normative lifecycle, rollback, ownership, privacy, and composition
contract is maintained in
[Build transaction and ownership](architecture.md#build-transaction-and-ownership),
not repeated in this roadmap.

The accepted dependency catalog contains `CatalogFacade`, `OrderingFacade`, and
borrowed `AppEventPublisher`/`AppEventSubscriber` roles. App DI creates and
registers one concrete `AppEventBus` first so LIFO teardown closes it last. Stores,
repositories, Product Offers, the Catalog ACL, clock, and database module remain
composition-only.

Catalog and Ordering facades now have real reference-presentation consumers.
The graph delivery catalog reaches only root route composition, which narrows
it immediately to feature scopes.

The autonomous DI snapshot passed isolated analysis, tests, DartDoc, full
quality checks, and staged review without blocker, high, or medium findings.

## Accepted in `b0ea52e`: Application diagnostics

Diagnostics Core v5.2.2 supersedes the unaccepted v5.2.1 candidate after an
exact staged usage-scenario and reviewability audit. It remains one app-owned
capability with sibling
`logging` and `error_reporting` directories. This isolated phase accepts:

- the open but trusted `AppLogRecord` SPI, static typed descriptors, typed
  field writer, a stable logger/null-object port library, a separately imported
  synchronous developer implementation, and fail-closed privacy projection;
- six final debug-only BLoC/Cubit record classes and two support-safe error
  record classes (`error_reported` and `reporter_failed`);
- closed `AppErrorReportKind`, strict asynchronous local/no-op reporters, and
  debug versus profile/release formatting;
- one root Flutter-isolate Zone and global-handler owner with privacy-first
  non-chaining restoration, distinct per-boundary logger/reporter recursion
  containment, and primary-before-reporter ordering;
- constructor-injected type-only BLoC/Cubit observation.

The public logger signature remains synchronous `void`; production
implementations cannot be `async`, reenter reporting, or create unowned work.
Direct boundary reporting is valid while created or active, whereas a disposed
boundary accepts only unavoidable best-effort late callbacks. A test-only final
support record proves the open SPI and every typed writer role without adding a
placeholder production event.

The complete normative privacy, coverage, lifecycle, expectedness, and future
provider contract is maintained in
[Diagnostics and error-handler lifecycle](architecture.md#diagnostics-and-error-handler-lifecycle),
not repeated here.

Accepted Startup closes the Diagnostics runtime-consumer gap:
`app/startup/run_application.dart` constructs one logger, reporter, and
boundary identity, while `main.dart` only delegates to it. Framework
initialization installs the BLoC observer using that logger. UI kit,
localization, presentation, and routing remain independent. Startup records
are not part of Core; they are accepted with their real Startup consumer.

The accepted `AppEventBus` now has a real publisher/subscriber pair.
`OrderDraftCreatedAppEvent` connects an in-flight Orders operation to a live
Activity projection without becoming authoritative or carrying navigation.
The former synthetic Demo completion event is removed.

Diagnostics Core itself does not accept `AppLoggingModule`, a support-log
exporter, native cache or Web IndexedDB adapters, persistence dependencies,
remote transport, analytics, or Support UI. The 4-KiB bound is intentionally
not a Core assertion: it applies to a complete canonical persisted line,
including the future storage envelope and final LF, and begins with the Storage
phase.

The first real implementation of a capability-owned narrow logging port will
live under `app/diagnostics/logging/adapters` with an exact inward-port import
allowlist. No adapter directory, base class, registry, or business import
exception exists before that consumer.

The isolated root-manifest delta is limited to exact hosted versions
`flutter_bloc: 9.1.1` and `ephemeral_bloc: 0.1.0`, plus their lockfile
resolution. It introduces no support-log storage dependency.

Any widget or process-isolated integration scenario that later installs the
boundary uses a recording reporter and asserts the complete expected record
set; the normal scenario requires no records. The boundary deliberately does
not invoke a previously installed Flutter test handler.

Remote diagnostics and analytics remain separate capability gates. No provider
registry, transport, queue, interceptor pipeline, or analytics event hierarchy
is accepted by this revision.

## Accepted by this revision: Consolidated architecture v9

Source of Truth v9 replaces v8 and later overlapping amendments for Startup,
process-global preparation, dependency composition, and resource ownership. It
established the target that the subsequent Startup runtime implements:

- `runApplication` is the sole composition root;
- binding is created inside the root boundary Zone before Environment or
  plugin work;
- one subordinate top-level `initializeAppFramework` configures only
  process/root-isolate global state;
- app-lifetime resources are constructed inside the existing transactional
  graph;
- `AppDependencies` is a downstream facade/port delivery catalog, not an
  inventory of modules, repositories, stores, or vendor clients;
- repositories remain private context collaborators retained by application
  services over borrowed stores;
- Firebase/FCM remain illustrative placement recipes, not dependencies or an
  implicitly scheduled provider phase.

The v9 candidate changed only the six canonical or derived documentation files.
Its runtime risk controls entered atomically with the accepted Startup phase
rather than as placeholder code.

## Accepted by this revision: Startup runtime v1

Startup runtime v1 originally implemented the v9 transaction without routing,
feature presentation, UI kit, localization, Firebase, or persistent support logging:

- `main` delegates to one `void runApplication` composition root;
- one logger, reporter, and boundary identity encloses binding, configuration,
  framework initialization, graph construction, handoff, and fallback;
- `initializeAppFramework` configures URL policy and the global BLoC observer
  but owns no application-lifetime resource;
- `AppDependencyGraphOwner` becomes the only owner after successful `runApp`;
- `AppStartupCompletedLogRecord` is emitted only after `runApp` returns and
  local graph authority is released;
- Environment and other Startup failures render only their stable support code
  in a graph-free fallback;
- tracked profiles use hash URLs by default, while path URLs remain an explicit
  deployment opt-in;
- process-isolated tests cover the real database graph and invalid Environment.

The only manifest addition is Flutter's SDK-owned `flutter_web_plugins` adapter.
Startup remains provider-neutral orchestration. The later routing phase passes
the built delivery catalog into normal `App`; UI kit and localization are not
Startup or routing prerequisites.

## Accepted by this revision: Enterprise Routing v2

The post-Startup gate selects exact `go_router: 18.0.0` and a single handwritten
app route catalog. Root `App` owns router lifecycle; features, BLoCs, and
workspace packages remain provider-neutral. The accepted Material reference
slice is Demo, Activity, Catalog, Orders, and static NotFound.

Canonical locations are `/`, `/activity/:sequence`, `/catalog`, and `/orders`.
Platform initial location is preserved; malformed or unsupported input is
privacy-safe; valid Activity route configuration restores; system back returns
child routes to Demo. Hash remains the deployment-independent default.

Catalog and Ordering facades now have real presentation consumers. Orders and
Activity prove a live, best-effort EventBus notification around an asynchronous
committed operation without using it for navigation or authoritative state.

## Later autonomous presentation capabilities

UI kit, generated localization, complete Catalog UI, Order Composer, and other
presentation work are independent phases. They may be scheduled when a real
consumer or delivery goal exists and do not block Startup or routing by
default. Route/path contract values are never localized.

## Persistent Support Log

**Entry criterion:** Startup has one stable logger identity and boundary
factory, and exact persistence dependency pins have been reviewed against the
accepted Flutter baseline.

This phase has no technical dependency on routing. Its priority relative to
the post-Startup routing gate is selected by a separate roadmap review after
Startup is stable.

Add the root-isolate `AppLoggingModule` as an autonomous Storage phase. It is
owned by the composition root outside `AppDependencyGraph`, starts with bounded
memory, may activate native cache or Web IndexedDB after binding and before
Environment, and degrades to memory-only without failing the functional app.
This phase atomically replaces Startup's standalone logger seam with the module
seam; both forms never coexist.

Add the bounded ring/queue, exact source constants, native segmented NDJSON and
Web IndexedDB stores, internal health counters/entries, timeout and late-
completion containment, and privileged in-memory NDJSON snapshot exporter.
Only this phase may add its exact pinned persistence dependencies and platform
files. The exporter remains outside `AppDependencies` until a real Support UI
consumer exists; no upload, public purge, remote reporter, analytics, or
controlled production shutdown is implied.

The complete lifecycle, storage, privacy, export, and 4-KiB canonical-line
contract is maintained in
[Diagnostics and error-handler lifecycle](architecture.md#diagnostics-and-error-handler-lifecycle),
not repeated here.

**Acceptance:** activation/disposal/export races are bounded; timeouts are not
treated as cancellation; memory, queue, persisted-data, segment, and output
bounds are exact; native and real-Chrome storage tests pass; exported data has
no raw failure, stack, runtime type, private writer ID, or unsupported field.

## Integration scenarios

Run normal startup, recording-error startup, and startup-failure fallback in
separate processes so root handlers and process-global Flutter state cannot
leak between scenarios. Keep device-dependent integration checks outside the
ordinary unit-test command.

Add a real external-system integration flow with the first external adapter;
the local Drift reference does not invent a remote provider.

## Accepted by this revision: Minimal CI quality gate

The repository now has one Ubuntu workflow for pull requests, pushes to `main`,
and manual runs. It installs Flutter 3.47.0 from the checksum-pinned official
archive, uses immutable reviewed GitHub Action revisions, least permissions, a
timeout, and concurrency cancellation. The clean-checkout gate verifies locked
dependency resolution, non-mutating formatting, analysis, tests, configuration
validation, DartDoc, Drift source/schema freshness, and a clean final tree.

Only the verified Flutter archive is cached, and its checksum is checked after
every restore. Pub dependencies and the extracted SDK are not cached. This
phase does not claim coverage thresholds, platform builds, real-Chrome storage,
device integration, release, or deployment automation.

## AST-based architecture guards

After Minimal CI, replace source-text parsing in three autonomous review
batches:

1. AST foundation and directives: add direct root dev dependency
   `analyzer: 13.3.0` while the Flutter 3.47/Dart 3.13 baseline remains, retain
   deterministically sorted filesystem discovery, and add one test-only
   `parseString` helper that fails closed on parser errors. Migrate imports,
   exports with `show`/`hide`, `part`/`part of`, allowed import locations, and
   foreign cross-package `src` imports in this batch.
2. Declarations and contracts: migrate modifiers, inheritance, constructors,
   fields, methods, public surfaces, Event and BLoC ownership, typed store
   catalogs, and prohibited container/DAO abstractions.
3. Executable syntax and composition: migrate constructor calls/references,
   Environment reads, graph claim/dispose sites, dependency-field access,
   lookup APIs, route-name references, and ordering checks based on AST offsets.

Before the first batch, classify every existing assertion in a review matrix as
an AST replacement, a retained structural/non-Dart check, or a removal covered
by a named stronger rule. Replace each source-text rule atomically with its AST
equivalent; do not keep competing implementations. File placement, manifests,
`build.yaml` and other build/tool configuration, Context Map YAML, SQL/Drift
schemas, generated layout, and behavioral tests stay outside Dart AST checks.
Do not add a package, CLI, plugin, custom lint, DSL, or resolved-element
infrastructure without a concrete rule that requires it. Remove the provisional
source-text warning only after the third batch leaves no AST-classified rule in
the migration matrix.

## Review hazards

Every phase review accounts for these recurring failure modes:

- a large mixed working tree is not evidence that a later phase is accepted;
- root manifest and lockfile hunks can silently pull future packages into the
  wrong snapshot;
- target documentation can lead accepted code, so this roadmap must keep each
  divergence explicit;
- a broad `AppDependencies` becomes a service locator, while a broad facade can
  become a repository with a different name;
- a package or directory named after a context does not prove a bounded
  context, and empty symmetric layers reduce cohesion;
- one physical database does not imply a shared model, transaction, or foreign
  key across contexts;
- AppEventBus has no replay and cannot be authoritative;
- identity-only entity equality can suppress UI changes if selectors choose a
  whole mutable entity instead of render-relevant fields;
- grapheme limits differ from UTF-16 and SQLite code-point length;
- duplicated domain/SQL safety bounds require regression tests;
- table rebuilds need representative performance and temporary disk-headroom
  validation before a production release;
- old binaries and stale Web tabs are unsafe after an unsupported schema
  upgrade;
- Flutter `State.dispose` is not an awaited shutdown barrier;
- raw stacks may contain paths or URIs, and logger/reporter failure can hide or
  recursively duplicate a primary failure;
- app-lifetime Page closures must not capture short-lived state;
- an Order snapshot intentionally becomes stale relative to later Catalog
  changes;
- an app workflow may consume two facades without coupling their domain
  models;
- one English locale proves generation and ownership, not translation quality
  or locale switching;
- source-text guards remain provisional and require human review until AST
  replacements are accepted;
- SOLID, GRASP, GoF, and DDD justify responsibilities and dependency direction,
  not additional class count.

For Startup and integration work, the review must also map each applicable
risk to a prevention control and a named proof in the owning phase. In
particular: binding/Zone ordering requires an integration test; owned
initialization requires register-before-initialize rollback coverage; immediate
configuration narrowing requires an import/signature guard; repository
exclusion from `AppDependencies` requires a delivery-surface guard; and
process-global state requires process isolation or `finally` restoration. The
detailed control matrix is maintained in
[Dependency and resource lifecycle](dependency_lifecycle.md#extension-review-controls).
Documentation-only phases prove scope through exact path and dependency deltas
instead of creating placeholder runtime tests.

## Capability gates

The following are not unfinished base work. They begin only when their entry
criterion exists:

- **remote reporting:** concrete provider, consent, scrubbing, timeout, flush,
  and recursion policy;
- **browser-JavaScript or native-crash capture:** a selected provider/runtime
  hook, coverage boundary, privacy policy, and deduplication relationship with
  the app-owned root boundary;
- **analytics:** provider, consent, data governance, bounded event vocabulary,
  and cardinality policy;
- **Support UI/exporter composition:** a real user support workflow that needs
  the least-authority snapshot role;
- **public support-log purge:** an account/logout, privacy-erasure, or other
  concrete deletion workflow with explicit ownership and policy;
- **support-log encryption at rest:** a threat-model change that requires
  protection beyond private app storage and bounded retention;
- **feature flags and engineer menu:** real runtime flag or QA override need;
- **session or tenant graph:** authenticated capability and explicit
  quiescence/data-partition policy;
- **controlled restart or awaited shutdown:** a real desktop/runtime scenario;
- **background isolates:** a real isolate workload and separate composition
  root;
- **reliable integration events:** a fact that cannot be lost, plus outbox,
  relay, idempotency, retry, monitoring, and compatibility policy;
- **Pricing or Offering context:** independent authority, language, invariants,
  ownership, security, release cadence, or relationship pressure, plus data
  cutover and rollback;
- **second app or reusable presentation:** a second consumer or independent
  team/release lifecycle;
- **second locale and locale persistence:** a real product language and locale
  selection requirement;
- **full multiplatform CI:** an accepted supported-target matrix;
- **multi-tab Web persistence:** a product requirement beyond the current
  storage policy;
- **shared-origin Web namespace:** deployment of multiple applications under
  one origin with reviewed ownership and migration;
- **native multi-process support logging:** a real second-process writer and a
  coordination/durability contract;
- **audit or security logging:** a regulatory/security requirement with its own
  integrity, access, retention, and delivery policy;
- **second production log destination or fan-out:** a real destination whose
  delivery and lifecycle cannot be represented by the existing local targets;
- **Diagnostics package extraction:** independent reuse, versioning, team
  ownership, or delivery rather than repository symmetry;
- **Ordering named Drift query:** a future API that proves equivalent reactive
  invalidation;
- **AGP legacy bridge removal:** a Flutter Gradle plugin proven to support the
  public AGP DSL with a green Android build.

Each activated gate requires a reviewed architecture update describing
ownership, compatibility, migration, rollback, and operational policy.

## Completion criteria

The consolidated target is complete only when:

- this documentation baseline is accepted without competing contracts;
- the platform project matches the accepted Flutter 3.47 and Dart 3.13
  baseline;
- Ordering and its Context Map edge are accepted separately from app DI;
- DI has passed the independent design audit and real database-to-context
  teardown tests;
- Diagnostics Core, Persistent Support Log, and the autonomous UI kit are
  accepted;
- Catalog and Order Composer are facade-only real consumers with generated
  localization;
- Startup has one composition root and no speculative router handoff seam;
- startup and process-isolated integration failures preserve primary errors and
  cleanup ordering;
- minimal CI reproduces clean-checkout quality and generator-freshness checks;
- AST guards match actual imports and replace equivalent source-text rules;
- every phase has passed isolated staged review and only the user has committed
  or pushed it.
