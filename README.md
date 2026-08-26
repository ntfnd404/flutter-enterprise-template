# template

Enterprise-oriented Flutter application scaffold with manual constructor
injection, transactional dependency-graph construction, explicit resource
ownership, typed diagnostics, BLoC presentation foundations, documented
cross-feature best-effort notifications, and executable DDD reference contexts
over a shared Drift persistence host.

This repository is the reusable scaffold itself, so its package name remains
`template`. An application created from the scaffold should adopt its own
package and platform names as part of initial project setup.

The target architecture is normative in
[application architecture](doc/architecture.md). The
[architecture roadmap](doc/roadmap.md) distinguishes that target from the
packages and runtime phases already accepted in Git; a file present only in a
mixed working tree is not an accepted scaffold capability.

## Requirements

- Flutter 3.47.0 stable.
- Dart constraint `^3.13.0`; Flutter 3.47.0 bundles Dart 3.13.0.
- JDK 17 for Android Gradle builds.
- GNU Make for the convenience commands below, or the equivalent Flutter and
  Dart commands from the `Makefile`.

Confirm the selected Android JDK with `flutter doctor -v`. If Flutter selects a
different runtime, configure the local JDK 17 installation with
`flutter config --jdk-dir=<jdk-17-home>` and restart the editor.

## Getting started

```text
flutter pub get
make check-config
make run-local
```

Flutter dart-defines are public client configuration. Never place passwords,
private keys, service-account credentials, or private tokens in
`env/*.env`.

## Startup flow

The accepted Startup runtime applies Source of Truth v9 through one testable
composition root and one subordinate `initializeAppFramework` function. Its
responsibility order is:

```text
main → runApplication
  → install one AppErrorBoundary
  → initialize Flutter binding inside its Zone
  → load and validate AppStartupConfiguration
  → call the subordinate initializeAppFramework function
  → build AppDependencies inside a transactional ownership boundary
  → runApp mounts one root Flutter lifecycle owner and the normal application
  → record successful startup completion after runApp returns
  → on failure, clean up before mounting a privacy-safe fallback
```

`initializeAppFramework` configures only process/root-isolate global state,
such as URL policy and the application BLoC observer. Database connections,
repositories, network clients, subscriptions, and other app-lifetime resources
are created by dependency composition so rollback and teardown have an owner.

See [application architecture](doc/architecture.md) for the complete ownership,
failure, event, and feature-DI contracts. Coding and naming rules live
in [code style](doc/code_style.md). Ordered work and capability-gated changes
that are intentionally deferred from the base scaffold are recorded in the
[architecture roadmap](doc/roadmap.md).

## Project structure

```text
lib/
├── main.dart                 # One-line production entrypoint
├── app/                      # Application shell and app-wide policies
│   ├── environment/          # Typed public client configuration
│   ├── di/                   # App graph construction and ownership
│   ├── diagnostics/          # Root handlers and privacy-safe diagnostics
│   ├── events/               # Best-effort cross-feature AppEvent contracts
│   ├── startup/              # Composition root and framework initialization
│   └── view/                 # Framework/application wrappers, not feature screens
├── core/
│   ├── di/typedefs/          # Construction-only Factory vocabulary
│   └── event_bus/            # Domain-neutral event delivery mechanism
└── feature/
    └── <name>/               # Future BLoC, DI, and view slice

env/                          # Public dart-define profiles
doc/                          # Authored project documentation
integration_test/             # Real-entrypoint smoke tests
test/                         # Unit, widget, and architecture tests
tool/                         # Private development utilities
packages/
├── bounded_contexts/
│   ├── catalog/              # Business domain/application/infrastructure
│   └── ordering/             # Downstream context and Catalog ACL
└── libraries/
    ├── app_database/         # Shared physical Drift host and narrow stores
    └── <future capability>/  # Added only in its accepted phase
```

This tree shows the architectural target. See the
[architecture roadmap](doc/roadmap.md) for the accepted Git state, current
review order, and temporary differences between the target and implementation.

`packages` is the Pub workspace container, not an application layer.
`bounded_contexts` contains business-model boundaries; `libraries` is a
repository category for reusable technical and foundation packages. The latter
name is unrelated to a Dart `library` declaration and does not mean a DDD
Shared Kernel.

`packages/bounded_contexts/catalog` is an executable product-catalog bounded
context rather than an empty layer demonstration. It owns product/category
entities, value objects, publication policy, repository port and adapter,
application facade, and a narrow Product Offers contract for downstream
contexts. `packages/libraries/app_database` owns the single physical Drift
connection, SQL schema, migrations, private DAOs, and the narrow item/category
stores. Target Catalog presentation receives only the facade; it never sees a
store, DAO, repository, or database.

`packages/bounded_contexts/ordering` is the downstream reference context in
the target. It owns the persistent Order aggregate and translates Catalog's
Product Offers contract through an Ordering-owned Anti-Corruption Layer.
Catalog never imports Ordering, and their query and write do not share a
transaction.

`AppDependencies` is the downstream delivery catalog, not a list of everything
constructed by the graph. Context composition creates private repositories over
borrowed stores; application services retain those repositories and expose only
facades or other narrow ports through `AppDependencies`. Presentation never
receives a repository, store, module, database, or vendor client.

The accepted normal and fallback wrappers deliberately use Flutter Material
defaults. A future UI kit remains an autonomous capability rather than a
Startup or routing prerequisite.

A technical capability stays with its current owner until a real package
boundary is justified by reuse, an independently useful public API, multiple
platform/provider implementations, separate ownership or lifecycle, or
materially independent testing, versioning, or delivery. These are entry
criteria for architectural review, not instructions to create placeholder
packages.

Catalog text limits use grapheme clusters, prices use integer minor units,
lifecycle statuses have explicit wire values, and mutable item snapshots carry
an optimistic revision. Persisted values are rehydrated strictly. Conditional
updates prevent concurrent draft edits or category deactivation from violating
the publication policy.

## Environment profiles

| File | Purpose | Version control |
|---|---|---|
| `env/local.env` | Local development | Tracked |
| `env/dev.env` | Shared development deployment | Tracked |
| `env/test.env` | Integration-test launch profile | Tracked |
| `env/prod.env` | Production public client profile | Tracked |

`test.env` uses the normal production graph. It is a launch profile, not a
separate runtime architecture. Its distinct `APP_STORAGE_NAMESPACE=test`
prevents integration data from sharing physical storage with `local`.

All tracked profiles use hash URLs as the safe hosting-independent default.
Path URLs remain supported only as a derived-deployment opt-in with server
rewrites and direct-refresh integration tests.

Every tracked profile contains public client configuration only. Deployment
systems may provide another validated profile path when public endpoint values
differ, but secrets always belong outside Flutter dart-defines.

### CI/CD environment contract

File-level validation is a required build preflight.
`loadAppStartupConfiguration()` can validate injected values at runtime, but a
compiled Flutter application cannot inspect the original profile for unknown or
duplicate keys. CI/CD must validate the exact same file immediately before
passing it to Flutter:

```text
make check-env ENV_FILE=env/prod.env
flutter build <target> --dart-define-from-file=env/prod.env
```

`make check` validates every tracked profile. A deployment-generated profile
must additionally use `make check-env ENV_FILE=<path>`.

### Adding an environment key

Environment keys have one canonical Dart declaration in
`AppEnvironmentKeys`. To add a key:

1. Add it to `AppEnvironmentKeys.required`.
2. Read it only in `app_environment_loader.dart`.
3. Add the raw input to `AppStartupConfiguration.fromValues` and parse it in
   its narrow owning configuration. Package-specific values do not belong in
   `AppEnvironment`.
4. Update `local`, `dev`, `test`, and `prod` profiles.
5. Pass the parsed file value from `DartDefineFileValidator` through the same
   typed factory used by runtime startup.
6. Add valid, missing, empty, invalid, and privacy tests, including an invalid
   value test proving that the CLI validator reaches the runtime parser.
7. Run `make check-config`; CI/CD must additionally run `make check-env` for
   the exact deployment file immediately before its build.

The
[package-specific configuration recipe](doc/architecture.md#adding-a-package-specific-compile-time-configuration)
shows how a future owning package defines `<Capability>Configuration`, how the
startup aggregate retains it, and where composition must narrow it.

Profile files, Makefile commands, and CI necessarily repeat the external wire
name. Validation and tests keep those representations aligned; they are not
used as independent Dart allowlists.

## Development commands

```text
make analyze
make test
make generate-database
make database-schema
make test-database-web
make check-env ENV_FILE=<path>
make check-config
make docs
make check
make run-local
make run-dev
make run-prod
```

`make check` intentionally excludes device-dependent integration scenarios,
which are added in their dedicated roadmap phase and run as separate
processes. `make test-database-web` drives real Chrome headlessly through the
Flutter Web Server device and verifies that WASM-backed data survives closing
and recreating the database module. Start a ChromeDriver compatible with the
installed Chrome on local port `4444` before running that target; the driver is
test infrastructure and is not committed to the application repository. The
Web Server device intentionally avoids the known Flutter/DWDS Chrome debug
connection race while exercising the same browser storage implementation.

## Adapting the scaffold

1. Rename the package in `pubspec.yaml` and replace `package:template/...`
   imports in the derived application.
2. Update Android, iOS, desktop, and Web application identifiers and display
   names.
3. Replace the demo presentation features while preserving their ownership
   patterns where applicable.
4. Use `packages/bounded_contexts/catalog` as the reference when creating a
   real `packages/bounded_contexts/<context>`; keep technical packages under
   `packages/libraries` and do not create global domain/data packages or empty
   layers.
5. Let that context own its typed `<Capability>Configuration.fromValues`, while
   the application environment loader remains the sole dart-define reader.
6. Put only required process-global SDK preparation in
   `initializeAppFramework`. Build an app-lifetime integration in its owning
   module factory, register the returned module once through
   `AppResourceRegistrar`, and expose only consumed application facades through
   `AppDependencies`. Private repositories remain behind those facades. If
   presentation later needs `AppEventBus`, graph composition owns the concrete
   disposable instance while consumers receive only non-owning
   publisher/subscriber roles.
7. Regenerate Drift sources with `make generate-database` after SQL or DAO
   annotation changes. After every schema change, run `make database-schema`
   and review the snapshot plus generated verifier under
   `test/migrations/drift/application_database`. Keep version-to-version and
   authored tests under `test/migrations/application_database`. Add a
   version-to-version test for every transition and a data-integrity fixture
   whenever a migration transforms data. The current v1→v2 Catalog migration
   is the data-migration reference; the v2→v3 Ordering migration demonstrates
   an additive context schema. Keep the checked-in Web worker and WASM versions
   aligned with the locked Drift and sqlite3 versions.
8. Add context-owned persistence below
   `packages/libraries/app_database/lib/src/persistence/<context>/<cluster>`,
   separating authored tables, optional named queries, private DAOs, and narrow
   stores. Root
   `src/schema` remains reserved for migration snapshots.
9. Add a real external-system integration flow with the first remote adapter.

Detailed placement examples for Firebase, FCM, Drift, native SDK resources,
network clients, Page resources, sessions, and isolates are in
[dependency lifecycle](doc/dependency_lifecycle.md).

## License

The scaffold is available under the [MIT License](LICENSE).

## Scaffold extension points

The scaffold may retain a public extension point before production code needs
it when the API represents a chosen pattern, has a concrete future scenario,
is documented and tested, adds no runtime initialization, and does not imply
that every feature must copy it.

Target extension points, accepted only in their roadmap phases, are:

- `Factory<T>`: feature-local construction without runtime parameters.
- `AppEventBus`: the neutral delivery mechanism in `core/event_bus`.
- `app/events`: concrete best-effort cross-feature `AppEvent` notifications
  delivered by the bus. They are not durable DDD integration events.

These APIs are not reasons to add artificial callers, runtime services, or
matching boilerplate to every feature.

## Deferred application UI

The accepted scaffold contains a router-free normal wrapper and a privacy-safe
pre-graph startup fallback. It does not yet contain a routing implementation,
feature presentation, UI kit, or localization. A multi-screen routing and
reference-presentation phase follows only after this handoff is stable.
