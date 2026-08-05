import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:template/app/environment/app_environment_keys.dart';

import '../../../tool/quality/dart_define_file_validator.dart';

void main() {
  const validator = DartDefineFileValidator();

  test('accepts every tracked environment profile', () {
    for (final path in [
      'env/local.env',
      'env/dev.env',
      'env/test.env',
      'env/prod.env',
    ]) {
      expect(
        () => validator.validate(File(path).readAsStringSync()),
        returnsNormally,
        reason: path,
      );
    }
  });

  test('accepts a valid CRLF environment profile', () {
    const contents =
        '${AppEnvironmentKeys.environment}=local\r\n'
        '${AppEnvironmentKeys.urlStrategy}=hash\r\n';

    expect(() => validator.validate(contents), returnsNormally);
  });

  test('rejects malformed, duplicate, empty, unknown, and missing keys', () {
    const valid =
        '${AppEnvironmentKeys.environment}=local\n'
        '${AppEnvironmentKeys.urlStrategy}=hash';
    final cases = {
      'MALFORMED': 'Invalid configuration syntax',
      '${AppEnvironmentKeys.environment} =local\n'
              '${AppEnvironmentKeys.urlStrategy}=hash':
          'Invalid configuration syntax',
      '${AppEnvironmentKeys.environment}= local\n'
              '${AppEnvironmentKeys.urlStrategy}=hash':
          'Invalid configuration syntax',
      '$valid\n${AppEnvironmentKeys.environment}=local': 'Duplicate dart-define key',
      '$valid\nAPI_SECRET=value': 'Unsupported dart-define key',
      '${AppEnvironmentKeys.environment}=local\n'
              '${AppEnvironmentKeys.urlStrategy}=':
          'Empty dart-define value',
      '${AppEnvironmentKeys.environment}=local': 'Missing required dart-define key',
    };

    for (final MapEntry(key: contents, value: expected) in cases.entries) {
      expect(
        () => validator.validate(contents),
        throwsA(
          isA<DartDefineValidationException>().having(
            (error) => error.message,
            'safe message',
            contains(expected),
          ),
        ),
      );
    }
  });

  test('never includes rejected values in diagnostics', () {
    const secret = 'credential-value-must-not-appear';
    const contents =
        '${AppEnvironmentKeys.environment}=local\n'
        '${AppEnvironmentKeys.urlStrategy}=$secret';

    expect(
      () => validator.validate(contents),
      throwsA(
        isA<DartDefineValidationException>().having(
          (error) => error.message,
          'safe message',
          isNot(contains(secret)),
        ),
      ),
    );
  });

  test('does not render hostile malformed key text', () {
    const hostileKey = 'BAD\u001b[31mKEY';

    expect(
      () => validator.validate('$hostileKey=value'),
      throwsA(
        isA<DartDefineValidationException>()
            .having(
              (error) => error.message,
              'safe message',
              isNot(contains(hostileKey)),
            )
            .having(
              (error) => error.message,
              'reason',
              contains('Invalid configuration key'),
            ),
      ),
    );
  });
}
