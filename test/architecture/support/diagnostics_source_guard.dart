import 'dart:io';

import 'architecture_files.dart';

/// Returns authored Dart files below [root] in stable path order.
List<File> sortedDartFiles(String root) {
  final files = dartFiles(root).toList()
    ..sort((left, right) => left.path.compareTo(right.path));

  return files;
}

/// Returns paths of [files] whose source contains [fragment].
List<String> filesContaining(List<File> files, String fragment) => files
    .where((file) => file.readAsStringSync().contains(fragment))
    .map((file) => file.path)
    .toList();

/// Extracts point-import URIs from [source].
List<String> sourceImports(String source) => RegExp(
  r"^import\s+'([^']+)';",
  multiLine: true,
).allMatches(source).map((match) => match.group(1)!).toList();

/// Extracts one final [AppLogRecord] subclass body from [source].
String recordClassSource(String source, String className) {
  final marker = 'final class $className extends AppLogRecord {';
  final start = source.indexOf(marker);
  if (start < 0) {
    throw StateError('Expected production record class was not found.');
  }
  final openingBrace = source.indexOf('{', start);
  var depth = 0;
  for (var index = openingBrace; index < source.length; index += 1) {
    switch (source[index]) {
      case '{':
        depth += 1;
      case '}':
        depth -= 1;
        if (depth == 0) {
          return source.substring(start, index + 1);
        }
    }
  }

  throw StateError('Production record class is not balanced.');
}

/// Removes line comments and normalizes whitespace for source assertions.
String normalizeSource(String source) =>
    withoutLineComments(source).replaceAll(RegExp(r'\s+'), ' ').trim();

/// Removes full-line Dart comments from [source].
String withoutLineComments(String source) =>
    source.replaceAll(RegExp(r'^\s*///?.*$', multiLine: true), '');

/// Counts non-overlapping occurrences of [fragment] in [source].
int occurrenceCount(String source, String fragment) =>
    source.split(fragment).length - 1;

/// Counts generative and named constructors for [className].
int constructorCount(String source, String className) => RegExp(
  '\\b${RegExp.escape(className)}(?:\\.[A-Za-z][A-Za-z0-9_]*)?\\s*\\(',
).allMatches(source).length;

/// Returns normalized final instance-field declarations from [source].
List<String> instanceFinalFields(String source) => RegExp(
  r'^  final\s+[^;\n]+;$',
  multiLine: true,
).allMatches(source).map((match) => normalizeSource(match.group(0)!)).toList();

/// Whether [source] contains an initialized or uninitialized mutable field.
bool hasMutableInstanceField(String source) => RegExp(
  r'^  (?!final\b|static\b|const\b)(?:late\s+)?'
  r'[A-Za-z_][A-Za-z0-9_<>?, ]*\s+[A-Za-z_][A-Za-z0-9_]*'
  r'(?:\s*=(?!>)\s*[^;\n]+)?\s*;$',
  multiLine: true,
).hasMatch(withoutLineComments(source));
