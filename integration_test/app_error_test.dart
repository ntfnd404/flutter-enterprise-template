import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/startup/run_application.dart' as application;

import 'support/capturing_app_error_boundary_factory.dart';
import 'support/dispose_app_graph.dart';
import 'support/pump_until_found.dart';
import 'support/recording_app_error_reporter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recording boundary observes no hidden startup failures', (
    tester,
  ) async {
    final reporter = RecordingAppErrorReporter();
    final boundaryFactory = CapturingAppErrorBoundaryFactory();
    addTearDown(boundaryFactory.dispose);

    application.runApplication(
      logger: const NoopAppLogger(),
      errorReporter: reporter,
      errorBoundaryFactory: boundaryFactory.create,
    );
    try {
      await pumpUntilFound(
        tester,
        find.byKey(const ValueKey('normal-app-marker')),
      );

      expect(
        find.byKey(const ValueKey('startup-failure-marker')),
        findsNothing,
      );
      expect(reporter.records, isEmpty);

      // The test owns the injected boundary and the root graph it launched.
      await disposeAppGraph(tester);
      expect(reporter.records, isEmpty);
    } finally {
      try {
        if (find.byType(AppDependencyGraphOwner).evaluate().isNotEmpty) {
          await disposeAppGraph(tester);
        }
      } finally {
        boundaryFactory.dispose();
      }
    }
  });
}
