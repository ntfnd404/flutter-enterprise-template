import 'dart:io';

import 'package:app_database/app_database_composition.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/di/modules/database/app_database_configuration_factory.dart';
import 'package:template/app/environment/storage/app_storage_namespace.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'derives isolated database identities from storage namespaces',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'template-database-configuration-',
      );
      const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
      binding.defaultBinaryMessenger.setMockMethodCallHandler(
        pathProvider,
        (call) async => directory.path,
      );
      addTearDown(() async {
        binding.defaultBinaryMessenger.setMockMethodCallHandler(
          pathProvider,
          null,
        );
        await directory.delete(recursive: true);
      });

      final identities = <String>{};
      for (final namespace in <String>['local', 'dev', 'test', 'prod']) {
        final configuration = await createAppDatabaseConfiguration(
          storageNamespace: AppStorageNamespace.fromValue(namespace),
        );

        expect(configuration.databaseName, 'template_$namespace');
        expect(
          configuration.nativePath,
          '${directory.path}/template_$namespace.sqlite',
        );
        expect(
          configuration.webStoragePolicy,
          AppDatabaseWebStoragePolicy.requirePersistent,
        );
        identities.add(configuration.databaseName);
      }

      expect(identities, hasLength(4));
    },
  );
}
