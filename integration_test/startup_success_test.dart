import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/startup/run_application.dart';

import 'support/startup_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'real test configuration mounts and tears down the normal graph',
    (
      tester,
    ) async {
      final originalObserver = Bloc.observer;
      final reporter = IntegrationStartupReporter();
      final boundaryCapture = IntegrationBoundaryCapture();
      var graphMounted = false;

      try {
        runApplication(
          logger: const NoopAppLogger(),
          errorReporter: reporter,
          errorBoundaryFactory: boundaryCapture.create,
        );

        await pumpUntilIntegrationWidget(
          tester,
          find.byKey(const ValueKey('normal-app-marker')),
        );
        await pumpUntilIntegrationWidget(
          tester,
          find.text('Template running'),
        );
        graphMounted = true;

        expect(find.text('Template running'), findsOneWidget);
        expect(reporter.reports, isEmpty);

        await unmountIntegrationGraph(tester);
        graphMounted = false;
        expect(reporter.reports, isEmpty);
      } finally {
        try {
          if (graphMounted) {
            await unmountIntegrationGraph(tester);
          }
        } finally {
          restoreIntegrationGlobals(
            observer: originalObserver,
            boundaryCapture: boundaryCapture,
          );
        }
      }
    },
  );
}
