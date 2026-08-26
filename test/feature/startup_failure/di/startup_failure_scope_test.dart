import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/startup_failure/bloc/startup_failure_bloc.dart';
import 'package:template/feature/startup_failure/di/startup_failure_scope.dart';

void main() {
  testWidgets('creates an isolated BLoC that BlocProvider closes', (tester) async {
    final previousObserver = Bloc.observer;
    final observer = _StartupFailureLifecycleObserver();
    Bloc.observer = observer;
    addTearDown(() => Bloc.observer = previousObserver);

    await tester.pumpWidget(
      const MaterialApp(
        home: StartupFailureScope(
          diagnosticCode: 'APP-STARTUP-001',
          child: _StartupFailureProbe(),
        ),
      ),
    );

    expect(find.text('APP-STARTUP-001'), findsOneWidget);
    final bloc = observer.created.single;

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(bloc.isClosed, isTrue);
  });
}

final class _StartupFailureProbe extends StatelessWidget {
  const _StartupFailureProbe();

  @override
  Widget build(BuildContext context) => Text(
    context.read<StartupFailureBloc>().state.diagnosticCode,
  );
}

final class _StartupFailureLifecycleObserver extends BlocObserver {
  final List<StartupFailureBloc> created = [];

  @override
  void onCreate(BlocBase<Object?> bloc) {
    if (bloc is StartupFailureBloc) {
      created.add(bloc);
    }
    super.onCreate(bloc);
  }
}
