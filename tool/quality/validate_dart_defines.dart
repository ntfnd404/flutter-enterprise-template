import 'dart:io';

import 'dart_define_file_validator.dart';

const int _usageExitCode = 64;
const int _invalidDataExitCode = 65;

/// Validates the single public dart-define profile passed in [arguments].
///
/// Usage:
/// ```text
/// dart run tool/quality/validate_dart_defines.dart env/local.env
/// ```
///
/// CI/CD must invoke this command for the exact file subsequently passed to
/// `flutter build --dart-define-from-file`.
///
/// A valid profile writes a confirmation to stdout and exits successfully.
/// Invalid invocation uses exit code 64; unreadable or invalid input uses exit
/// code 65 and writes only sanitized diagnostics to stderr.
void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln(
      'Usage: dart run tool/quality/validate_dart_defines.dart <env-file>',
    );
    exitCode = _usageExitCode;

    return;
  }

  try {
    final contents = File(arguments.single).readAsStringSync();
    const DartDefineFileValidator().validate(contents);
    stdout.writeln('Dart-define configuration is valid.');
  } on FileSystemException {
    stderr.writeln('Unable to read dart-define configuration file.');
    exitCode = _invalidDataExitCode;
  } on DartDefineValidationException catch (error) {
    stderr.writeln(error.message);
    exitCode = _invalidDataExitCode;
  }
}
