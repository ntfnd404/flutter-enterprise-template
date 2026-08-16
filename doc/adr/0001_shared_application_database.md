# ADR 0001: Shared physical application database

## Status

Accepted for the reference scaffold.

## Context

The scaffold needs an executable persistence example and must also demonstrate
how several future bounded contexts can use one physical Drift database without
passing a raw database, DAO, or repository into presentation. Keeping Drift in
the reference Catalog context made the first example simple, but it left schema
and migration ownership undefined when a second context needed the same file.

## Decision

`packages/libraries/app_database` owns the physical connection, complete schema,
migration chain, generated rows, and private DAOs. It is technical application
infrastructure, not a bounded context and therefore is not listed as a context
in `architecture/context_map.yaml`.

The context map records business context-to-context relationships. The
technical dependency on `app_database` is instead constrained by architecture
guards: context domain/application code and presentation cannot import it, and
context infrastructure/composition may use only its narrow store entrypoints.

Each context receives a separate narrow store entrypoint. A context
infrastructure adapter
maps store records and failures into its own domain/application types. Context
application APIs, presentation, and `AppDependencies` do not expose stores,
DAOs, generated rows, or the physical database.

App composition registers the database module once before constructing context
facades. Contexts borrow stores and do not close them. Any future context module
with owned resources is registered after the database, so LIFO teardown closes
the context before the shared connection.

Context-owned persistence is grouped under
`src/persistence/<owner>/<cluster>`. A cluster separates authored table files,
optional named queries, private DAOs, and narrow stores. The root `src/schema`
contains versioned migration snapshots rather than authored table definitions.
Logical ownership remains with the context even though schema migration and
physical connection ownership are centralized. Direct cross-context table
access is forbidden.

## Consequences

- All schema changes share one migration version and require coordinated review.
- The database is shared technical infrastructure with a coordinated schema
  lifecycle; it is not a DDD Shared Kernel.
- The package depends on no presentation or context implementation code.
- Separate context databases remain valid for future capabilities requiring
  stronger release, security, scaling, or transaction isolation.
- A repository remains in its context. Multiple repositories do not create a
  new runtime module unless they own disposable resources.
- A narrow store is the persistence seam; a second DAO interface beneath the
  private Drift DAO would duplicate the same boundary without active variation.
