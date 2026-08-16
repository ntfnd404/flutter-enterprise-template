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

The accepted repository therefore contains the `bounded_contexts/libraries`
package taxonomy, a shared physical database, the Catalog business context,
and the Ordering persistence seam. It does not yet contain an accepted
Ordering business package or accepted application runtime built on these
facades.

The working tree contains later implementations so adjacent APIs can be
developed and tested together. Ordering, DI, diagnostics, UI kit, routing,
presentation, startup, integration scenarios, and platform migration remain
review candidates until their own commits.

## Current review: Flutter 3.47 platform and toolchain baseline

Accept the template migration to Flutter 3.47.0 and Dart 3.13.0 independently
from business or runtime architecture:

- refresh `.metadata` from the Flutter 3.47 template;
- review Android Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, and JDK 17 settings;
- retain the documented temporary legacy AGP DSL bridge only while required by
  the Flutter Gradle plugin;
- review current iOS/macOS generated-plugin Swift package integration and
  deployment targets;
- review Windows template safety updates;
- accept Widget Preview and workspace build ignore rules;
- accept only compatible lint and package-version corrections belonging to
  this toolchain snapshot.

The verified local toolchain is Flutter 3.47.0 stable, Dart 3.13.0, JDK
17.0.20, Android SDK 36.1, Xcode 26.3, and CocoaPods 1.16.2. The migration is
compared against a fresh Flutter 3.47 application while preserving authored
application code and the existing Apple development team. The empty template
does not declare `cupertino_icons`; its Web font warning is therefore accepted
instead of adding an unused dependency. Unresolvable transitive updates are
not forced.

The root manifest must not gain direct Ordering, UI kit, routing, or startup
dependencies before their owning phases. A fresh Flutter 3.47 application is
the comparison baseline, but authored application code is never overwritten
by template regeneration.

**Acceptance:** Flutter doctor/toolchain versions are recorded; analysis and
tests are green; available Web, Android, iOS-simulator, and macOS builds are
run in proportion to the changed platform files; warnings are reviewed; and
the staged snapshot contains no business or runtime draft.

## Next review: Ordering bounded context

Accept the pure-Dart downstream context after the platform baseline:

- persistent multi-line Order aggregate;
- Ordering application facade and repository adapter;
- Ordering-owned Catalog Anti-Corruption Layer;
- package README, DartDoc, tests, and architecture guard;
- Catalog-to-Ordering relationship in the Context Map.

The Context Map edge is accepted atomically with the downstream package. It
classifies Catalog Product Offers as a Published Language, the direct call as
a synchronous query, the adapter as an ACL, and consistency as a point-in-time
snapshot with no cross-context atomicity.

The package review proves persistent empty drafts, the 100-line bound, strict
rehydration, checked money, status and revision transitions, fixed UTC time,
offer refresh during placement, immutable placed snapshots, operation-specific
failures, stream ownership, and Catalog outage behavior.

This snapshot contains no application DI or Flutter UI. The root application
does not add a direct Ordering dependency until the DI phase creates its first
production import.

## App-owned dependency graph

The existing DI code is a design candidate, not a pre-approved implementation.
Review behavior before staging code and retain only types whose responsibilities
remain justified.

Fixed invariants are:

- manual constructor injection and no service locator;
- one ownership boundary per build;
- immediate registration of owned resources;
- no registration of borrowed stores or module internals;
- sealed ownership handoff after a successful build;
- complete sequential LIFO rollback;
- preservation of the primary failure and original stack;
- separate aggregate cleanup failures;
- idempotent concurrent disposal;
- lifecycle-free `AppDependencies`;
- no dependency lookup through the graph owner;
- no DI dependency on diagnostics, routing, or features.

The review may merge, split, rename, or remove the current Builder, Graph,
Owner, and DisposalStack types. It must examine reentrancy, synchronous and
asynchronous failures, callback isolation, constructor visibility, Flutter-free
graph primitives, graph replacement, async widget teardown, aggregate privacy,
and production Database→Catalog→Ordering teardown.

Production composition creates and immediately registers one database module,
narrows its stores into one Catalog application and one Ordering facade, and
places only `CatalogFacade`, `OrderingFacade`, and the actually consumed
AppEventBus in `AppDependencies`. Catalog, Ordering, their repositories, ACL,
clock, stores, and database internals remain non-owning composition details.

**Acceptance:** the architecture review records why each retained type exists;
rollback and normal teardown are covered; real Database→Catalog→Ordering
wiring is tested; and the isolated staged review has no blocker, high, or
medium findings.

## Application diagnostics

**Entry criterion:** DI is accepted.

Move app-owned root diagnostics and the BLoC observer to
`lib/app/diagnostics`. `lib/core/diagnostics` is not retained for app-specific
support codes, Flutter handlers, logging policy, or reporter policy.

Introduce a synchronous non-owning `AppLogger`, `DeveloperAppLogger`, no-op
implementation, and recording tests. Logger records contain stable event names,
approved runtime types, and optional duration only. They never contain raw
errors, stacks, messages, configuration, credentials, analytics properties, or
BLoC payloads.

Use an `AppErrorReporter` interface with local, no-op, and test recording
implementations. `AppErrorBoundary` remains the sole owner of the root Zone and
Flutter/platform handlers. The BLoC observer emits type-only breadcrumbs and
does not report failures. Environment failures remain local-only. No remote
reporter registry or delegating transport is created before a provider exists.

**Acceptance:** hostile `toString`, privacy, original stacks, handler ownership,
reporter/logger failure isolation, stable breadcrumbs, and exactly-once
unhandled BLoC reporting are tested.

## Enterprise UI kit

**Entry criterion:** diagnostics is accepted. The package itself does not
depend on diagnostics.

Accept `packages/libraries/ui_kit` as an autonomous reusable Flutter library
before application presentation depends on it. It owns Material 3 theme
assembly, light/dark/system variants, semantic ThemeExtension tokens,
component themes, focus behavior, target sizes, text scaling, and reduced
motion policy. It contains no product-specific widgets in v1.

The root application adds the direct package dependency only with the later
app-shell/presentation consumer snapshot.

**Acceptance:** package analysis, tests and DartDoc are green; WCAG 2.2 AA,
48dp targets, 200%/320% layout behavior, focus, light/dark/system, and
reduced-motion contracts are reviewed.

## Routing, presentation, Order Composer, and localization

**Entry criterion:** DI, diagnostics, and UI kit APIs are stable.

Accept one coherent Flutter presentation phase:

- standardize every feature Page adapter under
  `routing/page_composition/<feature>_route_page.dart`;
- keep routes and decoders data-only;
- make Scopes factory-only and let `BlocProvider(create: ...)` own BLoCs;
- complete Catalog category, draft, publication, offer-update, archival,
  deletion, observation, and retry UI;
- add an app-level Order Composer using both `CatalogFacade` and
  `OrderingFacade` without coupling the contexts;
- add English generated localization and remove hard-coded product vocabulary;
- install the accepted UI kit in normal and startup-failure shells.

Order Composer provides `/orders` and `/orders/:orderId`, persistent draft
creation, published-product selection, quantities, whole-line replacement,
placement, cancellation, authoritative watches, and operation-specific
failures. It uses Catalog only for product discovery; Ordering repeats the
authoritative Product Offers query through its ACL before committing.

**Acceptance:** route and Page coverage, duplicate rejection, fallback privacy,
Scope/BLoC ownership, facade-only presentation, Value Object UI constraints,
Catalog and Order Composer behavior, stream retry ownership, generated
localization, accessibility, and widget tests are green.

## Startup composition

**Entry criterion:** DI, diagnostics, routing, localization, and Page
composition have stable APIs.

Keep `void main() => runApplication();` and make top-level `runApplication` the
only composition root. Replace static `AppBootstrap` with the subordinate
top-level `initializeAppFramework` function. Remove the production
`pageCatalogBuilder` seam.

The startup transaction is:

```text
install AppErrorBoundary
→ start Stopwatch
→ load AppStartupConfiguration
→ initializeAppFramework
→ build and validate route registry
→ build dependency graph
→ build and validate Page catalog
→ runApp
→ hand the graph to one root lifecycle owner
```

Environment failures are local-only. Graph-build rollback completes before the
primary construction error is returned; outward reporting remains primary
before secondary cleanup diagnostics. Reporter failure cannot block cleanup.
Fallback mounting occurs only after cleanup, and fallback mount failure escapes
to the root Zone.

**Acceptance:** environment, framework, graph, Page, handoff, cleanup, reporter,
and fallback failures preserve original stacks and ownership.

## Integration scenarios

Run normal startup, recording-error startup, and startup-failure fallback in
separate processes so root handlers and process-global Flutter state cannot
leak between scenarios. Keep device-dependent integration checks outside the
ordinary unit-test command.

Add a real external-system integration flow with the first external adapter;
the local Drift reference does not invent a remote provider.

## Minimal CI quality gate

Add one Ubuntu workflow for pull requests, pushes to `main`, and manual runs.
Pin Flutter 3.47.0, use immutable reviewed action revisions, least permissions,
timeouts, and concurrency cancellation. Run non-mutating format checks,
analysis, tests, configuration validation, DartDoc, and Drift source/schema
freshness from a clean checkout.

This phase does not claim platform-build coverage.

## AST-based architecture guards

Replace source-text parsing with dev-only `package:analyzer` checks for imports,
exports, parts, constructor invocations, approved composition points,
Environment reads, context contracts, and cross-package `src` imports. Remove
the equivalent old parsing guard as each rule moves; do not maintain two
competing implementations.

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

## Capability gates

The following are not unfinished base work. They begin only when their entry
criterion exists:

- **remote reporting:** concrete provider, consent, scrubbing, timeout, flush,
  and recursion policy;
- **analytics:** provider, consent, data governance, bounded event vocabulary,
  and cardinality policy;
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
- app-owned diagnostics and the autonomous UI kit are accepted;
- Catalog and Order Composer are facade-only real consumers with generated
  localization;
- static startup coordination and the production Page-catalog replacement seam
  are absent;
- startup and process-isolated integration failures preserve primary errors and
  cleanup ordering;
- minimal CI reproduces clean-checkout quality and generator-freshness checks;
- AST guards match actual imports and replace equivalent source-text rules;
- every phase has passed isolated staged review and only the user has committed
  or pushed it.
