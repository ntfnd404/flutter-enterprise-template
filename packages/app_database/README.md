# Application database

`app_database` is the Dart-only host for the application's shared physical
Drift database. It owns the connection, complete SQL schema, migration chain,
generated rows, and private DAOs. It is shared technical infrastructure, not a
business bounded context or a DDD Shared Kernel.

## Public boundaries

- `app_database_composition.dart` exposes configuration, storage policy,
  sanitized opening failures, and the owned database module.
- `app_database_catalog.dart` exposes only Catalog's narrow item store, stored
  records, and expected temporary store failure.
- A future context receives its own `app_database_<context>.dart` entrypoint.

The package never exports `ApplicationDatabase`, executors, DAOs, generated
rows, companions, or Drift-specific storage enums. A context maps its borrowed
store into context-owned repository and application APIs. Presentation receives
only the application facade.

## Source layout

```text
lib/src/
├── application_database.dart
├── tables.drift                       # complete authored schema manifest
├── connection/                         # physical platform connection
├── schema/application_database/        # versioned migration snapshots
└── contexts/
    └── catalog/
        └── items/
            ├── tables/                 # authored table definitions
            ├── queries/                # only real reusable named queries
            ├── dao/                    # private cohesive Drift access
            └── store/                  # records, narrow seam, and adapter
```

The `contexts` directory records logical ownership of persistence, but it does
not contain domain or application code. That code belongs to
`packages/<context>`. A cluster such as `items` groups one cohesive persistence
area. Split an oversized cluster by meaning, not by creating global DAO or
table catalogs.

`tables.drift` is the single composition manifest for the complete physical
schema. It imports context-owned table definitions while
`ApplicationDatabase` includes only that manifest. A DAO does not import the
global manifest: its `@DriftAccessor` includes only the tables and named queries
needed by that cohesive access responsibility.

A DAO is not created mechanically for every table. One DAO may coordinate
several related tables and a store may compose several DAOs. Add a separate
store only for a distinct narrow consumer contract. Do not add a second DAO
interface beneath a public store without a second implementation or another
real boundary. Public store records and store contracts use separate files so
each cross-package type remains easy to find and document; both stay in the
same cohesive `store` cluster.

## Ownership and lifecycle

App composition:

1. creates `AppDatabaseModule`;
2. registers it immediately in `AppResourceDisposalStack`;
3. awaits `initialize()`;
4. borrows context stores to build lifecycle-free context facades;
5. lets the graph close the module once in LIFO order.

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
`test/migrations/application_database/generated`. Never edit generated helpers
manually. Schema v1 is still the pre-release baseline. Add a version-to-version
migration test only with the first real v2; every data-changing migration also
needs authored fixtures and data-integrity assertions.

The root Makefile is the only command entrypoint. This package intentionally
has no separate Makefile. The real browser persistence scenario is run
headlessly through Flutter's Web Server device with `make test-database-web`
after starting a ChromeDriver compatible with the installed Chrome on local
port `4444`.

## Persisted-type rules

- Persist enum stable wire values, never Dart ordinal indices.
- Choose and test one timestamp representation before adding timestamps.
- Enable foreign keys for every connection when the first FK is introduced;
  run `foreign_key_check` after controlled migrations.
- Use triggers only for a technical invariant owned by one context. A
  cross-context workflow belongs to application coordination and may require an
  outbox or broker.
- Do not use `onlyIfTableIsEmpty`, non-atomic count-then-insert, or unconditional
  `insertOrIgnore` without an explicit transactional conflict policy.
