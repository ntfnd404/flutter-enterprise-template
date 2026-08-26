import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/routing/app_pages.dart';
import 'package:template/app/view/app.dart';
import 'package:template/core/event_bus/app_event.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/activity/bloc/activity_bloc.dart';
import 'package:template/feature/activity/di/activity_scope.dart';
import 'package:ui_kit/ui_kit.dart';

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
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.theme, same(AppTheme.light));
      expect(app.darkTheme, same(AppTheme.dark));

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

      await tester.tap(find.byTooltip('Back'));
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

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(() => eventPublisher.emit(const _ProbeEvent()), throwsStateError);
    },
  );

  testWidgets('does not replay a consumed UI action after the screen rebuilds', (
    tester,
  ) async {
    final graph = await _buildGraph();
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
    await tester.pump();
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
