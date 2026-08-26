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

/// Creates a new [T] from one runtime [P] parameter.
///
/// Use this when feature construction depends on a route identifier, route
/// arguments, or another invocation-specific value while longer-lived
/// collaborators are captured by the composition closure:
///
/// ```dart
/// final ParamFactory<OrderBloc, OrderId> createOrderBloc =
///     (orderId) => OrderBloc(
///       orderId: orderId,
///       orders: ordersFacade,
///     );
/// ```
///
/// When construction requires several runtime values, use a record or a
/// dedicated immutable parameters object as [P].
///
/// Like [Factory], this typedef defines construction only; ownership belongs
/// to the caller that invokes the factory.
typedef ParamFactory<T extends Object, P> = T Function(P parameter);
