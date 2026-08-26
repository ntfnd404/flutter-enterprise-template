import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/routing/app_router.dart';

/// Root application wrapper that owns one UI-lifetime router.
final class App extends StatefulWidget {
  /// Creates the normal application over borrowed graph [dependencies].
  const App({required this.dependencies, super.key});

  /// Narrow delivery catalog borrowed for this root application lifetime.
  final AppDependencies dependencies;

  @override
  State<App> createState() => _AppState();
}

final class _AppState extends State<App> {
  late final AppDependencies _dependencies;
  late final GoRouter _router;
  StateError? _lifecycleFailure;
  StackTrace? _lifecycleFailureStack;

  @override
  void initState() {
    super.initState();
    _dependencies = widget.dependencies;
    _router = createAppRouter(dependencies: _dependencies);
  }

  @override
  void didUpdateWidget(App oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(_dependencies, widget.dependencies)) {
      _lifecycleFailure = StateError(
        'App does not support replacing application dependencies.',
      );
      _lifecycleFailureStack = StackTrace.current;

      return;
    }
    _lifecycleFailure = null;
    _lifecycleFailureStack = null;
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

    return MaterialApp.router(
      restorationScopeId: 'app',
      routerConfig: _router,
    );
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }
}
