# Dependency and resource lifecycle

This guide explains where an integration is initialized, constructed, exposed,
and released. The normative application contract remains in
[application architecture](architecture.md); examples here illustrate how to
extend it without turning the template into a service locator or a hierarchy of
empty modules.

The DI type names in pseudocode reflect the current implementation candidate,
not a pre-approved class split. The dedicated DI audit may merge, split,
rename, or hide Builder, Graph, Owner, and DisposalStack types while preserving
the ownership and failure invariants described here.

## Lifetimes

| Lifetime | Typical owner | Examples |
|---|---|---|
| Process-global | Framework or concrete SDK initializer | Flutter binding, URL strategy, default Firebase initialization, FCM background-handler registration |
| Application | Returned app graph and its root lifecycle owner | Event bus and cohesive app/context modules registered during dependency composition |
| Session/tenant | Authenticated flow-shell owner, only after a real requirement exists | User-keyed cache, authenticated socket, tenant database |
| Feature/flow | Feature scope or flow-shell provider | BLoC shared by several feature routes |
| Page/screen | `BlocProvider(create: ...)`, provider, or `RouteScope` | Screen BLoC, editor controller, camera session |
| Operation | The method performing the operation | Request cancellation token, native operation handle, transaction |
| Background isolate | A composition root inside that isolate | Isolate-local database/proxy, plugin entrypoint collaborators |

The useful ownership rule is more precise than “dispose where created”:

> The creator must immediately choose an owner. It either keeps ownership or
> transfers it through an explicit lifecycle boundary.

Each build creates a new ownership boundary. Dependency composition fills it
with immediately registered app-owned leaves and returned modules, closes
registration on success, and returns one graph to one root lifecycle owner.
`AppDependencies` only describes what downstream composition may use; it does
not expose graph lifecycle or lookup.

## Placement decision

For each concrete integration, answer in order:

1. Does the SDK require process-global preparation before any owned instance
   can exist? Put only that preparation in the framework initializer.
2. Is this one simple app-owned leaf with no private construction transaction?
   Create it in `buildAppDependencies` and register it immediately.
3. Does the integration contain private clients, repositories, subscriptions,
   or internal partial rollback? Let a concrete module factory own them and
   register the returned module once.
4. Is an SDK value borrowed from a process-global registry? Keep it local and
   do not register it.
5. Does presentation need the concrete client or repository? No: expose the
   owning capability's application facade, command, query, or use case instead.
6. Is the resource tied to a Page or one operation? Keep it out of the app
   graph and use the narrower owner.

Do not add a module class for one ordinary object with no private lifecycle or
partial-construction risk. Direct leaf registration is clearer in that case.

## Application graph sketch

The following is placement-oriented pseudocode. The template does not add
these packages or placeholder types until a real capability selects them.

```dart
Future<AppDependencies> buildAppDependencies(
  AppResourceDisposalStack resources,
) async {
  // Simple app-owned leaf: create first so LIFO closes it last.
  final eventBus = resources.register(
    AppEventBus(),
    (eventBus) => eventBus.dispose(),
  );

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
    eventBus: eventBus,
    capability: capabilityModule.facade,
    notifications: notificationsModule.facade,
  );
}
```

This is placement-oriented pseudocode; the base scaffold does not introduce
the capability types. Real foundational resources that must outlive dependents
are created first. Sequential LIFO teardown closes later modules first and the
event bus last. Raw databases, repositories, notification plugins, and SDK
clients do not become fields of `AppDependencies` merely because composition
created them.

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
  required CapabilityCleanupFailureCallback onRollbackFailure,
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
      // This callback is guarded by the module boundary. Its failure cannot
      // replace the original initialization failure.
      await _reportCleanupSafely(onRollbackFailure, cleanupFailure);
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

A synchronous developer logger is created by the composition root before
framework initialization. It is not a disposable graph module and is not added
to `AppDependencies` merely to make it globally reachable:

```dart
void runApplication({
  AppLogger logger = const DeveloperAppLogger(),
}) {
  errorBoundary.run(() async {
    final stopwatch = Stopwatch()..start();

    logger.log(
      level: AppLogLevel.info,
      event: 'app_startup_started',
    );

    final configuration = loadAppStartupConfiguration();
    await initializeAppFramework(
      environment: configuration.environment,
      logger: logger,
    );

    final graph = await const AppDependencyGraphBuilder().build(
      dependenciesFactory: buildAppDependencies,
      onRollbackFailure: reportRollbackFailure,
    );
    final pages = buildAppPages(dependencies: graph.dependencies);

    stopwatch.stop();
    logger.log(
      level: AppLogLevel.info,
      event: 'app_startup_completed',
      elapsed: stopwatch.elapsed,
    );

    runApp(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: reportDisposalFailure,
        child: App(pageBuilder: pages.build),
      ),
    );
  });
}
```

This is the target wiring for the diagnostics and startup phases. Logger events
remain sanitized; raw errors and stack traces go to `AppErrorReporter`, not to
`AppLogger`. A buffered or remote logging transport would be a separate owned
diagnostics module because it has flush and shutdown semantics.

### Shared physical Drift module

The scaffold intentionally implements one shared physical database as described
in [ADR 0001](adr/0001_shared_application_database.md). This is infrastructure,
not a business context:

- [`app_database_composition.dart`](../packages/libraries/app_database/lib/app_database_composition.dart)
  creates and disposes the physical database module;
- [`stores/catalog.dart`](../packages/libraries/app_database/lib/stores/catalog.dart)
  exposes only the narrow catalog item/category stores;
- [`catalog.dart`](../packages/bounded_contexts/catalog/lib/catalog.dart) remains the public
  catalog application API used by presentation;
- [`catalog_composition.dart`](../packages/bounded_contexts/catalog/lib/catalog_composition.dart)
  adapts borrowed persistence into a lifecycle-free application facade.

App composition resolves a stable native path outside the Dart-only database
package, registers the module before its connection opens, then constructs
the context facade:

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
final catalogStores = databaseStores.catalog;

final catalogApplication = createCatalogApplication(
  itemsStore: catalogStores.items,
  categoriesStore: catalogStores.categories,
);
final ordering = createOrderingFacade(
  store: databaseStores.ordering.orders,
  productOffers: CatalogProductOfferAdapter(
    catalogApplication.productOffers,
  ),
  utcNow: () => DateTime.now().toUtc(),
);

return AppDependencies(
  eventBus: eventBus,
  catalog: catalogApplication.facade,
  ordering: ordering,
);
```

The root store catalog and its context bundles are synchronous, immutable,
lifecycle-free composition views. They are not dependency containers: app DI
narrows them immediately and passes only the required store contracts to each
context factory.

The module owns the connection, migration chain, generated rows, and private
DAOs. `CatalogItemsStore` and `CatalogCategoriesStore` are the real
cross-package persistence seams, so DAO interfaces beneath them would duplicate
the boundary. `StoreCatalogItemRepository` and
`StoreCatalogCategoryRepository` belong to Catalog infrastructure and map
store records/failures into context types. Their separate repository ports
remain domain-owned; `CatalogFacade` remains the only Catalog behavior injected
into Catalog presentation. The `CatalogApplication` composition result,
Published Language,
Ordering ACL, repositories, stores, and clock remain inside composition;
`OrderingFacade` is the only Ordering behavior placed in `AppDependencies`.

If opening or migration fails, Builder rollback closes the already-registered
database module and startup diagnostics receive the primary failure with its
original stack. Only SQLite `BUSY` and `LOCKED` contention is sanitized as
`CatalogStoreException`, then mapped to `CatalogPersistenceException` at the
context infrastructure boundary. Constraint, corruption, read-only, disk-full,
I/O, and
programming failures are not masked and preserve the object and stack observed
at that boundary. Direct executors preserve `SqliteException`; background
executors preserve `DriftRemoteException` and use its SQLite `remoteCause`
only for BUSY/LOCKED classification.

Database implementation files are grouped below
`src/persistence/<owner>/<cluster>/{tables,queries,dao,store}`. This records
logical schema/store ownership without moving domain or application code into
the technical database package. Authored table definitions stay in `tables`;
root `src/schema` contains only versioned migration snapshots. DAO boundaries
follow cohesive access responsibilities rather than one-interface-per-table.
A persistence-owner-level `src/persistence/<owner>/failures` is allowed only
for store
failure contracts or translation shared across that context's clusters. DAO,
table, and concrete store files remain inside their owning persistence cluster.

The module accepts one initialization attempt and exposes stores only after it
is ready. The first disposal request synchronously revokes store access;
repeated or concurrent disposal shares one Future and awaits any in-flight
initialization before closing acquired resources. This private monotonic guard
is ownership enforcement, not observable application state. Native paths must
be absolute. On Web, the default policy rejects in-memory fallback but permits
compatibility IndexedDB; a stricter policy also rejects the implementation that
cannot coordinate multiple tabs safely.

Several repositories in one context remain ordinary collaborators over one or
more narrow stores. They do not become separate runtime modules unless they own
subscriptions, workers, or other disposable resources. A future context module
with owned resources is registered after the database so LIFO disposal closes
the context before its borrowed store becomes unavailable.

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
  eventBus: eventBus,
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
  concrete adapter. The generic disposal stack imposes no timeout.
- Required workflows await their operation result. Best-effort telemetry is
  isolated and cannot fail a user workflow.

### Remote diagnostics

- The synchronous logger remains outside `AppDependencies` unless an actual
  downstream application service needs the port.
- Sentry, Crashlytics, or another buffered/remote transport is a separate
  graph-owned diagnostics module.
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

The application disposal mechanism is idempotent, sequential, and LIFO. It
attempts every disposer and throws one aggregate. Build rollback and normal
root-owner teardown each offer that aggregate to their callback
once. If the callback violates its contract and throws, only the callback
failure reaches the owner zone. DI awaits asynchronous callbacks to preserve
ordering, so a callback that performs I/O must own a bounded timeout and must
not wait indefinitely on a remote diagnostic service.

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
