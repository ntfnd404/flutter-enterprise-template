import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/core/event_bus/app_event_bus.dart';
import 'package:template/feature/demo/bloc/demo_bloc.dart';
import 'package:template/feature/demo/di/demo_scope.dart';

void main() {
  testWidgets(
    'feature factory creates the BLoC and BlocProvider owns the instance',
    (tester) async {
      final previousObserver = Bloc.observer;
      final observer = _LifecycleObserver();
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = previousObserver);
      final eventBus = AppEventBus();
      addTearDown(eventBus.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: DemoScope(
            eventBus: eventBus,
            child: const _BlocOwnerProbe(),
          ),
        ),
      );

      expect(find.text('created'), findsOneWidget);
      final bloc = observer.created.single;
      expect(bloc.state.isReady, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();

      expect(bloc.isClosed, isTrue);
    },
  );
}

final class _BlocOwnerProbe extends StatelessWidget {
  const _BlocOwnerProbe();

  @override
  Widget build(BuildContext context) => BlocProvider<DemoBloc>(
    create: (_) => DemoScope.createBloc(context),
    child: Builder(
      builder: (context) => Text(
        context.read<DemoBloc>().state.isReady ? 'ready' : 'created',
      ),
    ),
  );
}

final class _LifecycleObserver extends BlocObserver {
  final List<DemoBloc> created = [];

  @override
  void onCreate(BlocBase<Object?> bloc) {
    if (bloc is DemoBloc) {
      created.add(bloc);
    }
    super.onCreate(bloc);
  }
}
