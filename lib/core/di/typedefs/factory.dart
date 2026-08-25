/// Creates a new [T] without runtime parameters.
///
/// A factory describes construction policy but does not own the object it
/// returns. Every call creates an independent instance. A provider, cache, or
/// singleton accessor has different semantics and must use a different type.
///
/// In this scaffold, feature DI primarily uses factories to create BLoCs.
/// `BlocProvider(create: ...)` invokes the factory, owns the returned BLoC, and
/// closes it with the widget lifecycle. The factory remains feature-local and
/// is not exposed through `AppDependencies`.
typedef Factory<T extends Object> = T Function();
