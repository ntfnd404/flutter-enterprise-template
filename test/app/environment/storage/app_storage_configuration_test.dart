import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/environment/storage/app_storage_configuration.dart';
import 'package:template/app/environment/storage/app_storage_namespace.dart';

void main() {
  group('AppStorageConfiguration', () {
    test('owns validated app-wide local storage identity', () {
      final configuration = AppStorageConfiguration.fromValues(
        namespace: 'test',
      );

      expect(
        configuration.namespace,
        AppStorageNamespace.fromValue('test'),
      );
    });
  });
}
