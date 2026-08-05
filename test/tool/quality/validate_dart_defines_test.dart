import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _entrypoint = 'tool/quality/validate_dart_defines.dart';

void main() {
  group('validate_dart_defines CLI', () {
    test('uses the usage exit code when the file argument is absent', () async {
      final result = await _runValidator();

      expect(result.exitCode, 64);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('Usage:'));
    });

    test('uses the usage exit code when extra arguments are supplied', () async {
      final result = await _runValidator(<String>[
        'env/local.env',
        'env/dev.env',
      ]);

      expect(result.exitCode, 64);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('Usage:'));
      expect(result.stderr, isNot(contains('env/local.env')));
      expect(result.stderr, isNot(contains('env/dev.env')));
    });

    test('accepts a valid public environment profile', () async {
      final result = await _runValidator(<String>['env/local.env']);

      expect(result.exitCode, 0);
      expect(result.stdout, contains('Dart-define configuration is valid.'));
      expect(result.stderr, isEmpty);
    });

    test('uses the invalid-data exit code for an unreadable file', () async {
      final result = await _runValidator(<String>['env/missing.env']);

      expect(result.exitCode, 65);
      expect(result.stdout, isEmpty);
      expect(result.stderr, contains('Unable to read dart-define configuration file.'));
      expect(result.stderr, isNot(contains('env/missing.env')));
    });

    test('does not expose a rejected value in process output', () async {
      const rejectedValue = 'credential-value-must-not-appear';
      final temporaryDirectory = await Directory.systemTemp.createTemp('template_env_cli_test_');
      addTearDown(() => temporaryDirectory.delete(recursive: true));
      final profile = File('${temporaryDirectory.path}/invalid.env');
      await profile.writeAsString(
        'APP_ENVIRONMENT=local\nAPP_URL_STRATEGY=$rejectedValue',
      );

      final result = await _runValidator(<String>[profile.path]);

      expect(result.exitCode, 65);
      expect(result.stdout, isNot(contains(rejectedValue)));
      expect(result.stderr, isNot(contains(rejectedValue)));
      expect(
        result.stderr,
        contains('Dart-define values violate the application environment contract.'),
      );
    });
  });
}

Future<ProcessResult> _runValidator([List<String> arguments = const <String>[]]) => Process.run(
  'dart',
  [
    'run',
    _entrypoint,
    ...arguments,
  ],
  workingDirectory: Directory.current.path,
);
