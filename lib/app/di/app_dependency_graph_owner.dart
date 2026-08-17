import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_resource_disposal_exception.dart';

/// Owns one application dependency graph for the root widget-tree lifetime.
///
/// Dependencies are constructor-injected before this boundary. The owner is
/// not an `InheritedWidget`, exposes no lookup API, and exists only to claim
/// one graph and adapt asynchronous cleanup to Flutter's synchronous
/// [State.dispose] hook. A graph can have only one root owner.
///
/// Expected ownership and replacement violations are retained and rethrown
/// from this widget's own build boundary. That lets Flutter localize its
/// `ErrorWidget` to the rejected owner instead of replacing a parent subtree
/// that may contain the valid owner. A rejected owner never adopts or disposes
/// the graph claimed elsewhere.
final class AppDependencyGraphOwner extends StatefulWidget {
  /// Creates the root graph lifecycle owner.
  const AppDependencyGraphOwner({
    required this.graph,
    required this.onDisposalFailure,
    required this.child,
    super.key,
  });

  /// The single application dependency graph claimed by this widget.
  final AppDependencyGraph<Object> graph;

  /// Handles an aggregate failure raised during normal graph teardown.
  ///
  /// The latest callback accepted for the same graph is captured when widget
  /// disposal starts. Rejected graph replacement never adopts its callback.
  final AppResourceDisposalFailureCallback onDisposalFailure;

  /// The application subtree composed from the graph's dependencies.
  final Widget child;

  @override
  State<AppDependencyGraphOwner> createState() =>
      _AppDependencyGraphOwnerState();
}

final class _AppDependencyGraphOwnerState
    extends State<AppDependencyGraphOwner> {
  late final AppDependencyGraph<Object> _graph;
  late final Zone _ownerZone;
  late Widget _child;
  late AppResourceDisposalFailureCallback _onDisposalFailure;
  var _claimSucceeded = false;
  StateError? _lifecycleFailure;
  StackTrace? _lifecycleFailureStack;

  @override
  void initState() {
    super.initState();
    _graph = widget.graph;
    _ownerZone = Zone.current;
    _child = widget.child;
    _onDisposalFailure = widget.onDisposalFailure;
    try {
      _graph.claimRootOwnership();
      _claimSucceeded = true;
    } on StateError catch (error, stackTrace) {
      _lifecycleFailure = error;
      _lifecycleFailureStack = stackTrace;
    }
  }

  @override
  void didUpdateWidget(AppDependencyGraphOwner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_claimSucceeded) {
      return;
    }
    if (!identical(_graph, widget.graph)) {
      // Record the rejection before build so Flutter contains the failure at
      // this Owner. The accepted graph, child, and callback remain unchanged.
      _lifecycleFailure = StateError(
        'AppDependencyGraphOwner does not support replacing the application '
        'dependency graph.',
      );
      _lifecycleFailureStack = StackTrace.current;

      return;
    }

    _lifecycleFailure = null;
    _lifecycleFailureStack = null;
    _child = widget.child;
    _onDisposalFailure = widget.onDisposalFailure;
  }

  @override
  Widget build(BuildContext context) {
    final lifecycleFailure = _lifecycleFailure;
    if (lifecycleFailure != null) {
      Error.throwWithStackTrace(
        lifecycleFailure,
        _lifecycleFailureStack ?? StackTrace.current,
      );
    }

    return _child;
  }

  @override
  void dispose() {
    if (_claimSucceeded) {
      final onDisposalFailure = _onDisposalFailure;
      unawaited(_disposeGraph(onDisposalFailure));
    }
    super.dispose();
  }

  Future<void> _disposeGraph(
    AppResourceDisposalFailureCallback onDisposalFailure,
  ) async {
    try {
      await _graph.dispose();
    } on AppResourceDisposalException catch (error, stackTrace) {
      await _reportDisposalFailure(
        error,
        stackTrace,
        onDisposalFailure: onDisposalFailure,
      );
    } catch (error, stackTrace) {
      await _reportDisposalFailure(
        AppResourceDisposalException(
          <AppResourceDisposalFailure>[
            AppResourceDisposalFailure(
              error: error,
              stackTrace: stackTrace,
            ),
          ],
        ),
        stackTrace,
        onDisposalFailure: onDisposalFailure,
      );
    }
  }

  Future<void> _reportDisposalFailure(
    AppResourceDisposalException error,
    StackTrace stackTrace, {
    required AppResourceDisposalFailureCallback onDisposalFailure,
  }) async {
    try {
      await onDisposalFailure(error, stackTrace);
    } catch (callbackError, callbackStackTrace) {
      try {
        _ownerZone.handleUncaughtError(callbackError, callbackStackTrace);
      } on Object {
        // No lifecycle-safe reporting channel remains at this point.
      }
    }
  }
}
