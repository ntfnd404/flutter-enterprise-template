import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/events/demo_action_completed_app_event.dart';
import 'package:template/app/routing/app_pages.dart';
import 'package:template/app/routing/app_route.dart';
import 'package:template/app/view/app.dart';
import 'package:template/core/event_bus/app_event.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';
import 'package:template/feature/activity/di/activity_scope.dart';
import 'package:template/feature/catalog/bloc/catalog_bloc.dart';

import '../../support/noop_catalog_facade.dart';
import '../../support/noop_ordering_facade.dart';

void main() {
  testWidgets(
    'routes to a screen-lifetime no-replay activity projection and back',
    (tester) async {
      final previousObserver = Bloc.observer;
      final observer = _ActivityLifecycleObserver();
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = previousObserver);
      final graph = await _buildGraph();
      var graphDisposed = false;
      addTearDown(() async {
        if (!graphDisposed) {
          await graph.dispose();
        }
      });
      final dependencies = graph.dependencies;
      final eventPublisher = dependencies.eventPublisher;
      final pages = buildAppPages(dependencies: dependencies);

      await tester.pumpWidget(
        AppDependencyGraphOwner(
          graph: graph,
          onDisposalFailure: (_, _) {},
          child: App(pageBuilder: pages.build),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('normal-app-marker')),
        findsOneWidget,
      );
      expect(find.byType(MaterialApp), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('complete-demo-action')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('demo-action-snackbar')),
        findsOneWidget,
      );
      expect(find.text('Completed actions: 1'), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey<String>('open-activity-route')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Observed since opening Activity: 0'), findsOneWidget);
      expect(
        find.text(
          'Action 1 was published before this screen subscribed and was not replayed',
        ),
        findsOneWidget,
      );
      expect(observer.created, hasLength(1));

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey<String>('normal-app-marker')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('activity-route-marker')),
        findsNothing,
      );
      expect(find.byType(ActivityScope, skipOffstage: false), findsNothing);
      eventPublisher.emit(const DemoActionCompletedAppEvent(sequence: 99));
      await tester.pump();
      expect(observer.created.single.state.observedCount, 0);

      await tester.pumpWidget(const SizedBox.shrink());
      await graph.dispose();
      graphDisposed = true;
      expect(() => eventPublisher.emit(const _ProbeEvent()), throwsStateError);
    },
  );

  testWidgets('does not replay a consumed UI action after the screen rebuilds', (
    tester,
  ) async {
    final graph = await _buildGraph();
    var graphDisposed = false;
    addTearDown(() async {
      if (!graphDisposed) {
        await graph.dispose();
      }
    });
    final dependencies = graph.dependencies;
    final pages = buildAppPages(dependencies: dependencies);

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: (_, _) {},
        child: App(pageBuilder: pages.build),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('complete-demo-action')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('demo-action-snackbar')),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(
      find.byKey(const ValueKey<String>('demo-action-snackbar')),
      findsNothing,
    );

    // Update the existing tree with the same graph. The graph owner and the
    // BLoC keep their identity, so this is a genuine rebuild rather than a new
    // listener.
    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: (_, _) {},
        child: App(pageBuilder: pages.build),
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey<String>('demo-action-snackbar')),
      findsNothing,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await graph.dispose();
    graphDisposed = true;
  });

  testWidgets('routes to Catalog and synchronizes framework back', (
    tester,
  ) async {
    final previousObserver = Bloc.observer;
    final observer = _CatalogLifecycleObserver();
    Bloc.observer = observer;
    addTearDown(() => Bloc.observer = previousObserver);
    final graph = await _buildGraph();
    var graphDisposed = false;
    addTearDown(() async {
      if (!graphDisposed) {
        await graph.dispose();
      }
    });
    final pages = buildAppPages(dependencies: graph.dependencies);

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: (_, _) {},
        child: App(pageBuilder: pages.build),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey<String>('open-catalog-route')));
    await tester.pumpAndSettle();
    expect(find.text('Catalog'), findsOneWidget);
    expect(observer.created, hasLength(1));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('normal-app-marker')),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    await graph.dispose();
    graphDisposed = true;
  });

  testWidgets('keeps one Page-building strategy per App identity', (
    tester,
  ) async {
    final eventBus = AppEventBus();
    addTearDown(eventBus.dispose);
    final pages = buildAppPages(
      dependencies: AppDependencies(
        catalog: const NoopCatalogFacade(),
        ordering: const NoopOrderingFacade(),
        eventPublisher: eventBus,
        eventSubscriber: eventBus,
      ),
    );
    const acceptedKey = ValueKey<String>('accepted-app');

    await tester.pumpWidget(App(key: acceptedKey, pageBuilder: pages.build));
    await tester.pumpAndSettle();

    await tester.pumpWidget(App(key: acceptedKey, pageBuilder: pages.build));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      const App(key: acceptedKey, pageBuilder: _replacementPageBuilder),
    );
    await tester.pump();
    expect(
      tester.takeException(),
      isA<StateError>().having(
        (error) => error.message,
        'static message',
        'App does not support replacing its Page-building strategy.',
      ),
    );

    await tester.pumpWidget(
      const App(
        key: ValueKey<String>('replacement-app'),
        pageBuilder: _replacementPageBuilder,
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('replacement-page')),
      findsOneWidget,
    );
  });

  testWidgets('keeps the root route stable on framework back', (tester) async {
    final eventBus = AppEventBus();
    addTearDown(eventBus.dispose);
    final pages = buildAppPages(
      dependencies: AppDependencies(
        catalog: const NoopCatalogFacade(),
        ordering: const NoopOrderingFacade(),
        eventPublisher: eventBus,
        eventSubscriber: eventBus,
      ),
    );

    await tester.pumpWidget(App(pageBuilder: pages.build));
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const ValueKey<String>('normal-app-marker')),
      findsOneWidget,
    );
  });

  testWidgets('restores typed Activity configuration and sequence', (
    tester,
  ) async {
    final eventBus = AppEventBus();
    final pages = buildAppPages(
      dependencies: AppDependencies(
        catalog: const NoopCatalogFacade(),
        ordering: const NoopOrderingFacade(),
        eventPublisher: eventBus,
        eventSubscriber: eventBus,
      ),
    );

    await tester.pumpWidget(App(pageBuilder: pages.build));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey<String>('complete-demo-action')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('open-activity-route')));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Action 1 was published before'),
      findsOneWidget,
    );

    await tester.restartAndRestore();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('activity-route-marker')),
      findsOneWidget,
    );
    expect(
      find.textContaining('Action 1 was published before'),
      findsOneWidget,
    );

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('normal-app-marker')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await eventBus.dispose();
  });

  testWidgets('renders privacy-safe recovery for an invalid logical URL', (
    tester,
  ) async {
    final eventBus = AppEventBus();
    final pages = buildAppPages(
      dependencies: AppDependencies(
        catalog: const NoopCatalogFacade(),
        ordering: const NoopOrderingFacade(),
        eventPublisher: eventBus,
        eventSubscriber: eventBus,
      ),
    );

    await tester.pumpWidget(App(pageBuilder: pages.build));
    await tester.pumpAndSettle();

    await tester.binding.handlePushRoute('/private~token=secret');
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('not-found-marker')),
      findsOneWidget,
    );
    expect(find.textContaining('secret'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await eventBus.dispose();
  });
}

Future<AppDependencyGraph<AppDependencies>> _buildGraph() =>
    buildAppDependencyGraph<AppDependencies>(
      dependenciesFactory: (resources) async {
        final eventBus = resources.register(
          AppEventBus(),
          (resource) => resource.dispose(),
        );

        return AppDependencies(
          catalog: const NoopCatalogFacade(),
          ordering: const NoopOrderingFacade(),
          eventPublisher: eventBus,
          eventSubscriber: eventBus,
        );
      },
      captureRollbackFailure: (_, _) {},
    );

final class _ProbeEvent extends AppEvent {
  const _ProbeEvent();
}

Page<Object?> _replacementPageBuilder(
  BuildContext context,
  AppRoute route,
) => MaterialPage<void>(
  key: route.pageKey,
  child: const SizedBox(key: ValueKey<String>('replacement-page')),
);

final class _ActivityLifecycleObserver extends BlocObserver {
  final List<ActivityBloc> created = [];

  @override
  void onCreate(BlocBase<Object?> bloc) {
    if (bloc is ActivityBloc) {
      created.add(bloc);
    }
    super.onCreate(bloc);
  }
}

final class _CatalogLifecycleObserver extends BlocObserver {
  final List<CatalogBloc> created = [];

  @override
  void onCreate(BlocBase<Object?> bloc) {
    if (bloc is CatalogBloc) {
      created.add(bloc);
    }
    super.onCreate(bloc);
  }
}
