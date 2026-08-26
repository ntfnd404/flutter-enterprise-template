import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_dependencies.dart';
import 'package:template/app/di/app_dependency_graph.dart';
import 'package:template/app/di/app_dependency_graph_owner.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_reporter.dart';
import 'package:template/app/diagnostics/logging/app_log_record.dart';
import 'package:template/app/diagnostics/logging/app_logger.dart';
import 'package:template/app/environment/app_startup_configuration.dart';

import '../../../support/noop_app_event_bus.dart';
import '../../../support/noop_catalog_facade.dart';
import '../../../support/noop_ordering_facade.dart';

typedef StartupTestReport = ({
  Object error,
  StackTrace? stackTrace,
  AppErrorReportKind kind,
});

final class StartupTestLogger implements AppLogger {
  final records = <AppLogRecord>[];
  final _waiters = <({int count, Completer<void> completer})>[];

  Future<void> waitForCount(int count) {
    if (records.length >= count) {
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add((count: count, completer: completer));

    return completer.future;
  }

  @override
  void log(AppLogRecord record) {
    records.add(record);
    for (final waiter in _waiters.toList()) {
      if (records.length >= waiter.count) {
        _waiters.remove(waiter);
        waiter.completer.complete();
      }
    }
  }
}

final class StartupTestReporter implements AppErrorReporter {
  StartupTestReporter({this.onReport});

  final Future<void> Function(StartupTestReport report)? onReport;
  final reports = <StartupTestReport>[];
  final _waiters = <({int count, Completer<void> completer})>[];
  final _completionWaiters = <({int count, Completer<void> completer})>[];
  var _completedCount = 0;

  Future<void> waitForCount(int count) {
    if (reports.length >= count) {
      return Future.value();
    }
    final completer = Completer<void>();
    _waiters.add((count: count, completer: completer));

    return completer.future;
  }

  Future<void> waitForCompletedCount(int count) {
    if (_completedCount >= count) {
      return Future.value();
    }
    final completer = Completer<void>();
    _completionWaiters.add((count: count, completer: completer));

    return completer.future;
  }

  @override
  Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    required AppErrorReportKind kind,
  }) async {
    final report = (error: error, stackTrace: stackTrace, kind: kind);
    reports.add(report);
    for (final waiter in _waiters.toList()) {
      if (reports.length >= waiter.count) {
        _waiters.remove(waiter);
        waiter.completer.complete();
      }
    }
    try {
      await onReport?.call(report);
    } finally {
      _completedCount += 1;
      for (final waiter in _completionWaiters.toList()) {
        if (_completedCount >= waiter.count) {
          _completionWaiters.remove(waiter);
          waiter.completer.complete();
        }
      }
    }
  }
}

final class StartupBoundaryCapture {
  AppErrorBoundary? boundary;
  AppLogger? logger;
  AppErrorReporter? reporter;

  AppErrorBoundary create({
    required AppLogger logger,
    required AppErrorReporter reporter,
  }) {
    this.logger = logger;
    this.reporter = reporter;
    final created = AppErrorBoundary(logger: logger, reporter: reporter);
    boundary = created;

    return created;
  }

  void dispose() {
    boundary?.dispose();
    boundary = null;
  }
}

AppStartupConfiguration validStartupConfiguration() =>
    AppStartupConfiguration.fromValues(
      environment: 'local',
      urlStrategy: 'hash',
      storageNamespace: 'test',
    );

AppDependencies testAppDependencies() => const AppDependencies(
  catalog: NoopCatalogFacade(),
  ordering: NoopOrderingFacade(),
  eventPublisher: NoopAppEventBus(),
  eventSubscriber: NoopAppEventBus(),
);

Future<AppDependencyGraph<Object>> unmountAndDisposeGraph(
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

Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder,
) async {
  while (finder.evaluate().isEmpty) {
    await tester.pump();
  }
}

void restoreStartupGlobals({
  required BlocObserver observer,
  required StartupBoundaryCapture boundaryCapture,
}) {
  try {
    boundaryCapture.dispose();
  } finally {
    Bloc.observer = observer;
  }
}
