/// Marker base for immutable, in-process application-shell facts.
///
/// Concrete events live in `app/events` so independent presentation features
/// can communicate without importing one another. They are best-effort
/// notifications rather than current state, domain events, or durable workflow
/// messages.
abstract base class AppEvent {
  /// Creates an application event.
  const AppEvent();
}
