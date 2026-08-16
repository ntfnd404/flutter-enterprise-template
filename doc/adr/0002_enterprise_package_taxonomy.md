# ADR 0002: Enterprise package taxonomy

## Status

Accepted for the reference scaffold.

## Context

The scaffold is intended for applications with several business bounded
contexts and several reusable technical capabilities. Keeping every package
directly below `packages/` obscures that distinction: a business model such as
Catalog appears architecturally equivalent to a physical database host or UI
kit. The ambiguity encourages technical libraries to accumulate business
logic, and it makes the intended growth model of the scaffold hard to read.

The repository needs a taxonomy that communicates ownership without creating
empty placeholder packages or a deep hierarchy of speculative technical
categories.

## Decision

Workspace packages are grouped into exactly two architectural categories:

```text
packages/
├── bounded_contexts/
│   └── <context>/
└── libraries/
    └── <capability>/
```

`packages` is the physical container for independently resolved Dart and
Flutter workspace packages. It is not an architectural layer and does not
imply that its children share business or runtime responsibilities.

`bounded_contexts` contains a business model with its own Ubiquitous Language,
invariants, application boundary, failure model, and ownership. Its internal
layers are responsibility-driven; the reference contexts use `domain`,
`application`, `infrastructure`, and `composition` only where they have active
behavior.

`libraries` is a repository taxonomy category for reusable technical or
foundation capabilities without an authoritative business model. It is not a
Dart `library` declaration, does not change package imports, and does not mean
a DDD Shared Kernel. Examples include the physical database host, secure
storage adapter, device bridge, observability, analytics abstraction, and UI
kit. The category is not permission to create `common`, `utils`, `core`, or
other unowned code catalogs.

The root Flutter application remains the composition and presentation host.
Repository-private scripts remain under `tool/`; a tooling package is added
only for a reusable generator, lint, or build capability with a real consumer.

A technical capability remains with its current application or bounded-context
owner until a separate package boundary has a concrete driver. At least one of
the following must be true before extraction is considered:

- it has more than one real consumer;
- it exposes a stable independently useful public contract;
- it has multiple provider or platform implementations behind that contract;
- it has separate ownership or resource lifecycle;
- it materially benefits from independent testing, versioning, or delivery.

Meeting one entry criterion permits an extraction review; it does not make a
new package mandatory. The review must still show that the boundary improves
cohesion and dependency control more than it adds release and maintenance
cost.

Dart package names and import identifiers do not encode their physical group.
For example, the physical package
`packages/bounded_contexts/catalog` remains `package:catalog`, while
`packages/libraries/app_database` remains `package:app_database`.

Workspace globs are enabled only when each glob has at least one real package.
No placeholder package or `.gitkeep` exists merely to satisfy Pub workspace
resolution.

Problem-space decomposition and source topology are related but distinct.
Domains and subdomains describe the business problem, while bounded contexts
define the model, language, API, ownership, and dependency boundary used to
solve it. The reference Context Map records that relationship explicitly;
source packages remain organized by bounded context rather than by `domain` or
`subdomain` directories.

## Dependency rules

- The root application may compose bounded-context and library public APIs.
- A bounded context's infrastructure or composition may depend on narrow
  library contracts.
- A downstream context's infrastructure ACL may depend on an upstream public
  inter-context contract.
- Libraries never depend on bounded contexts.
- Domain and application code never depend on `app_database`.
- No package imports another package's `lib/src` implementation.
- Presentation receives application facades, not repositories, stores, or
  vendor clients.

Authentication is classified by responsibility, not vocabulary. Identity,
roles, access policy, authorization, and lifecycle form an `identity_access`
bounded context. An OAuth client, keychain adapter, or biometric bridge remains
a library when it is only technical integration.

## Consequences

- The repository topology visibly distinguishes business ownership from
  reusable technical capabilities.
- Adding a package requires choosing and documenting its architectural kind.
- Package paths become one level deeper, while Dart imports remain stable.
- Contexts do not need identical directory trees; responsibilities determine
  which adapters and layers exist.
- An extraction from a library into a bounded context, or the reverse, is an
  architectural change requiring ownership and migration analysis rather than
  a directory-only rename.
- Empty illustrative packages and speculative top-level groups are forbidden.
