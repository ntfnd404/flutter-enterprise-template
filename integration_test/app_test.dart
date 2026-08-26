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

  testWidgets('production entrypoint starts the normal graph', (tester) async {
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
      await pumpUntilFound(tester, find.text('Template running'));

      expect(
        find.byKey(const ValueKey('startup-failure-marker')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('complete-demo-action')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Completed actions: 1'), findsOneWidget);

      // The macOS integration viewport lets the action SnackBar overlap the
      // Activity button. Wait for that transient UI before exercising the
      // navigation scenario so the tap remains a real hit-test interaction.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('open-activity-route')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('activity-route-marker')),
        findsOneWidget,
      );
      expect(find.text('Observed since opening Activity: 0'), findsOneWidget);
      expect(
        find.text(
          'Action 1 was published before this screen subscribed and was not replayed',
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('startup-failure-marker')),
        findsNothing,
      );
      expect(reporter.records, isEmpty);

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
