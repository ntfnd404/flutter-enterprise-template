import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/app_resource_disposal_exception.dart';

void main() {
  test('stores failures immutably without rendering sensitive values', () {
    final error = _ThrowingToString();
    final stackTrace = _ThrowingStackTrace();
    final source = <AppResourceDisposalFailure>[
      AppResourceDisposalFailure(error: error, stackTrace: stackTrace),
    ];

    final exception = AppResourceDisposalException(source);
    source.clear();

    expect(exception.failures, hasLength(1));
    expect(exception.failures.single.error, same(error));
    expect(exception.failures.single.stackTrace, same(stackTrace));
    expect(
      exception.failures.single.toString(),
      'AppResourceDisposalFailure',
    );
    expect(
      exception.toString(),
      'AppResourceDisposalException(1 failures)',
    );
    expect(
      () => exception.failures.add(
        AppResourceDisposalFailure(
          error: StateError('hidden'),
          stackTrace: StackTrace.current,
        ),
      ),
      throwsUnsupportedError,
    );
  });

  test('rejects an empty aggregate with a privacy-safe error', () {
    Object? thrown;

    try {
      AppResourceDisposalException(const <AppResourceDisposalFailure>[]);
    } catch (error) {
      thrown = error;
    }

    expect(thrown, isA<ArgumentError>());
    expect(thrown.toString(), isNot(contains('Instance of')));
  });
}

final class _ThrowingToString {
  @override
  String toString() => throw StateError('must not render error');
}

final class _ThrowingStackTrace implements StackTrace {
  @override
  String toString() => throw StateError('must not render stack');
}
