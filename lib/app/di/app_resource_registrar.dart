import 'dart:async';

/// Releases one application-owned [resource].
typedef AppResourceDisposer<R extends Object> = FutureOr<void> Function(
  R resource,
);

/// Registers resources owned by one application dependency graph build.
///
/// A dependency factory receives this construction-only capability instead of
/// the graph's private lifecycle ledger. Register each owned resource
/// immediately after creating it. Borrowed resources and internals owned by an
/// already registered module must not be registered again.
abstract interface class AppResourceRegistrar {
  /// Registers an owned [resource] and returns it unchanged.
  ///
  /// Registering the same object identity twice, or registering after graph
  /// construction has closed, throws a privacy-safe [StateError].
  R register<R extends Object>(
    R resource,
    AppResourceDisposer<R> disposer,
  );
}
