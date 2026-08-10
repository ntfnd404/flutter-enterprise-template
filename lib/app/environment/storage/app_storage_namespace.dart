import 'package:template/app/environment/storage/app_storage_namespace_exception.dart';

/// Stable namespace separating app-owned local persistence between profiles.
final class AppStorageNamespace {
  const AppStorageNamespace._(this.value);

  /// Validates an externally supplied storage namespace.
  ///
  /// The value starts with a lowercase ASCII letter, contains only lowercase
  /// letters, digits, and underscores, and is at most 32 characters long.
  factory AppStorageNamespace.fromValue(String value) {
    if (value.isEmpty) {
      throw const AppStorageNamespaceException(
        AppStorageNamespaceFailure.empty,
      );
    }
    if (value.length > 32) {
      throw const AppStorageNamespaceException(
        AppStorageNamespaceFailure.tooLong,
      );
    }
    if (!_format.hasMatch(value)) {
      throw const AppStorageNamespaceException(
        AppStorageNamespaceFailure.nonCanonical,
      );
    }

    return AppStorageNamespace._(value);
  }

  static final RegExp _format = RegExp(r'^[a-z][a-z0-9_]{0,31}$');

  /// Canonical value safe to include in local persistent identifiers.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStorageNamespace && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AppStorageNamespace(<redacted>)';
}
