import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/di/app_resource_disposal_exception.dart';
import 'package:template/app/di/app_resource_registrar.dart';

void main() {
  testWidgets('claims and disposes the graph when removed', (tester) async {
    var disposalCount = 0;
    final graph = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) => disposalCount += 1);
      },
    );

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: _ignoreDisposalFailure,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(disposalCount, 1);
  });

  testWidgets('rejects a second simultaneous owner without disposing winner', (
    tester,
  ) async {
    var disposalCount = 0;
    final disposed = Completer<void>();
    final showRejectedOwner = ValueNotifier<bool>(false);
    final graph = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) {
          disposalCount += 1;
          disposed.complete();
        });
      },
    );

    await tester.pumpWidget(
      ValueListenableBuilder<bool>(
        valueListenable: showRejectedOwner,
        builder: (context, showRejected, _) => Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            AppDependencyGraphOwner(
              key: const ValueKey<String>('winner'),
              graph: graph,
              onDisposalFailure: _ignoreDisposalFailure,
              child: const SizedBox(
                key: ValueKey<String>('winner-child'),
              ),
            ),
            if (showRejected)
              AppDependencyGraphOwner(
                key: const ValueKey<String>('rejected'),
                graph: graph,
                onDisposalFailure: _ignoreDisposalFailure,
                child: const SizedBox(),
              ),
          ],
        ),
      ),
    );
    showRejectedOwner.value = true;
    await tester.pump();

    expect(tester.takeException(), isA<StateError>());
    expect(disposalCount, 0);
    expect(
      find.byKey(const ValueKey<String>('winner-child')),
      findsOneWidget,
    );

    showRejectedOwner.value = false;
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('winner')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await disposed.future.timeout(const Duration(seconds: 5));

    expect(disposalCount, 1);
    showRejectedOwner.dispose();
  });

  testWidgets('rejects remounting a graph after its owner is removed', (
    tester,
  ) async {
    var disposalCount = 0;
    final graph = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) => disposalCount += 1);
      },
    );

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: _ignoreDisposalFailure,
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(disposalCount, 1);

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: _ignoreDisposalFailure,
        child: const SizedBox(),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
    expect(disposalCount, 1);
  });

  testWidgets('rejects a graph disposed before ownership handoff', (
    tester,
  ) async {
    final graph = await _buildGraph();
    await graph.dispose();

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: _ignoreDisposalFailure,
        child: const SizedBox(),
      ),
    );

    expect(tester.takeException(), isA<StateError>());
  });

  testWidgets('accepts child and reporter updates for the same graph', (
    tester,
  ) async {
    final firstReports = <AppResourceDisposalException>[];
    final secondReports = <AppResourceDisposalException>[];
    final graph = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) => throw StateError('dispose'));
      },
    );

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: (error, _) => firstReports.add(error),
        child: const SizedBox(key: ValueKey<String>('first')),
      ),
    );
    expect(find.byKey(const ValueKey<String>('first')), findsOneWidget);

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: (error, _) => secondReports.add(error),
        child: const SizedBox(key: ValueKey<String>('second')),
      ),
    );
    expect(find.byKey(const ValueKey<String>('second')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(firstReports, isEmpty);
    expect(secondReports, hasLength(1));
  });

  testWidgets('rejected replacement does not adopt the new graph', (
    tester,
  ) async {
    final acceptedFailure = StateError('accepted');
    final acceptedReports = <AppResourceDisposalException>[];
    final rejectedReports = <AppResourceDisposalException>[];
    final recoveryReports = <AppResourceDisposalException>[];
    final mode = ValueNotifier<int>(0);
    final accepted = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) => throw acceptedFailure);
      },
    );
    var rejectedDisposalCount = 0;
    final rejected = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) => rejectedDisposalCount += 1);
      },
    );

    await tester.pumpWidget(
      ValueListenableBuilder<int>(
        valueListenable: mode,
        builder: (context, value, _) => AppDependencyGraphOwner(
          graph: value == 1 ? rejected : accepted,
          onDisposalFailure: value == 1
              ? (error, _) => rejectedReports.add(error)
              : value == 2
              ? (error, _) => recoveryReports.add(error)
              : (error, _) => acceptedReports.add(error),
          child: SizedBox(
            key: ValueKey<String>(
              switch (value) {
                0 => 'accepted',
                1 => 'rejected',
                _ => 'recovery',
              },
            ),
          ),
        ),
      ),
    );
    mode.value = 1;
    await tester.pump();

    expect(tester.takeException(), isA<StateError>());
    expect(rejectedDisposalCount, 0);
    expect(rejectedReports, isEmpty);

    // Restore a valid widget configuration after the deliberately rejected
    // update. This same-graph update becomes the newly accepted child and
    // callback without ever adopting values from the rejected graph.
    mode.value = 2;
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('accepted')), findsNothing);
    expect(find.byKey(const ValueKey<String>('recovery')), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(acceptedReports, isEmpty);
    expect(rejectedReports, isEmpty);
    expect(recoveryReports, hasLength(1));
    expect(
      recoveryReports.single.failures.single.error,
      same(acceptedFailure),
    );
    expect(rejectedDisposalCount, 0);

    await rejected.dispose();
    expect(rejectedDisposalCount, 1);
    mode.dispose();
  });

  testWidgets('reports only after delayed cleanup completes', (tester) async {
    final releaseDisposer = Completer<void>();
    final reported = Completer<AppResourceDisposalException>();
    var reportCount = 0;
    final graph = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) async {
          await releaseDisposer.future;
          throw StateError('delayed dispose');
        });
      },
    );

    await tester.pumpWidget(
      AppDependencyGraphOwner(
        graph: graph,
        onDisposalFailure: (error, _) {
          reportCount += 1;
          reported.complete(error);
        },
        child: const SizedBox(),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();

    expect(reported.isCompleted, isFalse);
    expect(reportCount, 0);

    releaseDisposer.complete();
    expect(
      await reported.future.timeout(const Duration(seconds: 5)),
      isA<AppResourceDisposalException>(),
    );
    expect(reportCount, 1);
  });

  testWidgets('sends only a broken reporter to the owner zone', (tester) async {
    final reporterFailure = StateError('reporter');
    final zoneErrors = <Object>[];
    final graph = await _buildGraph(
      configure: (resources) {
        resources.register(Object(), (_) => throw StateError('dispose'));
      },
    );

    final run = runZonedGuarded(
      () async {
        await tester.pumpWidget(
          AppDependencyGraphOwner(
            graph: graph,
            onDisposalFailure: (_, _) => throw reporterFailure,
            child: const SizedBox(),
          ),
        );
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
      },
      (error, _) => zoneErrors.add(error),
    );
    if (run == null) {
      fail('Guarded zone did not return the test future.');
    }
    await run;

    expect(zoneErrors, <Object>[reporterFailure]);
  });
}

Future<AppDependencyGraph<_TestDependencies>> _buildGraph({
  void Function(AppResourceRegistrar resources)? configure,
}) => buildAppDependencyGraph<_TestDependencies>(
  dependenciesFactory: (resources) async {
    configure?.call(resources);

    return const _TestDependencies();
  },
  captureRollbackFailure: _ignoreRollbackFailure,
);

void _ignoreRollbackFailure(
  AppResourceDisposalException error,
  StackTrace stackTrace,
) {}

void _ignoreDisposalFailure(
  AppResourceDisposalException error,
  StackTrace stackTrace,
) {}

final class _TestDependencies {
  const _TestDependencies();
}
