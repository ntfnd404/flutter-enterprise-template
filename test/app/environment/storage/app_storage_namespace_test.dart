import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/environment/storage/app_storage_namespace.dart';
import 'package:template/app/environment/storage/app_storage_namespace_exception.dart';

void main() {
  group('AppStorageNamespace', () {
    test('accepts canonical persistent identifiers', () {
      for (final value in <String>['local', 'prod_eu', 'tenant2']) {
        expect(AppStorageNamespace.fromValue(value).value, value);
      }
    });

    test('has value equality without exposing its value in toString', () {
      final first = AppStorageNamespace.fromValue('test');
      final second = AppStorageNamespace.fromValue('test');

      expect(first, second);
      expect(first.hashCode, second.hashCode);
      expect(first.toString(), isNot(contains('test')));
    });

    test('classifies invalid values without retaining them', () {
      final cases = <String, AppStorageNamespaceFailure>{
        '': AppStorageNamespaceFailure.empty,
        'a' * 33: AppStorageNamespaceFailure.tooLong,
        'Prod': AppStorageNamespaceFailure.nonCanonical,
        'prod-eu': AppStorageNamespaceFailure.nonCanonical,
        '_prod': AppStorageNamespaceFailure.nonCanonical,
      };

      for (final MapEntry(key: value, value: failure) in cases.entries) {
        expect(
          () => AppStorageNamespace.fromValue(value),
          throwsA(
            isA<AppStorageNamespaceException>()
                .having((error) => error.failure, 'failure', failure)
                .having(
                  (error) => error.toString(),
                  'sanitized text',
                  isNot(contains(value.isEmpty ? '<empty>' : value)),
                ),
          ),
        );
      }
    });
  });
}
