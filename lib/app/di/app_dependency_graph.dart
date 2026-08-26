import 'dart:async';
import 'dart:collection';

import 'package:template/app/di/app_resource_disposal_exception.dart';
import 'package:template/app/di/app_resource_registrar.dart';

final Object _resourceDisposerZoneKey = Object();

/// Builds one application dependency graph and its private ownership ledger.
///
/// Every invocation creates an independent ownership boundary. If
/// [dependenciesFactory] fails, every resource registered during that build is
/// released in last-in-first-out order before the original failure is rethrown
/// with its original stack trace. Cleanup failures are secondary and are
/// offered once to [captureRollbackFailure].
Future<AppDependencyGraph<T>> buildAppDependencyGraph<T extends Object>({
  required Future<T> Function(AppResourceRegistrar resources)
  dependenciesFactory,
  required AppResourceRollbackFailureCollector captureRollbackFailure,
}) async {
  final resources = _AppResourceLedger();

  try {
    final dependencies = await dependenciesFactory(resources);
    resources.seal();

    return AppDependencyGraph<T>._(
      dependencies: dependencies,
      resources: resources,
    );
  } catch (error, stackTrace) {
    await _rollback(
      resources,
      captureRollbackFailure: captureRollbackFailure,
    );
    Error.throwWithStackTrace(error, stackTrace);
  }
}

/// Owns one successfully constructed application dependency graph.
///
/// [dependencies] describes what downstream composition may use. The private
/// resource ledger exclusively owns app-lifetime cleanup. The graph is not a
/// dependency registry and provides no lookup API.
final class AppDependencyGraph<T extends Object> {
  AppDependencyGraph._({
    required this.dependencies,
    required this._resources,
  });

  /// Application-lifetime ports exposed by this graph.
  final T dependencies;

  final _AppResourceLedger _resources;
  _AppDependencyGraphOwnershipState _ownershipState =
      _AppDependencyGraphOwnershipState.unclaimed;

  /// Claims the graph for the single root lifecycle owner.
  ///
  /// This app-internal handoff exists because the Flutter owner is a separate
  /// Dart library. A graph can be claimed only once and cannot be claimed after
  /// disposal has been requested.
  void claimRootOwnership() {
    switch (_ownershipState) {
      case _AppDependencyGraphOwnershipState.unclaimed:
        _ownershipState = _AppDependencyGraphOwnershipState.claimed;
      case _AppDependencyGraphOwnershipState.claimed:
        throw StateError(
          'The application dependency graph already has a root owner.',
        );
      case _AppDependencyGraphOwnershipState.disposalRequested:
        throw StateError(
          'A disposing application dependency graph cannot be claimed.',
        );
    }
  }

  /// Releases every graph-owned resource exactly once.
  ///
  /// Concurrent and repeated external callers receive the exact same future,
  /// including after completion. Calling this method from any registered
  /// resource disposer is forbidden because nested graph teardown can create
  /// ownership cycles and deadlocks; that misuse throws synchronously.
  Future<void> dispose() {
    if (!_resources.isDisposed) {
      _rejectResourceDisposerCall();
    }
    _ownershipState = _AppDependencyGraphOwnershipState.disposalRequested;

    return _resources.dispose();
  }
}

enum _AppDependencyGraphOwnershipState {
  unclaimed,
  claimed,
  disposalRequested,
}

enum _AppResourceLedgerState {
  accepting,
  sealed,
  disposing,
  disposed,
}

final class _AppResourceLedger implements AppResourceRegistrar {
  final Set<Object> _resources = HashSet<Object>.identity();
  final List<FutureOr<void> Function()> _disposers =
      <FutureOr<void> Function()>[];
  _AppResourceLedgerState _state = _AppResourceLedgerState.accepting;
  Future<void>? _disposeFuture;

  bool get isDisposed => _state == _AppResourceLedgerState.disposed;

  @override
  R register<R extends Object>(
    R resource,
    AppResourceDisposer<R> disposer,
  ) {
    if (_state != _AppResourceLedgerState.accepting) {
      throw StateError(
        'Cannot register a resource after graph construction has closed.',
      );
    }
    if (_resources.contains(resource)) {
      throw StateError(
        'The same resource identity cannot be registered more than once.',
      );
    }

    _resources.add(resource);
    _disposers.add(() => disposer(resource));

    return resource;
  }

  void seal() {
    if (_state != _AppResourceLedgerState.accepting) {
      throw StateError('Cannot seal a resource ledger in its current state.');
    }
    _state = _AppResourceLedgerState.sealed;
  }

  Future<void> dispose() {
    final existing = _disposeFuture;
    if (existing != null) {
      return existing;
    }

    switch (_state) {
      case _AppResourceLedgerState.accepting:
      case _AppResourceLedgerState.sealed:
        _state = _AppResourceLedgerState.disposing;
      case _AppResourceLedgerState.disposing:
      case _AppResourceLedgerState.disposed:
        throw StateError('The resource ledger has an invalid lifecycle state.');
    }

    final completer = Completer<void>();
    _disposeFuture = completer.future;
    _disposeResources().then(
      (_) {
        _state = _AppResourceLedgerState.disposed;
        completer.complete();
      },
      onError: (Object error, StackTrace stackTrace) {
        _state = _AppResourceLedgerState.disposed;
        completer.completeError(error, stackTrace);
      },
    );

    return completer.future;
  }

  Future<void> _disposeResources() async {
    final failures = <AppResourceDisposalFailure>[];

    try {
      for (final dispose in _disposers.reversed) {
        try {
          await runZoned<FutureOr<void>>(
            dispose,
            zoneValues: <Object, Object>{_resourceDisposerZoneKey: true},
          );
        } catch (error, stackTrace) {
          failures.add(
            AppResourceDisposalFailure(
              error: error,
              stackTrace: stackTrace,
            ),
          );
        }
      }

      if (failures.isNotEmpty) {
        throw AppResourceDisposalException(failures);
      }
    } finally {
      _resources.clear();
      _disposers.clear();
    }
  }
}

Future<void> _rollback(
  _AppResourceLedger resources, {
  required AppResourceRollbackFailureCollector captureRollbackFailure,
}) async {
  try {
    await resources.dispose();
  } on AppResourceDisposalException catch (error, stackTrace) {
    _captureRollbackFailureSafely(
      error,
      stackTrace,
      captureRollbackFailure: captureRollbackFailure,
    );
  } catch (error, stackTrace) {
    _captureRollbackFailureSafely(
      AppResourceDisposalException(
        <AppResourceDisposalFailure>[
          AppResourceDisposalFailure(
            error: error,
            stackTrace: stackTrace,
          ),
        ],
      ),
      stackTrace,
      captureRollbackFailure: captureRollbackFailure,
    );
  }
}

void _captureRollbackFailureSafely(
  AppResourceDisposalException error,
  StackTrace stackTrace, {
  required AppResourceRollbackFailureCollector captureRollbackFailure,
}) {
  try {
    captureRollbackFailure(error, stackTrace);
  } on Object {
    // Rollback has no safe secondary reporting channel. A broken collector
    // must never replace or precede the primary graph-construction failure.
  }
}

void _rejectResourceDisposerCall() {
  if (Zone.current[_resourceDisposerZoneKey] == true) {
    throw StateError(
      'A resource disposer cannot dispose an application dependency graph.',
    );
  }
}
