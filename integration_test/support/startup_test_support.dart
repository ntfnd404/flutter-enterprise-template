import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';

typedef IntegrationStartupReport = ({
  Object error,
  StackTrace? stackTrace,
  AppErrorReportKind kind,
});

final class IntegrationStartupReporter implements AppErrorReporter {
  final reports = <IntegrationStartupReport>[];
  final _firstReport = Completer<void>();

  Future<void> get firstReport => _firstReport.future;

  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) {
    reports.add((error: error, stackTrace: stackTrace, kind: kind));
    if (!_firstReport.isCompleted) {
      _firstReport.complete();
    }

    return Future.value();
  }
}

final class IntegrationBoundaryCapture {
  AppErrorBoundary? boundary;

  AppErrorBoundary create({
    required AppLogger logger,
    required AppErrorReporter reporter,
  }) {
    final created = AppErrorBoundary(logger: logger, reporter: reporter);
    boundary = created;

    return created;
  }

  void dispose() {
    boundary?.dispose();
    boundary = null;
  }
}

Future<void> pumpUntilIntegrationWidget(
  WidgetTester tester,
  Finder finder,
) async {
  while (finder.evaluate().isEmpty) {
    await tester.pump();
  }
}

Future<AppDependencyGraph<Object>> unmountIntegrationGraph(
  WidgetTester tester,
) async {
  final owner = tester.widget<AppDependencyGraphOwner>(
    find.byType(AppDependencyGraphOwner),
  );
  final graph = owner.graph;
  await tester.pumpWidget(const SizedBox.shrink());
  await graph.dispose();

  return graph;
}

void restoreIntegrationGlobals({
  required BlocObserver observer,
  required IntegrationBoundaryCapture boundaryCapture,
}) {
  try {
    boundaryCapture.dispose();
  } finally {
    Bloc.observer = observer;
  }
}
