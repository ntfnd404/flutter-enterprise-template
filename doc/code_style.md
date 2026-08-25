# Code style

This document defines implementation and naming conventions for `template`.
Application lifecycle and placement decisions belong in
[application architecture](architecture.md).

## Naming and layout

- Name authored files and directories with `lowercase_with_underscores`.
- Keep ecosystem-standard root names unchanged: `README.md`, `CHANGELOG.md`,
  `CONTRIBUTING.md`, `LICENSE`, `AGENTS.md`, and `CLAUDE.md`.
- Place authored project documentation in `doc/`.
- Treat `doc/api/` as generated `dart doc` output and never commit it.
- Mirror source paths under `test/` and suffix test files with `_test.dart`.
- Keep the root application shell in `lib/app`; reserve `lib/feature/<name>` for
  Flutter presentation and feature-local UI orchestration, `lib/core` for
  domain-neutral mechanisms, `packages/bounded_contexts/<context>` for real
  business bounded contexts, and `packages/libraries/<capability>` for real
  reusable technical or foundation packages.
- Keep framework/application wrappers such as the root `MaterialApp` and
  router ownership in `app/view`. Put user-facing screen content,
  presentation state, and feature DI in `feature/<name>`.
- Start one package for a real bounded context and add its `domain`,
  `application`, `infrastructure`, or `composition` directories only when
  active behavior requires them. Do not create global domain/data packages or
  empty Clean Architecture scaffolding.

## Formatting and imports

- Use `dart format` with the configured 80-character page width.
- Separate a `return` from any preceding statement in the same block with one
  blank line. Do not add a leading blank line when `return` is the first or
  only statement in that block. This convention matches DCM's
  [`newline-before-return`](https://dcm.dev/docs/rules/common/newline-before-return/)
  rule and remains mandatory even when DCM is not part of the project
  toolchain.
- Use `package:template/...` imports in production `lib/` code.
- Use point imports for app-internal subsystems. Do not add a nested barrel
  unless it represents a reviewed API boundary with real external consumers.
- Keep imports in analyzer-enforced directive order.
- Do not import another package's implementation libraries.
- Split a source file when doing so creates a meaningful responsibility,
  dependency, or review boundary. Do not apply one-class-per-file
  mechanically: a trivial null object may remain beside its port, and closely
  related immutable records may share one cohesive library. Conversely, keep a
  substantial implementation in its own point-import library when ordinary
  consumers need only the stable port.
- Remove dead and commented-out implementations; version control preserves
  history. A short placement-oriented snippet in DartDoc or an extension point
  is allowed when it teaches the documented scaffold contract; detailed SDK
  examples belong in `doc/dependency_lifecycle.md`.

```dart
final result = calculateResult();

return result;
```

An immediate return needs no artificial leading whitespace:

```dart
if (!isSupported) {
  return;
}
```

## Types and APIs

- Prefer immutable values, `final` concrete classes, `const` constructors where
  semantically useful, and constructor injection.
- Use `abstract interface class` only for a real behavioral substitution point.
- Declare public API types explicitly and avoid `dynamic` calls. For private
  and local declarations, prefer inference when the initializer already makes
  the exact intended static type obvious. Keep an explicit type when it widens
  or narrows inference, represents nullable lifecycle state, disambiguates an
  empty collection, or documents another non-obvious contract. Omit collection
  literal type arguments when context or elements determine them unambiguously.
- Use named parameters for booleans and for arguments whose meaning is not
  obvious at the call site.
- Use initializing formals, including Dart primary-constructor syntax, when
  they express direct immutable assignment clearly. Keep public parameter
  names readable; expand the constructor when validation, ownership transfer,
  or a differently named private representation makes the concise form less
  clear.

## Template extension points

A public scaffold extension point may exist without a production caller only
when all of the following are true:

1. It represents an intentionally selected architecture pattern.
2. It has a concrete future use case rather than a hypothetical abstraction.
3. Its DartDoc includes purpose, ownership, and a minimal usage example.
4. A test compiles or exercises the intended contract.
5. It creates no runtime initialization or artificial dependency.
6. It does not imply that every feature must duplicate the same abstraction.

Do not add fake runtime callers merely to make an extension point appear used.
Conversely, do not retain undocumented helpers whose only justification is
that a template might need them someday.

## BLoC libraries

- Treat each `*_bloc.dart` as the root Dart library for that BLoC.
- Put every BLoC action, event, and state in its own companion file and attach
  it with `part`/`part of`. Do not import companion files directly.
- Keep private internal BLoC events in the event part. The convention does not
  require unrelated private helpers to become parts.
- A documented scaffold extension point may declare only the sealed event base
  and initial state until real behavior exists. Do not add placeholder events,
  handlers, repositories, or use cases merely to populate the files.
- Import the root `*_bloc.dart` wherever public action, event, or state types
  are needed. This keeps a BLoC's public surface and companion types coherent.

```dart
part 'profile_action.dart';
part 'profile_event.dart';
part 'profile_state.dart';
```

## Routing names

- Put stable URL and decoder keys in a feature-owned `*RouteName` enum with a
  `value` field.
- Make the route's `name` and its decoder-map key reference the same enum
  value. Do not duplicate route-name string literals or add `static wireName`
  fields to page implementations.
- Keep page identity (`pageKey`) separate from the route-value contract: a page key
  may include runtime parameters and widget-lifecycle identity.
- Keep each concrete data-only route beside its feature view and DI boundaries.
  The route imports the shared `app/routing/app_route.dart` SPI but no feature
  UI or DI. Put the outer presentation adapter in
  `feature/<name>/routing/page_composition/<name>_route_page.dart`; only that file may
  import the same feature's route, scope, and view.
- Keep concrete cross-feature route imports in application composition files,
  not in root widgets, core, or unrelated feature slices.
- Keep `AppNavigator` feature-neutral. Adapt a real cross-feature destination
  through a narrow app-owned port and a private stateless adapter in
  `app_navigator_context.dart`; do not expose a broad `BuildContext.navigator`.
- Make every externally composed Page use `key: route.pageKey`. Page builders
  are synchronous and non-owning: do not start I/O, navigate, mutate route
  state, or allocate an unowned disposable resource in them.
- Dispatch Pages by exact route type, never by a route value. Application decoder
  composition must reject duplicate route values instead of relying on map
  spread overwrite behavior.
- Inject `AppRouteFallbackBuilder` into feature decoder maps. A feature reports
  only `AppRouteFailureReason` and must not import the concrete recovery route.
- Never pass attempted URI, query values, or raw decoder failures into fallback
  routes, BLoC state, page keys, presentation, or logs.
- Treat route URI, params, page keys, and navigation transitions as potentially
  sensitive. Do not interpolate or stringify them in errors, Diagnostics, or
  analytics. Stable wire names and parameter keys are explicit reviewed
  literals, not localized copy.
- Keep logical codec goldens separate from browser-visible hash/path examples.
  Browser hosting, origin validation, and platform deep links are integration
  contracts rather than codec unit-test claims.
- Count and inspect external route segments in their raw encoded form. Reject
  duplicate parameter keys within one query channel or route segment before
  decoding; do not wrap trusted decoder or route code in a generic catch.
- Treat recovery-only route names separately from external wire values. A
  `HistoryExcluded` NotFound route is application state, not a public deep-link
  destination.
- Capture one Page-building strategy for a root `App` State lifetime. Replace
  the strategy by recreating `App` with a new identity, not by silently
  retaining stale Page/DI composition or hot-swapping the Router delegate.

## Analyzer policy

- `analysis_options.yaml` groups rules by type safety, async/resource safety,
  correctness, boundaries, maintainability, Dart idioms, readability, and
  Flutter-specific behavior.
- Strict casts, strict inference, and strict raw types remain enabled. Strict
  inference rejects insufficient type information; it does not require
  repeating a type that is already obvious from an initializer.
- Only `build/**` is globally excluded from analysis. Generated source inside
  authored directories is not silently exempted by a broad path pattern; each
  generator integration must define and justify any narrower policy it needs.
- Automated fixes are reviewed before application. A mechanical fix must not
  rename or privatize a public API parameter, change ownership, or alter a
  lifecycle boundary.
- Add a suppression only for a documented false positive and keep its scope as
  narrow as possible.

## Documentation and comments

- Use `///` DartDoc for public startup, Environment, Diagnostics, DI, and
  Event Bus APIs.
- Document responsibility, intentional exclusions, ownership, lifecycle,
  failure behavior, and zone constraints where relevant.
- Add inline comments for why an ownership or failure-policy decision exists,
  not for syntax already expressed by the code.
- Keep examples privacy-safe and update them with the contract they illustrate.

## Errors and diagnostics

- Model each operational breadcrumb as one final app-owned class that extends
  `AppLogRecord`. Group related records by cohesive concern; do not recreate a
  central factory catalog or put every record in a separate file by rule.
- Give each production record one static descriptor and a synchronous
  `project` implementation that returns `AppLogProjectionResult.complete`.
  Projection code performs no I/O, scheduling, logging, reporting, lookup, or
  payload stringification.
- Keep `AppLogger.log` synchronous `void` and no-throw. Do not implement it as
  `async`, reenter the logger, call the error boundary/reporter, or install
  global handlers. An owning module may start only tracked and contained work
  after its synchronous enqueue handoff.
- Write fields only through the narrow typed writer. Runtime `Type` belongs to
  `debugType`; support fields use reviewed flags, counts, durations, and stable
  codes rather than strings, identifiers, objects, or metadata collections.
- Place the first implementation of a capability-owned semantic logging port
  under `app/diagnostics/logging/adapters` only with its real consumer. It may
  import that exact inward port, while records remain feature- and domain-free.
- Gate diagnostic detail with `kDebugMode`. A test override may reduce detail
  but never enable debug projection in profile or release; do not select this
  policy with `kReleaseMode`.
- Catch only the exact failures owned by the current operation contract.
  Implementing `Exception` does not make an arbitrary failure expected, and
  `Error` is not converted by a generic catch into an expected result.
- Use `rethrow` when propagating the same failure object. When translating a
  recognized boundary condition into a new owner-specific failure, preserve
  the caught stack with `Error.throwWithStackTrace`.
- Use `return await` inside a `try` block when its `catch` must observe an
  asynchronous completion. Returning the Future directly bypasses that catch
  after the synchronous call returns.
- Do not call `toString()` on untrusted errors or render raw configuration.
- Do not pass raw errors to logging APIs that may stringify them.
- Cleanup and reporting failures must not replace a primary failure.
- Profile and release error-report output contains stable support codes, not
  provider payloads, runtime types, or raw stacks. Typed `AppLogger`
  breadcrumbs may still contain their approved stable event fields.

## Tests

- Prefer closures and small fakes over generated mocks for narrow contracts.
- Test ownership transfer, rollback, failure ordering, lifecycle idempotence,
  and diagnostic privacy.
- Add architecture guards for important dependency-direction constraints that
  the Dart type system cannot express.
- Integration tests invoke the production entrypoint and graph with an explicit
  public environment profile.
- Startup integration scenarios run as separate processes because framework
  initialization, global Flutter handlers, and the root zone have
  application-isolate lifetime.
