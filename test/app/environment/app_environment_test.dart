import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/environment/app_environment.dart';
import 'package:template/app/environment/app_environment_exception.dart';
import 'package:template/app/environment/app_environment_keys.dart';
import 'package:template/app/environment/app_environment_kind.dart';
import 'package:template/app/environment/app_url_strategy.dart';

void main() {
  group('AppEnvironment', () {
    test('publishes the canonical required dart-define keys', () {
      expect(
        AppEnvironmentKeys.required,
        {
          AppEnvironmentKeys.environment,
          AppEnvironmentKeys.urlStrategy,
          AppEnvironmentKeys.storageNamespace,
        },
      );
    });

    test('parses supported public values', () {
      final environment = AppEnvironment.fromValues(
        environment: 'prod',
        urlStrategy: 'path',
      );

      expect(environment.kind, AppEnvironmentKind.prod);
      expect(environment.urlStrategy, AppUrlStrategy.path);
    });

    test('has value equality', () {
      final first = AppEnvironment.fromValues(
        environment: 'dev',
        urlStrategy: 'hash',
      );
      final second = AppEnvironment.fromValues(
        environment: 'dev',
        urlStrategy: 'hash',
      );

      expect(first, second);
      expect(first.hashCode, second.hashCode);
    });

    test('rejects environment kind without rendering its value', () {
      const secret = 'secret-environment-value';

      expect(
        () => AppEnvironment.fromValues(
          environment: secret,
          urlStrategy: 'hash',
        ),
        throwsA(
          isA<AppEnvironmentException>().having(
            (error) => error.message,
            'safe message',
            isNot(contains(secret)),
          ),
        ),
      );
    });

    test('rejects URL strategy without rendering its value', () {
      const secret = 'path?token=secret';

      expect(
        () => AppEnvironment.fromValues(
          environment: 'local',
          urlStrategy: secret,
        ),
        throwsA(
          isA<AppEnvironmentException>().having(
            (error) => error.message,
            'safe message',
            isNot(contains(secret)),
          ),
        ),
      );
    });

    test('rejects empty runtime values at the typed boundary', () {
      for (final values in <({String environment, String urlStrategy})>[
        (environment: '', urlStrategy: 'hash'),
        (environment: 'local', urlStrategy: ''),
      ]) {
        expect(
          () => AppEnvironment.fromValues(
            environment: values.environment,
            urlStrategy: values.urlStrategy,
          ),
          throwsA(isA<AppEnvironmentException>()),
        );
      }
    });

    test('exception text never renders the rejected value', () {
      const rejectedValue = 'private-value-must-not-appear';

      try {
        AppEnvironment.fromValues(
          environment: rejectedValue,
          urlStrategy: 'hash',
        );
        fail('Invalid environment must throw.');
      } on AppEnvironmentException catch (error) {
        expect(error.message, isNot(contains(rejectedValue)));
        expect(error.toString(), isNot(contains(rejectedValue)));
      }
    });
  });
}
