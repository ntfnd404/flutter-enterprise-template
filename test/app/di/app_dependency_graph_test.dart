import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_resource_disposal_exception.dart';
import 'package:template/app/di/app_resource_registrar.dart';

void main() {
  group('construction', () {
    test('returns typed dependencies and closes registration', () async {
      late AppResourceRegistrar capturedResources;
      final owned = Object();
      var disposalCount = 0;

      final graph = await buildAppDependencyGraph<_TestDependencies>(
        dependenciesFactory: (resources) async {
          capturedResources = resources;
          resources.register(owned, (_) => disposalCount += 1);

          return const _TestDependencies('ready');
        },
        captureRollbackFailure: _ignoreRollbackFailure,
      );

      expect(graph.dependencies.value, 'ready');
      expect(disposalCount, 0);
      expect(
        () => capturedResources.register(Object(), (_) {}),
        throwsStateError,
      );

      await graph.dispose();

      expect(disposalCount, 1);
    });

    test('creates an independent ownership boundary per build', () async {
      final registrars = <AppResourceRegistrar>[];
      var disposalCount = 0;

      Future<AppDependencyGraph<_TestDependencies>> build() =>
          buildAppDependencyGraph<_TestDependencies>(
            dependenciesFactory: (resources) async {
              registrars.add(resources);
              resources.register(Object(), (_) => disposalCount += 1);

              return const _TestDependencies('ready');
            },
            captureRollbackFailure: _ignoreRollbackFailure,
          );

      final first = await build();
      final second = await build();

      expect(registrars, hasLength(2));
      expect(identical(registrars.first, registrars.last), isFalse);

      await first.dispose();
      expect(disposalCount, 1);

      await second.dispose();
      expect(disposalCount, 2);
    });

    test('rejects one resource identity registered twice', () async {
      final resource = Object();
      var disposalCount = 0;

      await expectLater(
        buildAppDependencyGraph<_TestDependencies>(
          dependenciesFactory: (resources) async {
            resources
              ..register(resource, (_) => disposalCount += 1)
              ..register(resource, (_) => disposalCount += 1);

            return const _TestDependencies('unreachable');
          },
          captureRollbackFailure: _ignoreRollbackFailure,
        ),
        throwsStateError,
      );

      expect(disposalCount, 1);
    });

    test('allows equal resources with different identities', () async {
      final first = _EqualResource();
      final second = _EqualResource();
      var disposalCount = 0;

      final graph = await buildAppDependencyGraph<_TestDependencies>(
        dependenciesFactory: (resources) async {
          resources
            ..register(first, (_) => disposalCount += 1)
            ..register(second, (_) => disposalCount += 1);

          return const _TestDependencies('ready');
        },
        captureRollbackFailure: _ignoreRollbackFailure,
      );

      await graph.dispose();

      expect(disposalCount, 2);
    });
  });

  group('rollback', () {
    test('preserves a synchronous factory error and original stack', () async {
      final primary = StateError('synchronous primary');
      final primaryStack = StackTrace.fromString('synchronous-primary-stack');
      var disposalCount = 0;

      try {
        await buildAppDependencyGraph<_TestDependencies>(
          dependenciesFactory: (resources) {
            resources.register(Object(), (_) => disposalCount += 1);
            Error.throwWithStackTrace(primary, primaryStack);
          },
          captureRollbackFailure: _ignoreRollbackFailure,
        );
        fail('Graph construction must fail.');
      } catch (error, stackTrace) {
        expect(error, same(primary));
        expect(
          stackTrace.toString(),
          contains('synchronous-primary-stack'),
        );
      }

      expect(disposalCount, 1);
    });

    test('preserves the primary error and original stack', () async {
      final primary = StateError('primary');
      final primaryStack = StackTrace.fromString('primary-stack');
      var disposalCount = 0;
      final captured = <AppResourceDisposalException>[];

      try {
        await buildAppDependencyGraph<_TestDependencies>(
          dependenciesFactory: (resources) {
            resources.register(Object(), (_) => disposalCount += 1);

            return Future<_TestDependencies>.error(primary, primaryStack);
          },
          captureRollbackFailure: (error, _) => captured.add(error),
        );
        fail('Graph construction must fail.');
      } catch (error, stackTrace) {
        expect(error, same(primary));
        expect(stackTrace.toString(), contains('primary-stack'));
      }

      expect(disposalCount, 1);
      expect(captured, isEmpty);
    });

    test(
      'waits for complete LIFO rollback and captures failures once',
      () async {
        final primary = StateError('primary');
        final firstCleanup = StateError('first cleanup');
        final secondCleanup = StateError('second cleanup');
        final releaseCleanup = Completer<void>();
        final cleanupStarted = Completer<void>();
        final timeline = <String>[];
        final captured = <AppResourceDisposalException>[];

        final build = buildAppDependencyGraph<_TestDependencies>(
          dependenciesFactory: (resources) {
            resources
              ..register(Object(), (_) {
                timeline.add('first');
                throw firstCleanup;
              })
              ..register(Object(), (_) async {
                timeline.add('second_started');
                cleanupStarted.complete();
                await releaseCleanup.future;
                timeline.add('second_finished');
                throw secondCleanup;
              });

            return Future<_TestDependencies>.error(primary);
          },
          captureRollbackFailure: (error, _) {
            timeline.add('captured');
            captured.add(error);
          },
        );

        await cleanupStarted.future;
        expect(timeline, <String>['second_started']);

        releaseCleanup.complete();
        await expectLater(build, throwsA(same(primary)));

        expect(
          timeline,
          <String>['second_started', 'second_finished', 'first', 'captured'],
        );
        expect(captured, hasLength(1));
        expect(
          captured.single.failures.map((failure) => failure.error),
          <Object>[secondCleanup, firstCleanup],
        );
      },
    );

    test('a broken rollback collector never replaces the primary', () async {
      final primary = StateError('primary');
      final cleanup = StateError('cleanup');
      var captureCount = 0;

      await expectLater(
        buildAppDependencyGraph<_TestDependencies>(
          dependenciesFactory: (resources) {
            resources.register(Object(), (_) => throw cleanup);

            return Future<_TestDependencies>.error(primary);
          },
          captureRollbackFailure: (_, _) {
            captureCount += 1;
            throw StateError('collector');
          },
        ),
        throwsA(same(primary)),
      );

      expect(captureCount, 1);
    });
  });

  group('disposal', () {
    test('runs every disposer once in reverse registration order', () async {
      final timeline = <String>[];
      final borrowed = Object();
      final graph = await buildAppDependencyGraph<_TestDependencies>(
        dependenciesFactory: (resources) async {
          resources
            ..register('first', (resource) => timeline.add(resource))
            ..register('second', (resource) async {
              await Future<void>.delayed(Duration.zero);
              timeline.add(resource);
            });

          return _TestDependencies(borrowed);
        },
        captureRollbackFailure: _ignoreRollbackFailure,
      );

      await graph.dispose();

      expect(timeline, <String>['second', 'first']);
      expect(graph.dependencies.value, same(borrowed));
    });

    test('returns the exact same future before and after success', () async {
      final release = Completer<void>();
      final graph = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) => release.future);
        },
      );

      final first = graph.dispose();
      final concurrent = graph.dispose();

      expect(identical(first, concurrent), isTrue);

      release.complete();
      await first;

      final completed = graph.dispose();
      expect(identical(first, completed), isTrue);
      await completed;
    });

    test('continues cleanup and preserves each error and stack', () async {
      final firstError = StateError('first secret');
      final firstStack = StackTrace.fromString('first-stack');
      final secondError = ArgumentError('second secret');
      final secondStack = StackTrace.fromString('second-stack');
      final timeline = <String>[];
      final graph = await _buildGraph(
        configure: (resources) {
          resources
            ..register('last', (resource) => timeline.add(resource))
            ..register(
              Object(),
              (_) => Future<void>.error(firstError, firstStack),
            )
            ..register(
              Object(),
              (_) => Future<void>.error(secondError, secondStack),
            )
            ..register('first', (resource) => timeline.add(resource));
        },
      );

      final first = graph.dispose();
      final concurrent = graph.dispose();
      final exception = await _captureDisposalException(first);

      expect(identical(first, concurrent), isTrue);
      expect(timeline, <String>['first', 'last']);
      expect(exception.failures, hasLength(2));
      expect(exception.failures[0].error, same(secondError));
      expect(
        exception.failures[0].stackTrace.toString(),
        contains('second-stack'),
      );
      expect(exception.failures[1].error, same(firstError));
      expect(
        exception.failures[1].stackTrace.toString(),
        contains('first-stack'),
      );

      final completed = graph.dispose();
      expect(identical(first, completed), isTrue);
      await expectLater(completed, throwsA(same(exception)));
    });

    test('rejects registration attempted by a disposer', () async {
      late AppResourceRegistrar capturedResources;
      final graph = await buildAppDependencyGraph<_TestDependencies>(
        dependenciesFactory: (resources) async {
          capturedResources = resources;
          resources.register(
            Object(),
            (_) => capturedResources.register(Object(), (_) {}),
          );

          return const _TestDependencies('ready');
        },
        captureRollbackFailure: _ignoreRollbackFailure,
      );

      final exception = await _captureDisposalException(graph.dispose());

      expect(exception.failures.single.error, isA<StateError>());
    });

    test('forbids self-disposal from a resource disposer', () async {
      late AppDependencyGraph<_TestDependencies> graph;
      var remainingDisposalCount = 0;
      var rejectedSynchronously = false;
      graph = await buildAppDependencyGraph<_TestDependencies>(
        dependenciesFactory: (resources) async {
          resources
            ..register(Object(), (_) => remainingDisposalCount += 1)
            ..register(Object(), (_) {
              try {
                graph.dispose();
              } on StateError {
                rejectedSynchronously = true;
                rethrow;
              }
            });

          return const _TestDependencies('ready');
        },
        captureRollbackFailure: _ignoreRollbackFailure,
      );

      final exception = await _captureDisposalException(graph.dispose());

      expect(exception.failures.single.error, isA<StateError>());
      expect(rejectedSynchronously, isTrue);
      expect(remainingDisposalCount, 1);
    });

    test('forbids disposing another graph from a disposer', () async {
      var targetDisposalCount = 0;
      final target = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) => targetDisposalCount += 1);
        },
      );
      final source = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) => target.dispose());
        },
      );

      final exception = await _captureDisposalException(source.dispose());

      expect(exception.failures.single.error, isA<StateError>());
      expect(targetDisposalCount, 0);

      await target.dispose();
      expect(targetDisposalCount, 1);
    });

    test('forbids joining an already-running graph from a disposer', () async {
      final releaseTarget = Completer<void>();
      final targetStarted = Completer<void>();
      final target = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) async {
            targetStarted.complete();
            await releaseTarget.future;
          });
        },
      );
      final source = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) => target.dispose());
        },
      );

      final targetDisposal = target.dispose();
      await targetStarted.future;
      final exception = await _captureDisposalException(source.dispose());

      expect(exception.failures.single.error, isA<StateError>());

      releaseTarget.complete();
      await targetDisposal;
    });

    test('allows a disposer to observe an already-completed graph', () async {
      var targetDisposalCount = 0;
      final target = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) => targetDisposalCount += 1);
        },
      );
      final completedTargetDisposal = target.dispose();
      await completedTargetDisposal;
      late Future<void> observedTargetDisposal;
      final source = await _buildGraph(
        configure: (resources) {
          resources.register(Object(), (_) {
            observedTargetDisposal = target.dispose();
          });
        },
      );

      await source.dispose();

      expect(
        identical(completedTargetDisposal, observedTargetDisposal),
        isTrue,
      );
      expect(targetDisposalCount, 1);
    });
  });

  group('root ownership', () {
    test('can be claimed only once', () async {
      final graph = await _buildGraph();

      graph.claimRootOwnership();

      expect(graph.claimRootOwnership, throwsStateError);
      await graph.dispose();
    });

    test('cannot be claimed after disposal was requested', () async {
      final graph = await _buildGraph();

      await graph.dispose();

      expect(graph.claimRootOwnership, throwsStateError);
    });
  });
}

Future<AppDependencyGraph<_TestDependencies>> _buildGraph({
  void Function(AppResourceRegistrar resources)? configure,
}) => buildAppDependencyGraph<_TestDependencies>(
  dependenciesFactory: (resources) async {
    configure?.call(resources);

    return const _TestDependencies('ready');
  },
  captureRollbackFailure: _ignoreRollbackFailure,
);

Future<AppResourceDisposalException> _captureDisposalException(
  Future<void> disposal,
) async {
  try {
    await disposal;
    fail('Disposal must fail.');
  } on AppResourceDisposalException catch (error) {
    return error;
  }
}

void _ignoreRollbackFailure(
  AppResourceDisposalException error,
  StackTrace stackTrace,
) {}

final class _TestDependencies {
  const _TestDependencies(this.value);

  final Object value;
}

final class _EqualResource {
  @override
  bool operator ==(Object other) => other is _EqualResource;

  @override
  int get hashCode => 1;
}
