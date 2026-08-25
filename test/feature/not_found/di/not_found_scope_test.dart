import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/routing/app_route_fallback.dart';
import 'package:template/feature/not_found/bloc/not_found_bloc.dart';
import 'package:template/feature/not_found/di/not_found_scope.dart';

void main() {
  testWidgets('creates a screen-lifetime BLoC that BlocProvider closes', (
    tester,
  ) async {
    final previousObserver = Bloc.observer;
    final observer = _NotFoundLifecycleObserver();
    Bloc.observer = observer;
    addTearDown(() => Bloc.observer = previousObserver);

    await tester.pumpWidget(
      const MaterialApp(
        home: NotFoundScope(
          reason: AppRouteFailureReason.invalidParameters,
          child: _NotFoundProbe(),
        ),
      ),
    );

    expect(find.text('invalidParameters'), findsOneWidget);
    final bloc = observer.created.single;
    expect(bloc.state.reason, AppRouteFailureReason.invalidParameters);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();

    expect(bloc.isClosed, isTrue);
  });
}

final class _NotFoundProbe extends StatelessWidget {
  const _NotFoundProbe();

  @override
  Widget build(BuildContext context) => Text(
    context.read<NotFoundBloc>().state.reason.name,
  );
}

final class _NotFoundLifecycleObserver extends BlocObserver {
  final List<NotFoundBloc> created = [];

  @override
  void onCreate(BlocBase<Object?> bloc) {
    if (bloc is NotFoundBloc) {
      created.add(bloc);
    }
    super.onCreate(bloc);
  }
}
