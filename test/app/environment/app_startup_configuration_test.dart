import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/environment/app_configuration_exception.dart';
import 'package:template/app/environment/app_environment_kind.dart';
import 'package:template/app/environment/app_startup_configuration.dart';
import 'package:template/app/environment/app_url_strategy.dart';

void main() {
  group('AppStartupConfiguration', () {
    test('composes validated configuration owned by narrow subsystems', () {
      final configuration = AppStartupConfiguration.fromValues(
        environment: 'prod',
        urlStrategy: 'path',
        storageNamespace: 'prod',
      );

      expect(configuration.environment.kind, AppEnvironmentKind.prod);
      expect(configuration.environment.urlStrategy, AppUrlStrategy.path);
      expect(configuration.storage.namespace.value, 'prod');
    });

    test('rejects storage namespace without rendering its value', () {
      const rejectedValue = 'Private-Namespace-Secret';

      expect(
        () => AppStartupConfiguration.fromValues(
          environment: 'local',
          urlStrategy: 'hash',
          storageNamespace: rejectedValue,
        ),
        throwsA(
          isA<AppConfigurationException>()
              .having(
                (error) => error.message,
                'safe message',
                isNot(contains(rejectedValue)),
              )
              .having(
                (error) => error.toString(),
                'safe text',
                isNot(contains(rejectedValue)),
              ),
        ),
      );
    });
  });
}
