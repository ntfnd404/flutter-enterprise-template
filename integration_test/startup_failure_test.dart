import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/startup/run_application.dart';

import 'support/startup_test_support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('invalid real Environment mounts only the safe fallback', (
    tester,
  ) async {
    final originalObserver = Bloc.observer;
    final reporter = IntegrationStartupReporter();
    final boundaryCapture = IntegrationBoundaryCapture();

    try {
      runApplication(
        logger: const NoopAppLogger(),
        errorReporter: reporter,
        errorBoundaryFactory: boundaryCapture.create,
      );

      await reporter.firstReport;
      await pumpUntilIntegrationWidget(
        tester,
        find.byKey(const ValueKey('startup-failure-marker')),
      );

      expect(reporter.reports, hasLength(1));
      expect(reporter.reports.single.kind, AppErrorReportKind.environment);
      expect(find.text('APP-ENVIRONMENT-001'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('normal-app-marker')),
        findsNothing,
      );
    } finally {
      try {
        await tester.pumpWidget(const SizedBox.shrink());
      } finally {
        restoreIntegrationGlobals(
          observer: originalObserver,
          boundaryCapture: boundaryCapture,
        );
      }
    }
  });
}
