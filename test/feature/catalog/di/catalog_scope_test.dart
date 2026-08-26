import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/feature/catalog/bloc/catalog_bloc.dart';
import 'package:template/feature/catalog/di/catalog_scope.dart';

import '../support/recording_catalog_facade.dart';

void main() {
  testWidgets('publishes a factory without creating or owning BLoCs', (
    tester,
  ) async {
    final facade = RecordingCatalogFacade();
    final created = <CatalogBloc>[];
    late BuildContext featureContext;

    await tester.pumpWidget(
      CatalogScope(
        catalog: facade,
        child: Builder(
          builder: (context) {
            featureContext = context;

            return const SizedBox();
          },
        ),
      ),
    );

    expect(created, isEmpty);
    created
      ..add(CatalogScope.createBloc(featureContext))
      ..add(CatalogScope.createBloc(featureContext));
    expect(created, hasLength(2));
    expect(identical(created.first, created.last), isFalse);

    await tester.runAsync(
      () async {
        await Future.wait(created.map((bloc) => bloc.close()));
        await facade.dispose();
      },
    );
  });

  testWidgets('reports a safe StateError when scope is missing', (
    tester,
  ) async {
    Object? captured;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          try {
            CatalogScope.createBloc(context);
          } catch (error) {
            captured = error;
          }

          return const SizedBox();
        },
      ),
    );

    expect(captured, isA<StateError>());
    expect(captured.toString(), contains('CatalogScope not found'));
  });
}
