import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:template/feature/startup_failure/bloc/startup_failure_bloc.dart';

/// Pre-DI composition boundary for startup-failure presentation.
///
/// The scope receives only a safe code and deliberately does not read the
/// normal application graph. [BlocProvider] owns and closes its BLoC.
final class StartupFailureScope extends StatelessWidget {
  /// Creates the isolated startup-failure boundary.
  const StartupFailureScope({
    required this.diagnosticCode,
    required this.child,
    super.key,
  });

  /// Stable non-sensitive identifier supplied by the startup boundary.
  final String diagnosticCode;

  /// Fallback subtree that consumes `StartupFailureBloc`.
  final Widget child;

  @override
  Widget build(BuildContext context) => BlocProvider<StartupFailureBloc>(
    create: (_) => StartupFailureBloc(diagnosticCode: diagnosticCode),
    child: child,
  );
}
