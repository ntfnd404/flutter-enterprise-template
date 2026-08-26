import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/diagnostics/error_reporting/app_error_report_kind.dart';

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

  group('lifecycle', () {
    test(
      'reports while created without installing handlers or taking a lease',
      () async {
        final reporter = TestRecordingAppErrorReporter();
        final boundary = createTestErrorBoundary(reporter: reporter);
        addTearDown(boundary.dispose);
        try {
          final flutterHandler = FlutterError.onError;
          final platformHandler = PlatformDispatcher.instance.onError;

          await boundary.report(
            StateError('explicit pre-run report'),
            null,
            kind: AppErrorReportKind.environment,
          );

          expect(reporter.records, hasLength(1));
          expect(identical(FlutterError.onError, flutterHandler), isTrue);
          expect(
            identical(PlatformDispatcher.instance.onError, platformHandler),
            isTrue,
          );
          boundary.run(_completedBoundaryBody);
        } finally {
          boundary.dispose();
        }
      },
    );

    test('keeps an unavoidable late report after disposal no-throw', () async {
      final reporter = TestRecordingAppErrorReporter();
      final boundary = createTestErrorBoundary(reporter: reporter);
      addTearDown(boundary.dispose);
      try {
        boundary.run(_completedBoundaryBody);
        boundary.dispose();

        await expectLater(
          boundary.report(
            StateError('late callback'),
            StackTrace.current,
            kind: AppErrorReportKind.dependencyDisposal,
          ),
          completes,
        );

        expect(reporter.records, hasLength(1));
      } finally {
        boundary.dispose();
      }
    });

    test('does not replace handlers installed by another owner', () {
      final boundary = createTestErrorBoundary();
      addTearDown(boundary.dispose);
      try {
        boundary.run(_completedBoundaryBody);
        void foreignFlutterHandler(FlutterErrorDetails _) {}
        bool foreignPlatformHandler(Object _, StackTrace _) => false;
        FlutterError.onError = foreignFlutterHandler;
        PlatformDispatcher.instance.onError = foreignPlatformHandler;

        boundary.dispose();

        expect(identical(FlutterError.onError, foreignFlutterHandler), isTrue);
        expect(
          identical(
            PlatformDispatcher.instance.onError,
            foreignPlatformHandler,
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
    });

    test('rejects a competing owner but leaves it reusable', () {
      final first = createTestErrorBoundary();
      final competitor = createTestErrorBoundary();
      addTearDown(first.dispose);
      addTearDown(competitor.dispose);
      try {
        first.run(_completedBoundaryBody);
        expect(
          () => competitor.run(_completedBoundaryBody),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              'Another AppErrorBoundary is already active.',
            ),
          ),
        );

        first.dispose();
        competitor.run(_completedBoundaryBody);
      } finally {
        competitor.dispose();
        first.dispose();
      }
    });

    test('rejects repeated run and run after disposal', () {
      final active = createTestErrorBoundary();
      addTearDown(active.dispose);
      try {
        active.run(_completedBoundaryBody);

        expect(() => active.run(_completedBoundaryBody), throwsStateError);
        active.dispose();
        active.dispose();
        expect(() => active.run(_completedBoundaryBody), throwsStateError);

        final disposedBeforeRun = createTestErrorBoundary()..dispose();
        expect(
          () => disposedBeforeRun.run(_completedBoundaryBody),
          throwsStateError,
        );
      } finally {
        active.dispose();
      }
    });
  });
}

Future<void> _completedBoundaryBody() => Future<void>.value();
