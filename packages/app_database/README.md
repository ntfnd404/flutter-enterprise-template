# Application database

`app_database` is the Dart-only host for the application's shared physical
Drift database. It owns the connection, complete SQL schema, migration chain,
generated rows, and private DAOs. It is shared technical infrastructure, not a
business bounded context or a DDD Shared Kernel.

## Public boundaries

- `app_database_composition.dart` exposes configuration, storage policy,
  sanitized opening failures, the owned database module, and its typed context
  store catalog.
- `contexts/catalog.dart` exposes only Catalog's narrow item/category
  stores, typed context bundle, provider-neutral records, and expected
  temporary store failure.
- Every later context receives its own `contexts/<context>.dart` entrypoint.

The package never exports `ApplicationDatabase`, executors, DAOs, generated
rows, companions, or Drift-specific storage enums. A context maps its borrowed
store into context-owned repository and application APIs. Presentation receives
only the application facade.

## Source layout

```text
lib/src/
├── configuration/                     # typed connection configuration
├── application_database.dart
├── application_database.steps.dart     # generated versioned schema API
├── app_database_stores.dart            # typed root context-store assembly
├── tables.drift                       # complete authored schema manifest
├── connection/                         # physical platform connection
├── migrations/                         # authored global version transitions
├── schema/application_database/        # versioned migration snapshots
└── contexts/
    └── catalog/
        ├── catalog_database_stores.dart # Catalog store view and assembly
        ├── failures/                    # context-wide store failures/translation
        ├── items/
        │   ├── tables/                  # authored table definitions
        │   ├── queries/                 # only real reusable named queries
        │   ├── dao/                     # private cohesive Drift access
        │   └── store/                   # item seam, records, and adapter
        └── categories/
            ├── tables/
            ├── dao/
            └── store/                   # independent category seam
```

Public context entrypoints are grouped separately under `lib/contexts`. This
keeps a growing bounded-context API discoverable without combining unrelated
stores into one broad package barrel. This pre-release scaffold intentionally
replaced the former root-level Catalog entrypoint without a compatibility shim;
there are no supported external consumers of that unreleased API.

The `contexts` directory records logical ownership of persistence, but it does
not contain domain or application code. That code belongs to
`packages/<context>`. A cluster such as `items` groups one cohesive persistence
area. Split an oversized cluster by meaning, not by creating global DAO or
table catalogs.

`AppDatabaseModule.stores` publishes one immutable typed catalog after the
database has opened and migrated. Application composition immediately narrows
it through `stores.catalog` and passes only individual narrow stores to the
Catalog factory. The catalog and context bundle are lifecycle-free views: they
perform no lookup, I/O, caching, or disposal and are never placed in
`AppDependencies`. Adding a context extends this explicit assembly but does
not change database lifecycle logic.

`tables.drift` is the single composition manifest for the complete physical
schema. It imports context-owned table definitions while
`ApplicationDatabase` includes only that manifest. A DAO does not import the
global manifest: its `@DriftAccessor` includes only the tables and named queries
needed by that cohesive access responsibility. A multi-table persistence
cluster may expose a descriptively named table manifest, such as
`<cluster>_tables.drift`, when its DAO and the database schema both need
the same cohesive set. A one-table cluster does not add a forwarding manifest.

A DAO is not created mechanically for every table. One DAO may coordinate
several related tables and a store may compose several DAOs. Add a separate
store only for a distinct narrow consumer contract. Do not add a second DAO
interface beneath a public store without a second implementation or another
real boundary. Public store records and store contracts use separate files so
each cross-package type remains easy to find and document; both stay in the
same cohesive `store` cluster.

A context-level `contexts/<context>/failures` directory is reserved for store
failure contracts or translation shared by several clusters of that same
context. It does not contain DAOs, tables, concrete stores, domain behavior, or
become a generic global failure layer.

## Ownership and lifecycle

App composition:

1. creates `AppDatabaseModule`;
2. registers it immediately in `AppResourceDisposalStack`;
3. awaits `initialize()`;
4. narrows `module.stores` to the required context stores;
5. builds lifecycle-free context facades over those borrowed stores;
6. lets the graph close the module once in LIFO order.

The module accepts one initialization attempt. A failed instance is disposed
and replaced if retry is required. The first disposal request synchronously
revokes store access. Repeated or concurrent disposal shares one Future and
waits for an in-flight initialization before closing acquired resources. The
private monotonic lifecycle guard is not observable state and does not require
a notifier. Contexts never close borrowed stores or the physical database.

## Native and Web storage

The Flutter host adapter in `lib/app/di/modules/database` resolves an absolute
application-support path through `path_provider`. That plugin remains a root
application dependency: the Dart-only database package receives the completed
path and never imports Flutter or `path_provider`. Relative paths and
working-directory fallbacks are rejected. Native SQLite runs through
`NativeDatabase.createInBackground`.

Web defaults to `AppDatabaseWebStoragePolicy.requirePersistent`. In-memory
fallback is rejected. `unsafeIndexedDb` remains compatible with the default but
cannot safely coordinate concurrent tabs. Deployments requiring multi-tab
safety select `requireSafePersistent`, which accepts only OPFS or coordinated
IndexedDB implementations. Existing IndexedDB storage is opportunistically
moved to OPFS when Drift can do so safely.

The application configuration factory chooses `requirePersistent` explicitly.
Changing the package default must therefore not silently change application
behavior. A dart-define for this policy is added only if deployment profiles
actually require different guarantees.

`APP_STORAGE_NAMESPACE` separates physical storage for local, dev, test, and
prod profiles. It is public client configuration, not a secret. The app builds
`template_<namespace>` and `template_<namespace>.sqlite`; this package does not
import the app Environment model.

## Failures and privacy

Only SQLite `BUSY` and `LOCKED`, including extended variants, become a
sanitized temporary context-store failure. Constraint, corruption, read-only,
disk-full, I/O, and programming failures preserve the boundary error object and
stack. A direct executor preserves `SqliteException`; a background executor
preserves the outer `DriftRemoteException` and inspects its SQLite
`remoteCause` only for contention classification. The package never logs SQL,
parameters, paths, configuration, or raw vendor messages.

## Schema workflow

After changing `tables.drift`, a table, or a DAO annotation, run from the
repository root:

```text
make generate-database
make database-schema
```

Review generated sources, the versioned snapshot, and
`test/migrations/drift/application_database/generated`. `make
database-schema` uses `drift_dev make-migrations` as the single generator for
snapshots, the step-by-step helper, and schema-verifier helpers.

Migration artifacts have three distinct owners:

- `lib/src/migrations` contains authored executable version transitions;
- `test/migrations/drift/application_database/migration_test.dart` is the
  Drift-created scaffold retained by the project for structural checks of all
  version paths;
- the adjacent `generated` directory is fully regenerated and is never edited
  manually.

Handwritten schema-consistency, policy, data-transformation, and preservation
tests live separately in `test/migrations/application_database`. A migration
that changes persisted data requires real legacy fixtures; an empty generated
template is not an acceptance test.

Schema v2 is the current schema. Its v1→v2 migration converts legacy task-like
rows into incomplete drafts, adds categories and explicit product fields, and
initializes optimistic revisions. Because rebuilding an AUTOINCREMENT table can
reset SQLite's sequence to the highest surviving row, the transition also
preserves the legacy sequence explicitly. An ID issued before migration is
never reused merely because its row was deleted.

Each transition is a top-level function using the generated schema for its
target version. The registry runs the complete requested upgrade in one
transaction with foreign-key enforcement disabled and validates
`foreign_key_check` before commit. Downgrades fail closed. After every
successful create or upgrade, `beforeOpen` enables foreign-key enforcement and
verifies that SQLite accepted the setting before stores become available.

Released snapshots are immutable. Verifier helpers are reproducibly regenerated
from those snapshots and are never edited manually. A repair required by an
already-migrated installation is a new forward migration. Changing an old
transition for installations that have not traversed it requires explicit
compatibility analysis and regression fixtures; historical code is not
refactored merely for style.

Schema-version allocation is serialized by the owner of this physical
database. Parallel branches must not independently claim the same target
version; one branch rebases its transition and regenerates its snapshot after
the earlier version is accepted. A binary whose supported schema is older than
the physical database fails closed. Rolling an application binary back after a
schema upgrade is unsupported unless an explicit backward-compatibility plan
was designed before that migration.

On Web, a schema-changing deployment requires every stale tab to reload before
it accesses the upgraded database. Simultaneous application binary versions
using one physical browser database are unsupported. This version-compatibility
rule is separate from the `unsafeIndexedDb` multi-tab coordination limitation;
selecting a safer storage backend cannot make incompatible SQL versions safe.

Before releasing a migration that rebuilds a large table, test it with a
representative database size and device class. The review must account for
upgrade duration and temporary disk headroom for both the old and replacement
table. This scaffold does not invent a generic progress or recovery coordinator
before a concrete product needs migration UX.

The root Makefile is the only command entrypoint. This package intentionally
has no separate Makefile. The real browser persistence scenario is run
headlessly through Flutter's Web Server device with `make test-database-web`
after starting a ChromeDriver compatible with the installed Chrome on local
port `4444`.

## Persisted-type rules

- Persist enum stable wire values, never Dart ordinal indices.
- Protect mutable item snapshots with the explicit monotonic `revision` column;
  conditional detail/lifecycle updates increment it atomically.
- Foreign keys are enabled for every connection, and upgraded databases run
  `foreign_key_check` before opening to application code.
- Use triggers only for a technical invariant owned by one context. A
  cross-context workflow belongs to application coordination and may require an
  outbox or broker.
- Do not use `onlyIfTableIsEmpty`, non-atomic count-then-insert, or unconditional
  `insertOrIgnore` without an explicit transactional conflict policy.
