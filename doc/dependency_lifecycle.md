# Dependency and resource lifecycle

This guide explains where an integration is initialized, constructed, exposed,
and released. The normative application contract remains in
[application architecture](architecture.md); examples here illustrate how to
extend it without turning the template into a service locator or a hierarchy of
empty modules.

The examples use the app-local typed graph and register-only ownership boundary
defined normatively in
[Build transaction and ownership](architecture.md#build-transaction-and-ownership).
The names make the recipes concrete; this guide does not define a second DI
contract or a service-locator framework.

## Lifetimes

| Lifetime | Typical owner | Examples |
|---|---|---|
| Process-global | Framework or concrete SDK initializer | Flutter binding, URL strategy, default Firebase initialization, FCM background-handler registration |
| Root Flutter isolate | Application composition root outside the dependency graph | `AppErrorBoundary`, application BLoC observer, future `AppLoggingModule` |
| Application | Returned app graph and its root lifecycle owner | Cohesive app/context modules registered during dependency composition |
| Session/tenant | Authenticated flow-shell owner, only after a real requirement exists | User-keyed cache, authenticated socket, tenant database |
| Feature/flow | Feature scope or flow-shell provider | BLoC shared by several feature routes |
| Page/screen | `BlocProvider(create: ...)`, provider, or `RouteScope` | Screen BLoC, editor controller, camera session |
| Operation | The method performing the operation | Request cancellation token, native operation handle, transaction |
| Background isolate | A composition root inside that isolate | Isolate-local database/proxy, plugin entrypoint collaborators |

The useful ownership rule is more precise than “dispose where created”:

> The creator must immediately choose an owner. It either keeps ownership or
> transfers it through an explicit lifecycle boundary.

Each build creates a new private ownership boundary. Dependency composition
fills it with immediately registered app-owned leaves and returned modules,
the graph transaction seals registration on success, and one root lifecycle
owner claims the graph once.

`AppDependencies` only describes what downstream composition may use; it does
not expose graph lifecycle or lookup.

## Placement decision

For each concrete integration, answer in order:

1. Does the SDK require process-global preparation before any owned instance
   can exist? Put only that preparation in the framework initializer.
2. Must the capability record Environment or graph build/disposal failures and
   therefore outlive the application graph? Keep that reviewed process-root
   owner with its capability; do not force it into `app/di/modules`.
3. Is this one simple app-owned leaf with no private construction transaction?
   Create it in the app dependency factory and register it immediately.
4. Does the integration contain private clients, repositories, subscriptions,
   or internal partial rollback? Let a concrete module factory own them and
   register the returned module once.
5. Is an SDK value borrowed from a process-global registry? Keep it local and
   do not register it.
6. Does presentation need the concrete client or repository? No: expose the
   owning capability's application facade, command, query, or use case instead.
7. Is the resource tied to a Page or one operation? Keep it out of the app
   graph and use the narrower owner.

Do not add a module class for one ordinary object with no private lifecycle or
partial-construction risk. Direct leaf registration is clearer in that case.
Keep the current Database→Catalog→Ordering wiring linear and explicit. Split it
into private typed subordinate functions only when size or reuse demonstrates
a cohesive responsibility. `lib/app/di/modules` is reserved for concrete
resource-owning technical or platform composition, not arbitrary groups or a
universal module protocol.

## Application graph sketch

The following is placement-oriented pseudocode. The template does not add
these packages or placeholder types until a real capability selects them.

```dart
Future<AppDependencies> buildAppDependencies(
  AppResourceRegistrar resources,
) async {
  // The module factory owns its database/client/repositories/subscriptions.
  final capabilityModule = await buildCapabilityModule(
    configuration: capabilityConfiguration,
  );
  resources.register(
    capabilityModule,
    (module) => module.dispose(),
  );

  final notificationsModule = await buildNotificationsModule(
    configuration: notificationsConfiguration,
  );
  resources.register(
    notificationsModule,
    (module) => module.dispose(),
  );

  return AppDependencies(
    capability: capabilityModule.facade,
    notifications: notificationsModule.facade,
  );
}
```

This is placement-oriented pseudocode; the base scaffold does not introduce
the capability types. Real foundational resources that must outlive dependents
are created first. Sequential LIFO teardown closes later modules first and the
foundation last. Raw databases, repositories, notification plugins, and SDK
clients do not become fields of `AppDependencies` merely because composition
created them. The registrar cannot seal, dispose, or inspect the private
ledger, and factories must not retain it after construction.

The graph is created by the generic top-level transaction:

```dart
final graph = await buildAppDependencyGraph<AppDependencies>(
  dependenciesFactory: buildAppDependencies,
  captureRollbackFailure: collectRollbackFailure,
);
```

`collectRollbackFailure` follows the construction-failure contract in
[Build transaction and ownership](architecture.md#build-transaction-and-ownership);
it is not an outward reporter.

The typed dependency catalog receives only real app-lifetime public facades or
ports with accepted consumers, except for a bounded, tested consumer gap
recorded in the roadmap. A disposable capability such as `AppEventBus` stays
graph-owned and exposes only the non-owning roles required downstream.

The reference composition registers `AppEventBus` first and immediately. It
then lends only `AppEventPublisher` and `AppEventSubscriber` through
`AppDependencies`. LIFO disposal therefore closes feature/database dependents
before the bus. A feature subscription starts cancellation when its Page/BLoC
subtree is removed; tests unmount the tree and await the graph's same memoized
`dispose()` Future rather than inferring quiescence from one pump or delay.

## Failure-atomic assemblies

An async factory can allocate resources and fail before returning an owner.
The outer graph cannot register an object it never received, so the factory
must clean its partial state:

```dart
typedef CapabilityCleanupFailureCallback =
    FutureOr<void> Function(
      CapabilityCleanupException error,
      StackTrace stackTrace,
    );

static Future<CapabilityModule> open({
  required CapabilityCleanupFailureCallback onCleanupFailure,
}) async {
  NativeSession? session;
  StreamSubscription<Object?>? subscription;

  try {
    session = await NativeSession.open(...);
    subscription = events.listen(...);

    return CapabilityModule._(
      session: session,
      subscription: subscription,
    );
  } catch (primaryError, primaryStackTrace) {
    // `_disposeInternals` attempts every non-null resource in reverse creation
    // order and returns one aggregate instead of stopping on the first error.
    final cleanupFailure = await _disposeInternals(
      subscription: subscription,
      session: session,
    );
    if (cleanupFailure != null) {
      // This collector is guarded by the module boundary. Its failure cannot
      // replace or escape before the original initialization failure.
      await _collectCleanupSafely(onCleanupFailure, cleanupFailure);
    }
    Error.throwWithStackTrace(primaryError, primaryStackTrace);
  }
}
```

Normal `dispose()` uses the same all-attempted reverse-order helper and throws
its aggregate after all internals have been visited. The exact cleanup remains
local to the integration: `CapabilityCleanupFailureCallback` and
`CapabilityCleanupException` above are pseudocode for module-owned types, not
imports from `lib/app/di`. An app-local module may use the app-owned callback,
but a workspace package must not depend on the application shell. The example
deliberately does not introduce a universal `Module` interface. An owning
package keeps its helper private. If a second package needs the same pure-Dart
lifecycle contract, that demonstrated reuse is the trigger to promote the
generalized stack and aggregate types to a focused
lifecycle library review. Demonstrated reuse permits that review; it does not
make extraction or a new package automatic.

## Common integrations

These examples show concrete placement, but do not make every integration
mandatory. Catalog is deliberately a real Drift-backed reference capability,
not a placeholder. Remote backends, push providers, settings, and native SDKs
still appear only with a real consumer because empty modules would create
runtime and maintenance cost without behavior.

### Logger and startup timing

Diagnostics Core deliberately has no live `main.dart` consumer. It provides a
synchronous logger, a strict asynchronous local/no-op reporter, a root boundary,
and the BLoC observer as tested extension points. Raw errors and nullable
original stacks go only to `AppErrorReporter`; approved records go only to
`AppLogger`. Logger implementations complete validation and their synchronous
sink/enqueue handoff before returning; they never call the boundary or reporter.
The boundary may be reported to explicitly before `run`, without installing
handlers or claiming the global lease, while automatic coverage begins only in
`run`.

The later Startup phase creates exactly one logger identity, one fixed local or
no-op reporter, and one boundary made by a narrow factory that receives those
exact collaborators. It does not accept both a prebuilt boundary and an
independent logger, because that permits the boundary, Startup, and observer to
emit through different identities. Startup also adds its two concrete record
classes; Diagnostics Core does not predeclare them.

The practical order is:

```text
construct logger and fixed reporter
→ construct boundary from those exact collaborators
→ boundary.run
    → set debug zone-mismatch policy
    → initialize Flutter binding
    → log AppStartupStartedLogRecord
    → load Environment
    → initialize Environment-dependent framework/SDK capabilities
    → build route registry, graph, and Page catalog
    → log AppStartupCompletedLogRecord
    → runApp and hand graph ownership to the root widget
```

The binding step is a minimal configuration-free prelude. It no longer
contradicts the rule that Environment-dependent SDK initialization happens only
after Environment validation. The abbreviated recipe omits the surrounding
startup `try`/`catch`; primary-first graph rollback and reporting remain
normative in
[Build transaction and ownership](architecture.md#build-transaction-and-ownership).

The Persistent Support Log phase later replaces the standalone logger seam
atomically with one optional `AppLoggingModule`. The root composition owner
constructs that module before the reporter and boundary, gives every consumer
the exact `module.logger`, initializes the binding inside the boundary, then
starts the module's documented non-failing persistence activation before
Environment loading. It does not add the module or exporter to
`AppDependencies`, and it does not create an Environment-derived storage
namespace.

The module remains outside the graph so it can record support-safe Environment,
graph-build, rollback, disposal, and final-teardown breadcrumbs. This is a
specific lifetime decision, not a general second graph. Its native and Web
platform adapters colocate under `app/diagnostics/logging/support_log`; only
graph-owned platform adapters belong in `app/di/modules`.

Production does not pretend that Flutter supplies awaited process shutdown. A
future controlled desktop or restart flow must first stop new work, await graph
disposal and explicit reports, establish report/export quiescence, dispose the
boundary, and only then await logging-module disposal. A timeout bounds waiting
but does not cancel the provider operation beneath a Dart Future.

### Shared physical Drift module

The scaffold implements one shared physical database as described in
[ADR 0001](adr/0001_shared_application_database.md). It is infrastructure, not
a business context. Its complete package contract lives in the
[AppDatabase README](../packages/libraries/app_database/README.md).

App composition resolves the host-specific storage configuration, creates the
module, transfers it immediately to the application-lifetime owner, and only
then initializes and borrows its typed stores:

```dart
final databaseConfiguration = await createAppDatabaseConfiguration(
  storageNamespace: storageConfiguration.namespace,
);
final databaseModule = resources.register(
  createAppDatabaseModule(configuration: databaseConfiguration),
  (module) => module.dispose(),
);
await databaseModule.initialize();

final databaseStores = databaseModule.stores;
final catalogApplication = createCatalogApplication(
  itemsStore: databaseStores.catalog.items,
  categoriesStore: databaseStores.catalog.categories,
);
final ordering = createOrderingFacade(
  store: databaseStores.ordering.orders,
  productOffers: CatalogProductOfferAdapter(
    catalogApplication.productOffers,
  ),
  utcNow: () => DateTime.now().toUtc(),
);
```

The store catalog and context bundles are synchronous, immutable,
lifecycle-free composition views. App DI narrows them immediately. Contexts
borrow stores, own their repository mapping and application facades, and never
close the physical database. Only consumed facade/port views enter
`AppDependencies`; Product Offers, the Ordering ACL, repositories, stores,
clock, and module remain inside composition.

If opening or migration fails, the graph rolls back the already-owned module
before returning the preserved construction failure. Readiness, module
disposal, schema, migration, failure-classification, and platform-storage rules
belong to the AppDatabase package contract linked above. Additional
repositories remain ordinary lifecycle-free collaborators unless they acquire
subscriptions, workers, or another real owned resource.

### Typed settings over SharedPreferences

`SharedPreferencesAsync` has no application-owned close operation. If settings
composition creates no subscriptions or controllers, a disposable module would
be ceremony without an ownership purpose:

```dart
final preferences = SharedPreferencesAsync();
final settingsRepository = SettingsRepositoryImpl(
  preferences: preferences,
);
final settings = await SettingsFacadeImpl.create(
  repository: settingsRepository,
);

return AppDependencies(
  settings: settings,
);
```

These concrete types belong to the owning settings capability. Presentation
receives `SettingsFacade`, not `SharedPreferencesAsync` or the repository. If
the implementation later owns a stream, controller, or background worker, it
becomes a registered `SettingsModule` with explicit disposal.

### Firebase and Firestore

- Required default `Firebase.initializeApp` belongs to process-global framework
  initialization when the selected Firebase integration requires it before
  graph construction.
- A default `FirebaseApp`, `FirebaseFirestore.instance`, and
  `FirebaseMessaging.instance` are normally borrowed registry values.
- Per-instance settings must be applied at the owning integration boundary
  before first use, following the selected SDK contract.
- Firestore listeners, token streams, and application-created subscriptions
  are owned by the adapter/module that created them.
- A secondary explicitly created Firebase app may have different ownership;
  follow its actual delete contract rather than treating every Firebase value
  as process-global.

### Push notifications and FCM

- Background handler registration is process-global and uses the plugin's
  required top-level entrypoint.
- Notification permission prompts are user-driven workflows, not framework
  initialization.
- Token retrieval and message/opened-app subscriptions belong to a
  notifications service or module.
- The module exposes a narrow application facade only when app/feature
  composition has a real consumer.

### Drift

- `AppDatabaseModule` owns the one implemented physical database, SQL schema,
  versioned snapshots, migrations, and private DAOs.
- Each context receives a separate narrow store. It never receives the raw
  database or a generated row through its public application API.
- Repository implementations remain inside their owning contexts and map store
  records into context types. Presentation receives only facade/query/command
  APIs.
- A second physical database remains valid when a future context needs stronger
  isolation; sharing the current file is not mandatory.
- Context-owned subscriptions or modules are created after the database so LIFO
  closes them first.
- A Drift isolate or background connection follows Drift's supported proxy
  mechanism; a raw database object is not sent through a Dart isolate message.
- `make database-schema` refreshes the versioned snapshot, step helper, and
  verifier under `test/migrations/drift/application_database/generated` after
  every schema change. Handwritten migration tests remain separate under
  `test/migrations/application_database`.
  The current-schema test validates a fresh runtime database against the latest
  committed snapshot. The v1→v2 Catalog migration and v2→v3 Ordering migration
  demonstrate required version-to-version coverage. Data-changing migrations
  also need authored data-integrity fixtures; generated files are never edited
  manually.
- `web/drift_worker.js` and `web/sqlite3.wasm` are versioned runtime artifacts.
  Upgrade them with their locked Dart packages and serve WASM with the
  `application/wasm` content type.

### Native SDK resources

- Process/native library preparation belongs to framework initialization only
  when the SDK
  explicitly requires it.
- Long-lived native sessions are module-owned and graph-registered.
- Operation objects such as sessions, handles, or buffers are released in the
  operation's `try/finally` according to the selected binding's API.
- Never invent `dispose` for a vendor type that has no such contract, and never
  rely on application teardown to persist a transfer.

```dart
Future<OperationResult> executeOperation(OperationInput input) async {
  final operation = NativeOperationHandle.open(input);
  try {
    return operation.execute();
  } finally {
    operation.release();
  }
}
```

### HTTP, RPC, and WebSocket

- An application-created HTTP/RPC client is registered by the graph or its
  owning module; an injected test-harness client is borrowed.
- A WebSocket module owns reconnect timers, subscriptions, controllers, and the
  socket, and closes them in its contract-specific order.
- Request timeout, cancellation, retry, and abort semantics belong to the
  concrete adapter. The generic graph imposes no timeout.
- Required workflows await their operation result. Best-effort telemetry is
  isolated and cannot fail a user workflow.

### Remote diagnostics

- The app-wide `AppLogger` remains outside `AppDependencies`. A downstream
  capability with a real need owns a narrower semantic port; the app adapter
  translates that port to one reviewed record type. Its first concrete
  implementation belongs under `app/diagnostics/logging/adapters`, is
  stateless/non-owning, and imports only that exact inward port plus the logger
  and record. No directory, adapter base, or generic translation registry is
  created before the consumer.
- The accepted root boundary keeps one fixed local or no-op reporter. It does
  not expose a mutable provider registry.
- Sentry, Crashlytics, or another buffered transport requires a reviewed
  reporter-handoff policy. Its SDK resource may later be graph-owned, but the
  boundary is installed before that graph and cannot borrow it implicitly.
- The future persistent support log is bounded local operational history, not a
  reporter placeholder or automatic upload queue.
- Features do not receive a global logger by default. Raw errors,
  configuration, BLoC events, and state payloads are never logged.

### Camera, BLE, and platform sessions

- A session used by one Page belongs to that Page scope, not the app graph.
- Permission requests are user-driven operations.
- Native callbacks are detached before closing the native session.
- Move a session to app/session lifetime only when background behavior is a
  real product requirement.

## Feature delivery

Application Page composition reads the catalog once and passes narrow ports:

```text
AppDependencies
  → buildAppPages
      → buildCapabilityPageDefinition(facade: dependencies.capability)
          → CapabilityScope(facade: facade)
              → BlocProvider(create: (_) => CapabilityBloc(facade))
                  → CapabilityScreen
```

The Page builder captures dependencies but owns none of them. It is
synchronous and may run repeatedly. It must not start I/O, navigate, mutate
route state, or allocate a disposable resource. Page-owned resources are
created below the Page through `BlocProvider`, another provider, or
`RouteScope`.

## Teardown and durability

The exact graph states, handoff authority, LIFO failure behavior, reentrancy
protection, and reporting/privacy contracts are defined only in
[Build transaction and ownership](architecture.md#build-transaction-and-ownership).
This guide focuses on their practical consequence: cleanup is a resource
release boundary, not a durability protocol.

Flutter does not await `State.dispose`, and a mobile OS may kill the process
without any teardown. Therefore:

- subscription cancellation begins before the first asynchronous gap in the
  owning `close` method;
- required persistence completes inside an awaited repository/use-case call;
- database writes use transactions where atomicity matters;
- retryable remote commands use idempotency/recovery appropriate to the
  integration;
- `dispose` releases resources but is never the only correctness boundary.

Do not close the app graph on pause, inactive, or background lifecycle events.
A future controlled session switch defines its own quiescence policy rather
than turning the application graph into a task tracker.

## Session and isolate extension points

The base scaffold has no auth/tenant implementation and therefore no empty
session graph. With the first real requirement, an authenticated flow shell
owns a distinct session graph. It prevents new session work, removes session
UI, resolves the capability-specific in-flight policy, and disposes session
resources without replacing the application graph.

Every background isolate composes its own dependencies. It receives only
serializable inputs and returns serializable outputs. Main-isolate repositories,
clients, databases, the event bus, and `AppDependencies` never cross the
boundary unless a concrete SDK explicitly documents a supported proxy.
