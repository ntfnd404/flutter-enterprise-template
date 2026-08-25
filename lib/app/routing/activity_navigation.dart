/// Application-shell capability for opening the activity destination.
///
/// Callers depend on this narrow contract rather than importing the concrete
/// Activity route or feature implementation.
abstract interface class ActivityNavigation {
  /// Opens Activity and highlights [sequence].
  void openActivity({required int sequence});
}
