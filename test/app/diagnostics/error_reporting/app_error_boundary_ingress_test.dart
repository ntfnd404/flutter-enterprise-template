import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_boundary.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';
import 'package:template/app/diagnostics/logging/app_bloc_observer.dart';

import 'support/app_error_boundary_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterExceptionHandler? originalFlutterHandler;
  late ErrorCallback? originalPlatformHandler;

  setUp(() {
    originalFlutterHandler = FlutterError.onError;
    originalPlatformHandler = PlatformDispatcher.instance.onError;
  });

  void restoreOriginalHandlers() {
    FlutterError.onError = originalFlutterHandler;
    PlatformDispatcher.instance.onError = originalPlatformHandler;
  }

  tearDown(restoreOriginalHandlers);

  group('root Zone', () {
    test('reports a synchronous body failure exactly once', () async {
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(reporter: reporter);
      addTearDown(boundary.dispose);
      try {
        final failure = StateError('synchronous root failure');

        boundary.run(() => throw failure);
        await reporter.waitForCount(1);

        expect(reporter.records, hasLength(1));
        expect(reporter.records.single.error, same(failure));
        expect(reporter.records.single.kind, AppErrorReportKind.rootZone);
      } finally {
        boundary.dispose();
      }
    });

    test('reports an external completion in the guarded Zone', () async {
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(reporter: reporter);
      addTearDown(boundary.dispose);
      try {
        final failure = StateError('asynchronous root failure');
        final stackTrace = StackTrace.fromString('asynchronous stack');
        late Completer<void> bodyCompletion;

        boundary.run(() {
          bodyCompletion = Completer<void>();

          return bodyCompletion.future;
        });
        bodyCompletion.completeError(failure, stackTrace);
        await reporter.waitForCount(1);
        await Future<void>.delayed(Duration.zero);

        expect(reporter.records, hasLength(1));
        expect(reporter.records.single.error, same(failure));
        expect(reporter.records.single.stackTrace, same(stackTrace));
        expect(reporter.records.single.kind, AppErrorReportKind.rootZone);
      } finally {
        boundary.dispose();
      }
    });

    test(
      'reports one root failure after one BLoC error breadcrumb',
      () async {
        final previousObserver = Bloc.observer;
        final logger = TestRecordingAppLogger();
        Bloc.observer = AppBlocObserver(logger: logger);
        addTearDown(() => Bloc.observer = previousObserver);
        final reporter = TestRecordingAppErrorReporter();
        final boundary = createTestErrorBoundary(
          reporter: reporter,
          logger: logger,
        );
        addTearDown(boundary.dispose);
        _ThrowingBloc? bloc;
        try {
          boundary.run(() async {
            bloc = _ThrowingBloc()..add(const _ThrowingEvent());
          });
          await reporter.waitForCount(1);
          await Future<void>.delayed(Duration.zero);

          expect(reporter.records, hasLength(1));
          expect(reporter.records.single.kind, AppErrorReportKind.rootZone);
          expect(
            logger.records
                .where(
                  (record) =>
                      record.descriptor.eventName ==
                      'app.bloc.error_breadcrumb',
                )
                .length,
            1,
          );
          expect(
            logger.records
                .where(
                  (record) =>
                      record.descriptor.eventName ==
                      'app.diagnostics.error_reported',
                )
                .length,
            1,
          );
        } finally {
          await bloc?.close();
          Bloc.observer = previousObserver;
          boundary.dispose();
        }
      },
    );
  });

  group('global handlers', () {
    test(
      'reports without invoking previous handlers and restores them',
      () async {
        var previousFlutterCalls = 0;
        var previousPlatformCalls = 0;
        void previousFlutterHandler(FlutterErrorDetails _) {
          previousFlutterCalls += 1;
        }

        bool previousPlatformHandler(Object _, StackTrace _) {
          previousPlatformCalls += 1;

          return false;
        }

        final reporter = TestRecordingAppErrorReporter();
        final boundary = createTestErrorBoundary(reporter: reporter);
        addTearDown(boundary.dispose);
        final flutterFailure = StateError('framework');
        final flutterStack = StackTrace.fromString('framework stack');
        final platformFailure = StateError('platform');
        final platformStack = StackTrace.fromString('platform stack');

        try {
          FlutterError.onError = previousFlutterHandler;
          PlatformDispatcher.instance.onError = previousPlatformHandler;
          boundary.run(_completedBoundaryBody);
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: flutterFailure,
              stack: flutterStack,
            ),
          );
          final handled = PlatformDispatcher.instance.onError!(
            platformFailure,
            platformStack,
          );
          await reporter.waitForCount(2);

          expect(previousFlutterCalls, 0);
          expect(previousPlatformCalls, 0);
          expect(handled, isTrue);
          expect(reporter.records, hasLength(2));
          expect(reporter.records.first.error, same(flutterFailure));
          expect(reporter.records.first.stackTrace, same(flutterStack));
          expect(
            reporter.records.first.kind,
            AppErrorReportKind.flutterFramework,
          );
          expect(reporter.records.last.error, same(platformFailure));
          expect(reporter.records.last.stackTrace, same(platformStack));
          expect(
            reporter.records.last.kind,
            AppErrorReportKind.platformDispatcher,
          );

          boundary.dispose();
          expect(
            identical(FlutterError.onError, previousFlutterHandler),
            isTrue,
          );
          expect(
            identical(
              PlatformDispatcher.instance.onError,
              previousPlatformHandler,
            ),
            isTrue,
          );
        } finally {
          try {
            boundary.dispose();
          } finally {
            restoreOriginalHandlers();
          }
        }
      },
    );

    test('preserves an absent Flutter framework stack', () async {
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(reporter: reporter);
      addTearDown(boundary.dispose);
      try {
        final failure = StateError('framework without stack');

        boundary.run(_completedBoundaryBody);
        FlutterError.reportError(FlutterErrorDetails(exception: failure));
        await reporter.waitForCount(1);

        expect(reporter.records, hasLength(1));
        expect(reporter.records.single.error, same(failure));
        expect(reporter.records.single.stackTrace, isNull);
        expect(
          reporter.records.single.kind,
          AppErrorReportKind.flutterFramework,
        );
      } finally {
        boundary.dispose();
      }
    });

    test('does not evaluate Flutter information collectors', () async {
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(reporter: reporter);
      addTearDown(boundary.dispose);
      try {
        var collectorCalls = 0;

        boundary.run(_completedBoundaryBody);
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: StateError('framework'),
            informationCollector: () {
              collectorCalls += 1;
              throw StateError('collector must stay unevaluated');
            },
          ),
        );
        await reporter.waitForCount(1);

        expect(collectorCalls, 0);
        expect(reporter.records, hasLength(1));
      } finally {
        boundary.dispose();
      }
    });

    test('reports silent Flutter failures by default in debug', () async {
      expect(kDebugMode, isTrue);
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(reporter: reporter);
      addTearDown(boundary.dispose);
      try {
        final failure = StateError('silent debug failure');

        boundary.run(_completedBoundaryBody);
        FlutterError.reportError(
          FlutterErrorDetails(exception: failure, silent: true),
        );
        await reporter.waitForCount(1);

        expect(reporter.records, hasLength(1));
        expect(reporter.records.single.error, same(failure));
        expect(
          reporter.records.single.kind,
          AppErrorReportKind.flutterFramework,
        );
      } finally {
        boundary.dispose();
      }
    });

    test(
      'suppresses silent Flutter failures when policy disables them',
      () async {
        final reporter = TestRecordingAppErrorReporter();
        final boundary = AppErrorBoundary(
          reporter: reporter,
          logger: TestRecordingAppLogger(),
          reportSilentFlutterErrors: false,
        );
        addTearDown(boundary.dispose);
        try {
          final visibleFailure = StateError('visible');

          boundary.run(_completedBoundaryBody);
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: StateError('silent'),
              silent: true,
            ),
          );
          FlutterError.reportError(
            FlutterErrorDetails(exception: visibleFailure),
          );
          await reporter.waitForCount(1);

          expect(reporter.records, hasLength(1));
          expect(reporter.records.single.error, same(visibleFailure));
        } finally {
          boundary.dispose();
        }
      },
    );

    test(
      'platform handler returns true after reporter and logger failures',
      () async {
        final secondLoggerCall = Completer<void>();
        var loggerCalls = 0;
        final boundary = createTestErrorBoundary(
          reporter: TestCallbackAppErrorReporter(
            (_, _, _) => throw StateError('broken reporter'),
          ),
          logger: TestCallbackAppLogger((_) {
            loggerCalls += 1;
            if (loggerCalls == 2) {
              secondLoggerCall.complete();
            }
            throw StateError('broken logger');
          }),
        );
        addTearDown(boundary.dispose);
        try {
          boundary.run(_completedBoundaryBody);
          final handled = PlatformDispatcher.instance.onError!(
            StateError('platform'),
            StackTrace.current,
          );
          await secondLoggerCall.future;

          expect(handled, isTrue);
          expect(loggerCalls, 2);
        } finally {
          boundary.dispose();
        }
      },
    );
  });
}

final class _ThrowingEvent {
  const _ThrowingEvent();
}

final class _ThrowingBloc extends Bloc<_ThrowingEvent, int> {
  _ThrowingBloc() : super(0) {
    on<_ThrowingEvent>((event, emit) => throw StateError('BLoC failure'));
  }
}

Future<void> _completedBoundaryBody() => Future<void>.value();
