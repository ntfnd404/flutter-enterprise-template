/// Stable names owned by the Activity routing contract.
enum ActivityRouteName {
  /// Activity destination.
  activity('activity');

  const ActivityRouteName(this.value);

  /// Stable URL segment and registry key.
  final String value;
}
